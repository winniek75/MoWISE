-- Bootstrap_TakeoverRemotes.server.lua
-- C-3.1 / 先生 NPC 引き継ぎ用 RemoteEvent を MoWISERemotes 配下に追加
--
-- 既存 TT_* / dialogue* 系とは独立した名前空間（takeover_* プレフィックス）。
-- 実装ガイド §6-4 に従う命名規則:
--   - takeover_started (Server → Client：先生に「引き継ぎ開始」を通知)
--   - takeover_ended   (Server → Client：先生に「引き継ぎ終了」を通知)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("MoWISERemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name   = "MoWISERemotes"
    remotes.Parent = ReplicatedStorage
    print("[Takeover] MoWISERemotes folder created")
end

local function ensureEvent(name)
    if not remotes:FindFirstChild(name) then
        local e = Instance.new("RemoteEvent")
        e.Name   = name
        e.Parent = remotes
    end
end

ensureEvent("takeover_started")
ensureEvent("takeover_ended")

print("[Takeover] 2 RemoteEvents ready: takeover_started / takeover_ended")
