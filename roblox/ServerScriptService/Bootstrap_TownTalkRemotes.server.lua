-- Bootstrap_TownTalkRemotes.server.lua
-- C-1.2 Phase 1.1 / Town Talk 用 RemoteEvent 5 本を MoWISERemotes 配下に追加
-- 既存 StartDialogue / DialogueAnswer / DialogueResult（VillagerSystem 用 3 ターン会話）
-- とは独立した名前空間（TT_ プレフィックス）にすることで干渉を回避する。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MoWISERemotes フォルダは WorldSetup.server.lua が作成するが、起動順非決定のため
-- 念のため自前でも生成（idempotent）。
local remotes = ReplicatedStorage:FindFirstChild("MoWISERemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "MoWISERemotes"
    remotes.Parent = ReplicatedStorage
    print("[TownTalk] MoWISERemotes folder created")
end

local function ensureEvent(name)
    if not remotes:FindFirstChild(name) then
        local e = Instance.new("RemoteEvent")
        e.Name = name
        e.Parent = remotes
    end
end

ensureEvent("TT_Start")
ensureEvent("TT_AnswerSubmit")
ensureEvent("TT_TurnResult")
ensureEvent("TT_MissionComplete")
ensureEvent("TT_Cancel")

print("[TownTalk] 5 RemoteEvents ready: TT_Start / TT_AnswerSubmit / TT_TurnResult / TT_MissionComplete / TT_Cancel")
