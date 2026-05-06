-- TownTalkService.server.lua
-- C-1.2 Phase 3 / Town Talk サーバ側中枢
--
-- 役割：
--   1. NPC 接近トリガから startSession でシナリオ取得（Edge Function）
--   2. TT_AnswerSubmit を受けてサーバ側 validateTurn で正誤判定
--      （クライアント信用しない：option_id を payload_json から逆引きして再判定）
--   3. 5ターン完走で submitSession → world-talk-submit で結果送信
--   4. 報酬反映（Phase 5 で本実装、Phase 3 は仮）
--
-- 認証ルート：
--   既存 X-MoWISE-API-Key（roblox-* 系）には触れない
--   world-talk-scenario-fetch / world-talk-submit は Authorization: Bearer 統一
--   → SyncService:fetchTownTalkScenario / submitTownTalkResult 経由（Phase 3.1+3.2 で追加済）
--
-- TEST_MODE：
--   Phase 3 確認用。TEST_USER_ID（test@sample.com）をハードコードし、
--   6桁リンキング無しでも fetch/submit が通るようにする。
--   Phase 5 で TEST_MODE = false 化、SyncService.mowiseUserId 経由に切替。

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SyncService = require(ServerScriptService:WaitForChild("SyncService"))

local remotes            = ReplicatedStorage:WaitForChild("MoWISERemotes")
local TT_Start           = remotes:WaitForChild("TT_Start")
local TT_AnswerSubmit    = remotes:WaitForChild("TT_AnswerSubmit")
local TT_TurnResult      = remotes:WaitForChild("TT_TurnResult")
local TT_MissionComplete = remotes:WaitForChild("TT_MissionComplete")
local TT_Cancel          = remotes:WaitForChild("TT_Cancel")
local mowiEmotion        = remotes:FindFirstChild("MowiEmotion")  -- 既存（任意）

------------------------------------------------------------------------
-- TEST_MODE（Phase 5 で false に切替済み）
-- ★ true に戻すと TEST_USER_ID（test@sample.com）でハードコード動作
-- ★ Phase 6 デバッグ用に _G.setMoWISEUserId(player, userId) も提供
------------------------------------------------------------------------
local TEST_MODE    = false
local TEST_USER_ID = "0c871272-0391-4b82-8e69-6493f06377f9"  -- test@sample.com（緊急時のフォールバック用）

------------------------------------------------------------------------
-- アクティブセッション管理
------------------------------------------------------------------------
local activeSessions = {}  -- [Player] = sessionState
local SESSION_TIMEOUT_SEC = 300  -- 5分（GC 用）

------------------------------------------------------------------------
-- SyncService 取得（PlayerJoinHandler の中央レジストリ経由）
-- 既存 BindableFunction "GetPlayerSync" を使う（PlayerJoinHandler.server.lua:24-28）
------------------------------------------------------------------------
local getSyncBF = remotes:WaitForChild("GetPlayerSync", 30)

local function getSyncService(player)
    if not getSyncBF then return nil end
    local ok, sync = pcall(function()
        return getSyncBF:Invoke(player.UserId)
    end)
    return ok and sync or nil
end

local function getMoWISEUserId(player)
    if TEST_MODE then return TEST_USER_ID end
    local sync = getSyncService(player)
    if not sync then return nil end
    return sync.mowiseUserId  -- nil の場合は未連携扱い
end

------------------------------------------------------------------------
-- サーバ側 option_id 検証（クライアント信用しない）
-- payload_json から該当 option を引いて結果を返す
-- 戻り値：result table | nil（不正な option_id は nil）
------------------------------------------------------------------------
local function validateTurn(scenario, turnNo, optionId)
    if not scenario or not scenario.turns then return nil end
    local turn = scenario.turns[turnNo]
    if not turn or not turn.options then return nil end

    for _, opt in ipairs(turn.options) do
        if opt.option_id == optionId then
            local nextTurn = scenario.turns[turnNo + 1]
            return {
                is_correct       = opt.is_correct,
                is_acceptable    = opt.is_acceptable,
                explanation      = opt.explanation,
                next_npc_audio   = nextTurn and nextTurn.npc_audio or nil,
            }
        end
    end
    return nil  -- 不正な option_id（kick はせず警告ログのみ）
end

------------------------------------------------------------------------
-- 報酬反映（Phase 5 本実装）
-- Word Coins：player.WordCoins (NumberValue) に直接加算（既存パターン踏襲）
-- 友好度    ：player Attribute "TotalNPCFriendship" を加算
-- Mowi 演出 ：mowiEmotion :FireClient(player, "joy") → 1秒後 "grow"
------------------------------------------------------------------------
local TownTalkService = {}

function TownTalkService:applyRewards(player, npcId, rewards)
    if not rewards then return end

    -- ① Word Coins 加算（既存 VillagerSystem.server.lua:657-658 と同パターン）
    local coinsGranted = tonumber(rewards.coins_granted) or 0
    if coinsGranted > 0 then
        local coins = player:FindFirstChild("WordCoins")
        if coins then
            coins.Value = coins.Value + coinsGranted
        else
            warn(("[TownTalk] WordCoins not found for %s; coin reward skipped"):format(player.Name))
        end
    end

    -- ② 友好度（TotalNPCFriendship Attribute）加算
    -- ※ 個別 NPC 友好度メーターは未実装。総合スコアのみ更新
    local friendshipDelta = tonumber(rewards.friendship_delta) or 0
    if friendshipDelta > 0 then
        local cur = player:GetAttribute("TotalNPCFriendship") or 0
        player:SetAttribute("TotalNPCFriendship", cur + friendshipDelta)
    end

    -- ③ Mowi 演出（joy → 1秒後 grow）
    if mowiEmotion then
        mowiEmotion:FireClient(player, "joy")
        task.delay(1, function()
            if player and player.Parent then
                mowiEmotion:FireClient(player, "grow")
            end
        end)
    end

    print(string.format(
        "[TownTalk] rewards applied: %s +%d coins, friendship +%d, mowi=%s",
        tostring(npcId),
        coinsGranted,
        friendshipDelta,
        tostring(rewards.mowi_message)
    ))
end

------------------------------------------------------------------------
-- セッション開始（VillagerSystem の ProximityPrompt から呼ばれる予定 = Phase 4）
------------------------------------------------------------------------
function TownTalkService:startSession(player, npcId)
    if activeSessions[player] then
        warn(("[TownTalk] %s: session already active"):format(player.Name))
        return
    end

    local userId = getMoWISEUserId(player)
    if not userId then
        TT_Cancel:FireClient(player, "NOT_LINKED")
        return
    end

    local sync = getSyncService(player)
    local ok, response, statusCode = sync:fetchTownTalkScenario(npcId)

    if not ok then
        if statusCode == 404 then
            TT_Cancel:FireClient(player, "NO_SCENARIO")
        elseif statusCode == 401 then
            TT_Cancel:FireClient(player, "AUTH")
        else
            TT_Cancel:FireClient(player, "NETWORK")
        end
        return
    end

    if not response or not response.scenario then
        warn(("[TownTalk] %s: empty scenario response"):format(player.Name))
        TT_Cancel:FireClient(player, "NETWORK")
        return
    end

    -- セッション state 構築
    activeSessions[player] = {
        scenarioId      = response.scenario_id,
        scenario        = response.scenario,
        npcId           = npcId,
        startedAt       = os.time(),
        currentTurn     = 1,
        selections      = {},
        selectionReason = response.selection_reason,
    }

    -- クライアント開始
    TT_Start:FireClient(player, {
        scenario_id      = response.scenario_id,
        scenario         = response.scenario,
        selection_reason = response.selection_reason,
    })

    print(("[TownTalk] %s: session started (%s, reason=%s)"):format(
        player.Name,
        tostring(response.scenario_id),
        tostring(response.selection_reason)
    ))
end

------------------------------------------------------------------------
-- 結果送信
------------------------------------------------------------------------
function TownTalkService:submitSession(player)
    local session = activeSessions[player]
    if not session then return end

    local sync     = getSyncService(player)
    local userId   = getMoWISEUserId(player)
    local duration = os.time() - session.startedAt

    local ok, response, statusCode = sync:submitTownTalkResult({
        user_id      = userId,
        scenario_id  = session.scenarioId,
        selections   = session.selections,
        audio_urls   = {},  -- C-1.2 では空送信（C-1.4+ で対応）
        duration_sec = duration,
        platform     = "roblox",
    })

    if not ok then
        warn(("[TownTalk] %s: submit failed (status=%s)"):format(
            player.Name, tostring(statusCode)))
        TT_Cancel:FireClient(player, "SUBMIT_FAILED")
        activeSessions[player] = nil
        return
    end

    local rewards = response and response.rewards or {}

    -- 報酬反映（Phase 5 で本実装）
    self:applyRewards(player, session.npcId, rewards)

    -- 完了通知
    TT_MissionComplete:FireClient(player, rewards)

    print(("[TownTalk] %s: submit OK, log_id=%s, status=%s, +%s coins"):format(
        player.Name,
        tostring(response and response.log_id),
        tostring(response and response.approval_status),
        tostring(rewards.coins_granted)
    ))

    activeSessions[player] = nil
end

------------------------------------------------------------------------
-- TT_AnswerSubmit ハンドラ：サーバ側で validateTurn → 結果送信
------------------------------------------------------------------------
TT_AnswerSubmit.OnServerEvent:Connect(function(player, turnNo, optionId)
    local session = activeSessions[player]
    if not session then
        warn(("[TownTalk] %s: TT_AnswerSubmit without active session"):format(player.Name))
        return
    end

    -- ターン整合性
    if turnNo ~= session.currentTurn then
        warn(("[TownTalk] %s: turn mismatch (got %s, expected %s)"):format(
            player.Name, tostring(turnNo), tostring(session.currentTurn)))
        return
    end

    -- サーバ側で再判定（payload_json から）
    local result = validateTurn(session.scenario, turnNo, optionId)
    if not result then
        warn(("[TownTalk] %s: invalid option_id %s (turn %s)"):format(
            player.Name, tostring(optionId), tostring(turnNo)))
        return  -- kick はせず無視
    end

    -- selection 記録
    table.insert(session.selections, {
        turn          = turnNo,
        option_id     = optionId,
        is_correct    = result.is_correct,
        is_acceptable = result.is_acceptable,
    })

    -- クライアント通知
    TT_TurnResult:FireClient(
        player,
        turnNo,
        result.is_correct,
        result.is_acceptable,
        result.explanation,
        result.next_npc_audio
    )

    -- Mowi 反応（既存）：誤答時に sad
    if mowiEmotion and not (result.is_correct or result.is_acceptable) then
        mowiEmotion:FireClient(player, "sad")
    end

    -- 進行
    if result.is_correct or result.is_acceptable then
        local totalTurns = session.scenario.total_turns or 5
        if turnNo >= totalTurns then
            -- 最終ターン完走 → submit
            TownTalkService:submitSession(player)
        else
            session.currentTurn = turnNo + 1
        end
    end
    -- 不正解時はターン進行しない（client 側で同ターン再挑戦）
end)

------------------------------------------------------------------------
-- ステイルセッション GC（5分超過は破棄）
------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(60)
        local now = os.time()
        for player, session in pairs(activeSessions) do
            if now - session.startedAt > SESSION_TIMEOUT_SEC then
                warn(("[TownTalk] stale session GC: %s"):format(player.Name))
                activeSessions[player] = nil
            end
        end
    end
end)

------------------------------------------------------------------------
-- プレイヤー退室時クリーンアップ
------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    activeSessions[player] = nil
end)

------------------------------------------------------------------------
-- グローバル公開
------------------------------------------------------------------------
_G.TownTalkService = TownTalkService  -- VillagerSystem 統合用（Phase 4）

-- デバッグ用（Phase 3 動作確認用）
_G.startTownTalk = function(player, npcId)
    if not player then
        warn("[TownTalk] _G.startTownTalk: player nil")
        return
    end
    TownTalkService:startSession(player, npcId)
end

-- Phase 6 デバッグ用：未連携プレイヤーにも mowiseUserId を手動セットして
-- 実 user_id 経路をテストするヘルパー（LinkSystem 拡張までの暫定措置）
-- 例：_G.setMoWISEUserId(player, "0c871272-0391-4b82-8e69-6493f06377f9")
_G.setMoWISEUserId = function(player, userId)
    if not player or not userId then
        warn("[TownTalk] _G.setMoWISEUserId: invalid args")
        return
    end
    local sync = getSyncService(player)
    if not sync then
        warn(("[TownTalk] _G.setMoWISEUserId: no SyncService for %s"):format(player.Name))
        return
    end
    sync.mowiseUserId = userId
    print(("[TownTalk] mowiseUserId set: %s -> %s"):format(player.Name, userId))
end

print(("[TownTalk] TownTalkService ready (TEST_MODE=%s)"):format(tostring(TEST_MODE)))

return TownTalkService
