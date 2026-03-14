-- ZoneSystem.server.lua
-- Phase 4: パターンエリア管理・★進捗・レシピ解禁
-- Phase 5: P006〜P010 追加 + 農業レシピ解禁
-- Phase 6: P011〜P019 追加（Zone 1 全19エリア完成）

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

-- RemoteEvent 追加
local patternStarUp   = Instance.new("RemoteEvent", remotes)
patternStarUp.Name    = "PatternStarUp"   -- ★が上がったことをクライアントに通知
local recipeUnlocked  = Instance.new("RemoteEvent", remotes)
recipeUnlocked.Name   = "RecipeUnlocked"  -- 新レシピ解禁をクライアントに通知

------------------------------------------------------------------------
-- パターンエリア定義（P001〜P019）
-- 設計書 §4.2 の「パターン × 素材」連動を実装
------------------------------------------------------------------------
local PATTERN_ZONES = {
    {
        id          = "P001",
        name        = "崩れた石壁エリア",
        patternName = "[代名詞] + be動詞",
        position    = Vector3.new(30, 0, 30),
        ruins = {
            { size = Vector3.new(2,8,1),  offset = Vector3.new(0,4,0),   color = Color3.fromRGB(108,88,75) },
            { size = Vector3.new(2,6,1),  offset = Vector3.new(3,3,0),   color = Color3.fromRGB(100,80,70) },
            { size = Vector3.new(4,1,3),  offset = Vector3.new(1,0.5,2), color = Color3.fromRGB(99,95,98) },
        },
        rewards     = { Stone = 2, Wood = 1 },
    },
    {
        id          = "P002",
        name        = "壊れた看板エリア",
        patternName = "This is [名詞]",
        position    = Vector3.new(60, 0, 10),
        ruins = {
            { size = Vector3.new(1,5,0.5), offset = Vector3.new(0,2.5,0), color = Color3.fromRGB(120,100,80) },
            { size = Vector3.new(4,0.3,2), offset = Vector3.new(0,4.8,0), color = Color3.fromRGB(130,110,90) },
            { size = Vector3.new(2,1,3),   offset = Vector3.new(2,0.5,0), color = Color3.fromRGB(100,90,80) },
        },
        rewards     = { Wood = 3 },
    },
    {
        id          = "P003",
        name        = "枯れた花壇エリア",
        patternName = "I like [名詞/〜ing]",
        position    = Vector3.new(10, 0, 70),
        ruins = {
            { size = Vector3.new(6,0.5,6), offset = Vector3.new(0,0.25,0), color = Color3.fromRGB(80,60,40) },
            { size = Vector3.new(1,0.8,1), offset = Vector3.new(2,0.65,2), color = Color3.fromRGB(60,50,40) },
            { size = Vector3.new(1,0.6,1), offset = Vector3.new(-2,0.55,-1), color = Color3.fromRGB(70,55,45) },
        },
        rewards     = { Flower = 4 },
    },
    {
        id          = "P004",
        name        = "腐った食糧庫エリア",
        patternName = "I want [名詞/to動詞]",
        position    = Vector3.new(-20, 0, 50),
        ruins = {
            { size = Vector3.new(5,3,4),  offset = Vector3.new(0,1.5,0), color = Color3.fromRGB(90,80,60) },
            { size = Vector3.new(3,0.5,4), offset = Vector3.new(3,0.25,0), color = Color3.fromRGB(100,85,65) },
        },
        rewards     = { Seed = 2, Wood = 1 },
    },
    {
        id          = "P005",
        name        = "崩れた倉庫エリア",
        patternName = "I have [名詞]",
        position    = Vector3.new(-40, 0, 20),
        ruins = {
            { size = Vector3.new(8,4,6),  offset = Vector3.new(0,2,0),   color = Color3.fromRGB(95,88,78) },
            { size = Vector3.new(2,2,2),  offset = Vector3.new(5,1,3),   color = Color3.fromRGB(88,80,70) },
            { size = Vector3.new(6,0.5,8), offset = Vector3.new(0,0.25,4), color = Color3.fromRGB(105,95,85) },
        },
        rewards     = { Wood = 2, Stone = 1, Flower = 1 },
    },
    -- Phase 5: P006〜P010
    {
        id          = "P006",
        name        = "壊れた工房エリア",
        patternName = "I can [動詞]",
        position    = Vector3.new(50, 0, 50),
        ruins = {
            { size = Vector3.new(5,3,4), offset = Vector3.new(0,1.5,0),    color = Color3.fromRGB(110,90,70) },
            { size = Vector3.new(3,2,3), offset = Vector3.new(-4,1,2),     color = Color3.fromRGB(100,85,65) },
            { size = Vector3.new(7,0.5,5), offset = Vector3.new(0,0.25,0), color = Color3.fromRGB(90,80,60) },
        },
        rewards = { Wood = 2, Stone = 1 },
    },
    {
        id          = "P007",
        name        = "倒れた標識塔エリア",
        patternName = "I'm from [場所]",
        position    = Vector3.new(-60, 0, 40),
        ruins = {
            { size = Vector3.new(1,6,1),  offset = Vector3.new(0,0,0),    color = Color3.fromRGB(120,100,80) },
            { size = Vector3.new(4,0.5,4), offset = Vector3.new(0,0.25,3), color = Color3.fromRGB(105,90,70) },
        },
        rewards = { Stone = 3 },
    },
    {
        id          = "P008",
        name        = "錆びた風見鶏エリア",
        patternName = "It's [形容詞/名詞]",
        position    = Vector3.new(70, 0, 50),
        ruins = {
            { size = Vector3.new(3,5,3),  offset = Vector3.new(0,2.5,0),  color = Color3.fromRGB(130,110,90) },
            { size = Vector3.new(1,1,1),  offset = Vector3.new(0,5.5,0),  color = Color3.fromRGB(150,120,80) },
        },
        rewards = { Flower = 3 },
    },
    {
        id          = "P009",
        name        = "崩れた掲示板エリア",
        patternName = "Do you [動詞]?",
        position    = Vector3.new(-10, 0, 80),
        ruins = {
            { size = Vector3.new(5,0.5,6),  offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(100,90,80) },
            { size = Vector3.new(1,2,0.5),  offset = Vector3.new(2,1.25,0),  color = Color3.fromRGB(110,95,80) },
            { size = Vector3.new(1,2,0.5),  offset = Vector3.new(-2,1.5,0),  color = Color3.fromRGB(105,90,78) },
        },
        rewards = { Seed = 3 },
    },
    {
        id          = "P010",
        name        = "割れた石畳道エリア",
        patternName = "I go to [場所]",
        position    = Vector3.new(20, 0, -60),
        ruins = {
            { size = Vector3.new(8,0.3,3),  offset = Vector3.new(0,0.15,0),    color = Color3.fromRGB(100,95,90) },
            { size = Vector3.new(3,0.3,3),  offset = Vector3.new(6,0.15,3),    color = Color3.fromRGB(105,100,92) },
        },
        rewards = { Wood = 2, Flower = 1 },
    },
    -- Phase 6: P011〜P019
    {
        id          = "P011",
        name        = "落ちた入れの石碑エリア",
        patternName = "I put [名詞] in [場所]",
        position    = Vector3.new(-30, 0, -40),
        ruins = {
            { size = Vector3.new(3,5,1),   offset = Vector3.new(0,2.5,0),   color = Color3.fromRGB(115,105,95) },
            { size = Vector3.new(4,1,3),   offset = Vector3.new(2,0.5,2),   color = Color3.fromRGB(100,95,88) },
            { size = Vector3.new(2,0.5,2), offset = Vector3.new(-2,0.25,-1), color = Color3.fromRGB(110,100,90) },
        },
        rewards = { Stone = 3 },
    },
    {
        id          = "P012",
        name        = "割れた鏡の広場エリア",
        patternName = "I see [名詞]",
        position    = Vector3.new(80, 0, -30),
        ruins = {
            { size = Vector3.new(5,0.3,5), offset = Vector3.new(0,0.15,0),  color = Color3.fromRGB(140,135,130) },
            { size = Vector3.new(2,3,0.5), offset = Vector3.new(0,1.5,3),   color = Color3.fromRGB(160,155,150) },
            { size = Vector3.new(1,2,1),   offset = Vector3.new(-3,1,0),    color = Color3.fromRGB(130,125,120) },
        },
        rewards = { Flower = 3 },
    },
    {
        id          = "P013",
        name        = "崩れた通訳小屋エリア",
        patternName = "I speak [言語]",
        position    = Vector3.new(-80, 0, -20),
        ruins = {
            { size = Vector3.new(6,4,5),   offset = Vector3.new(0,2,0),     color = Color3.fromRGB(105,90,75) },
            { size = Vector3.new(3,1,2),   offset = Vector3.new(4,0.5,3),   color = Color3.fromRGB(95,85,70) },
        },
        rewards = { Wood = 3 },
    },
    {
        id          = "P014",
        name        = "倒れた助け合いの木エリア",
        patternName = "Please [動詞]",
        position    = Vector3.new(40, 0, -50),
        ruins = {
            { size = Vector3.new(2,7,2),   offset = Vector3.new(0,0,0),     color = Color3.fromRGB(90,70,50) },
            { size = Vector3.new(5,1,4),   offset = Vector3.new(2,0.5,3),   color = Color3.fromRGB(80,65,45) },
            { size = Vector3.new(3,0.5,3), offset = Vector3.new(-3,0.25,-2), color = Color3.fromRGB(85,70,50) },
        },
        rewards = { Wood = 2, Stone = 1 },
    },
    {
        id          = "P015",
        name        = "迷子の道標エリア",
        patternName = "Where is [名詞]?",
        position    = Vector3.new(-50, 0, 70),
        ruins = {
            { size = Vector3.new(1,4,0.5), offset = Vector3.new(0,2,0),     color = Color3.fromRGB(120,110,95) },
            { size = Vector3.new(3,0.3,3), offset = Vector3.new(2,0.15,2),  color = Color3.fromRGB(110,100,88) },
            { size = Vector3.new(2,0.3,4), offset = Vector3.new(-3,0.15,-1), color = Color3.fromRGB(115,105,92) },
        },
        rewards = { Stone = 3 },
    },
    {
        id          = "P016",
        name        = "壊れた市場の秤エリア",
        patternName = "How many [名詞]?",
        position    = Vector3.new(85, 0, 30),
        ruins = {
            { size = Vector3.new(4,2,3),   offset = Vector3.new(0,1,0),     color = Color3.fromRGB(130,115,95) },
            { size = Vector3.new(2,1,2),   offset = Vector3.new(3,0.5,2),   color = Color3.fromRGB(120,105,85) },
            { size = Vector3.new(1,3,1),   offset = Vector3.new(-2,1.5,-1), color = Color3.fromRGB(140,120,100) },
        },
        rewards = { Seed = 3 },
    },
    {
        id          = "P017",
        name        = "錆びた探索の杭エリア",
        patternName = "I look for [名詞]",
        position    = Vector3.new(-70, 0, -60),
        ruins = {
            { size = Vector3.new(1,5,1),   offset = Vector3.new(0,2.5,0),   color = Color3.fromRGB(125,110,90) },
            { size = Vector3.new(1,4,1),   offset = Vector3.new(3,2,0),     color = Color3.fromRGB(118,105,85) },
            { size = Vector3.new(4,0.5,4), offset = Vector3.new(1,0.25,2),  color = Color3.fromRGB(110,100,80) },
        },
        rewards = { Flower = 2, Wood = 1 },
    },
    {
        id          = "P018",
        name        = "古い集会場の残骸エリア",
        patternName = "Let's [動詞]!",
        position    = Vector3.new(0, 0, -80),
        ruins = {
            { size = Vector3.new(8,3,6),   offset = Vector3.new(0,1.5,0),   color = Color3.fromRGB(100,90,78) },
            { size = Vector3.new(3,2,3),   offset = Vector3.new(5,1,4),     color = Color3.fromRGB(95,85,72) },
            { size = Vector3.new(4,0.5,5), offset = Vector3.new(-4,0.25,-3), color = Color3.fromRGB(105,95,82) },
        },
        rewards = { Wood = 4 },
    },
    {
        id          = "P019",
        name        = "風化した感情の壁エリア",
        patternName = "I feel [形容詞]",
        position    = Vector3.new(-85, 0, 60),
        ruins = {
            { size = Vector3.new(6,5,1),   offset = Vector3.new(0,2.5,0),   color = Color3.fromRGB(110,100,88) },
            { size = Vector3.new(3,3,1),   offset = Vector3.new(4,1.5,2),   color = Color3.fromRGB(105,95,82) },
            { size = Vector3.new(2,1,2),   offset = Vector3.new(-3,0.5,-1), color = Color3.fromRGB(115,105,92) },
        },
        rewards = { Flower = 4 },
    },
    -- Phase 7: Zone 2（街の市場）P020〜P027
    {
        id          = "P020",
        name        = "崩れた市場の入口エリア",
        patternName = "Do you have [名詞]?",
        position    = Vector3.new(30, 0, 230),
        ruins = {
            { size = Vector3.new(8,4,1),    offset = Vector3.new(0,2,0),     color = Color3.fromRGB(130,118,95) },
            { size = Vector3.new(3,4,1),    offset = Vector3.new(6,2,0),     color = Color3.fromRGB(125,112,90) },
            { size = Vector3.new(10,0.5,5), offset = Vector3.new(0,0.25,3),  color = Color3.fromRGB(115,105,85) },
        },
        rewards = { Stone = 2, Seed = 1 },
    },
    {
        id          = "P021",
        name        = "傾いた高級食堂棚エリア",
        patternName = "I'd like [名詞/to動詞]",
        position    = Vector3.new(-40, 0, 250),
        ruins = {
            { size = Vector3.new(5,6,1),    offset = Vector3.new(0,3,0),     color = Color3.fromRGB(145,125,100) },
            { size = Vector3.new(5,0.5,1),  offset = Vector3.new(0,6.25,0),  color = Color3.fromRGB(150,130,105) },
            { size = Vector3.new(6,0.5,4),  offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(135,118,92) },
        },
        rewards = { Flower = 2, Stone = 1 },
    },
    {
        id          = "P022",
        name        = "壊れた許可証の柱エリア",
        patternName = "May I [動詞]?",
        position    = Vector3.new(60, 0, 270),
        ruins = {
            { size = Vector3.new(2,7,2),    offset = Vector3.new(0,3.5,0),   color = Color3.fromRGB(140,128,110) },
            { size = Vector3.new(1,7,2),    offset = Vector3.new(-4,0,0),    color = Color3.fromRGB(135,122,105) },
            { size = Vector3.new(6,0.5,4),  offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(125,115,95)  },
        },
        rewards = { Stone = 4 },
    },
    {
        id          = "P023",
        name        = "錆びた調査塔の台エリア",
        patternName = "What do you [動詞]?",
        position    = Vector3.new(-60, 0, 300),
        ruins = {
            { size = Vector3.new(4,1,3),    offset = Vector3.new(0,0.5,0),   color = Color3.fromRGB(110,100,85) },
            { size = Vector3.new(1,4,1),    offset = Vector3.new(-1,2.5,0),  color = Color3.fromRGB(105,95,80)  },
            { size = Vector3.new(1,3,1),    offset = Vector3.new(1,2,0),     color = Color3.fromRGB(108,98,82)  },
            { size = Vector3.new(5,0.5,4),  offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(100,92,78)  },
        },
        rewards = { Wood = 3 },
    },
    {
        id          = "P024",
        name        = "倒れた時計塔エリア",
        patternName = "How long does it take [to動詞]?",
        position    = Vector3.new(0, 0, 330),
        ruins = {
            { size = Vector3.new(3,10,3),   offset = Vector3.new(0,0,0),     color = Color3.fromRGB(155,140,120) },
            { size = Vector3.new(10,3,3),   offset = Vector3.new(5,1.5,0),   color = Color3.fromRGB(148,133,115) },
            { size = Vector3.new(4,4,4),    offset = Vector3.new(0,5,0),     color = Color3.fromRGB(160,145,125) },
        },
        rewards = { Stone = 2, Flower = 1 },
    },
    {
        id          = "P025",
        name        = "割れた注文カウンターエリア",
        patternName = "Can I get [名詞]?",
        position    = Vector3.new(50, 0, 350),
        ruins = {
            { size = Vector3.new(8,1,2),    offset = Vector3.new(0,0.5,0),   color = Color3.fromRGB(125,115,95)  },
            { size = Vector3.new(8,0.5,5),  offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(118,108,88)  },
            { size = Vector3.new(1,2,1),    offset = Vector3.new(-4,1.5,0),  color = Color3.fromRGB(120,110,90)  },
            { size = Vector3.new(1,2,1),    offset = Vector3.new(4,1.5,0),   color = Color3.fromRGB(120,110,90)  },
        },
        rewards = { Seed = 2, Wood = 1 },
    },
    {
        id          = "P026",
        name        = "崩れた予定掲示板エリア",
        patternName = "I'm going to [動詞]",
        position    = Vector3.new(-30, 0, 360),
        ruins = {
            { size = Vector3.new(6,4,0.5),  offset = Vector3.new(0,2,0),     color = Color3.fromRGB(112,100,82) },
            { size = Vector3.new(1,4,0.5),  offset = Vector3.new(4,2,1),     color = Color3.fromRGB(108,96,78)  },
            { size = Vector3.new(7,0.5,4),  offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(105,94,76)  },
        },
        rewards = { Wood = 4 },
    },
    {
        id          = "P027",
        name        = "古びた意見箱エリア",
        patternName = "I think [文]",
        position    = Vector3.new(70, 0, 380),
        ruins = {
            { size = Vector3.new(3,4,3),    offset = Vector3.new(0,2,0),     color = Color3.fromRGB(130,115,95)  },
            { size = Vector3.new(1,4,3),    offset = Vector3.new(-3,2,0),    color = Color3.fromRGB(125,110,90)  },
            { size = Vector3.new(4,0.5,4),  offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(118,105,85)  },
            { size = Vector3.new(2,0.5,1),  offset = Vector3.new(0,4.25,0),  color = Color3.fromRGB(135,120,100) },
        },
        rewards = { Flower = 4 },
    },
    -- Phase 8: Zone 2 後半（P028〜P035）MVP最終ブロック
    {
        id          = "P028",
        name        = "壊れた提案箱エリア",
        patternName = "How about [名詞/動名詞]?",
        position    = Vector3.new(-70, 0, 240),
        ruins = {
            { size = Vector3.new(4,3,3),   offset = Vector3.new(0,1.5,0),   color = Color3.fromRGB(128,112,90)  },
            { size = Vector3.new(2,1,2),   offset = Vector3.new(-3,0.5,0),  color = Color3.fromRGB(120,106,85)  },
            { size = Vector3.new(5,0.5,5), offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(115,102,82)  },
        },
        rewards = { Flower = 2, Wood = 1 },
    },
    {
        id          = "P029",
        name        = "停止した市場時計エリア",
        patternName = "What time does [名詞] [動詞]?",
        position    = Vector3.new(80, 0, 255),
        ruins = {
            { size = Vector3.new(2,8,2),   offset = Vector3.new(0,4,0),     color = Color3.fromRGB(155,142,125) },
            { size = Vector3.new(4,4,4),   offset = Vector3.new(0,6,0),     color = Color3.fromRGB(148,135,118) },
            { size = Vector3.new(5,0.5,5), offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(140,128,112) },
        },
        rewards = { Stone = 4 },
    },
    {
        id          = "P030",
        name        = "崩れた補給所エリア",
        patternName = "I need [名詞/to動詞]",
        position    = Vector3.new(-80, 0, 340),
        ruins = {
            { size = Vector3.new(7,4,5),   offset = Vector3.new(0,2,0),     color = Color3.fromRGB(105,92,75)   },
            { size = Vector3.new(3,2,2),   offset = Vector3.new(5,1,0),     color = Color3.fromRGB(100,88,72)   },
            { size = Vector3.new(8,0.5,6), offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(98,86,70)    },
        },
        rewards = { Wood = 2, Seed = 2 },
    },
    {
        id          = "P031",
        name        = "歪んだ展示窓エリア",
        patternName = "It looks [形容詞/like 名詞]",
        position    = Vector3.new(35, 0, 400),
        ruins = {
            { size = Vector3.new(6,5,0.5), offset = Vector3.new(0,2.5,0),   color = Color3.fromRGB(145,130,112) },
            { size = Vector3.new(2,3,0.5), offset = Vector3.new(4,1.5,1),   color = Color3.fromRGB(140,125,108) },
            { size = Vector3.new(7,0.5,4), offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(132,118,100) },
        },
        rewards = { Flower = 4 },
    },
    {
        id          = "P032",
        name        = "倒れた丁寧な依頼台エリア",
        patternName = "Could you [動詞]?",
        position    = Vector3.new(-45, 0, 410),
        ruins = {
            { size = Vector3.new(5,1,3),   offset = Vector3.new(0,0.5,0),   color = Color3.fromRGB(138,122,100) },
            { size = Vector3.new(1,3,1),   offset = Vector3.new(-2,2,0),    color = Color3.fromRGB(132,118,96)  },
            { size = Vector3.new(1,3,1),   offset = Vector3.new(2,2.5,0),   color = Color3.fromRGB(134,120,98)  },
            { size = Vector3.new(6,0.5,5), offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(125,112,92)  },
        },
        rewards = { Stone = 2, Wood = 1 },
    },
    {
        id          = "P033",
        name        = "古びた相談室の残骸エリア",
        patternName = "I was wondering if [文]",
        position    = Vector3.new(75, 0, 430),
        ruins = {
            { size = Vector3.new(6,4,5),   offset = Vector3.new(0,2,0),     color = Color3.fromRGB(118,105,88)  },
            { size = Vector3.new(6,4,0.5), offset = Vector3.new(0,2,-2.75), color = Color3.fromRGB(112,100,84)  },
            { size = Vector3.new(7,0.5,6), offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(108,96,80)   },
        },
        rewards = { Flower = 2, Stone = 2 },
    },
    {
        id          = "P034",
        name        = "不確かな掲示板エリア",
        patternName = "I'm not sure [if/about 名詞]",
        position    = Vector3.new(-20, 0, 455),
        ruins = {
            { size = Vector3.new(8,3,0.5), offset = Vector3.new(0,1.5,0),   color = Color3.fromRGB(122,110,92)  },
            { size = Vector3.new(3,3,0.5), offset = Vector3.new(0,1.5,2),   color = Color3.fromRGB(116,105,88)  },
            { size = Vector3.new(9,0.5,5), offset = Vector3.new(0,0.25,0),  color = Color3.fromRGB(110,100,84)  },
        },
        rewards = { Wood = 4 },
    },
    {
        id          = "P035",
        name        = "響いた感想の壁エリア",
        patternName = "That sounds [形容詞]",
        position    = Vector3.new(50, 0, 480),
        ruins = {
            { size = Vector3.new(12,5,0.5), offset = Vector3.new(0,2.5,0),  color = Color3.fromRGB(135,120,105) },
            { size = Vector3.new(4,5,0.5),  offset = Vector3.new(0,2.5,3),  color = Color3.fromRGB(128,115,100) },
            { size = Vector3.new(12,0.5,5), offset = Vector3.new(0,0.25,0), color = Color3.fromRGB(122,110,95)  },
        },
        rewards = { Flower = 5 },
    },
}

------------------------------------------------------------------------
-- パターン★進捗（プレイヤーごと）
------------------------------------------------------------------------
local playerProgress = {}
-- { [userId] = { P001 = { stars=0, attempts=0, correct=0 }, ... } }

local function getProgress(player)
    if not playerProgress[player.UserId] then
        local p = {}
        for _, zone in ipairs(PATTERN_ZONES) do
            p[zone.id] = { stars = 0, attempts = 0, correct = 0 }
        end
        playerProgress[player.UserId] = p
    end
    return playerProgress[player.UserId]
end

------------------------------------------------------------------------
-- ★が上がる条件：各パターンで5回正解するごとに★1UP（最大★5）
------------------------------------------------------------------------
local CORRECT_PER_STAR = 5

-- ★解禁レシピマップ（★N達成時に解禁するレシピID一覧）
local STAR_UNLOCK_RECIPES = {
    ["P003-2"] = { "flower_bed" },
    ["P004-2"] = { "farm_plot" },
    ["P001-3"] = { "medium_house" },
    ["P005-3"] = { "storage_shed" },
    ["P001-5"] = { "village_hall" },
    -- Phase 5
    ["P006-2"] = { "sign_post" },
    ["P008-1"] = { "deco_window" },
    -- Phase 6
    ["P011-2"] = { "stone_arch" },
    ["P012-1"] = { "mirror_deco" },
    ["P014-2"] = { "help_bench" },
    ["P015-2"] = { "direction_sign" },
    ["P018-2"] = { "gathering_hall" },
    -- Phase 7: Zone 2
    ["P020-2"] = { "market_stall" },
    ["P022-1"] = { "permit_sign" },
    ["P024-2"] = { "clock_post" },
    ["P026-2"] = { "schedule_board" },
    ["P027-2"] = { "idea_box" },
    -- Phase 8: Zone 2 後半
    ["P028-2"] = { "suggestion_box" },
    ["P029-2"] = { "market_clock" },
    ["P031-1"] = { "display_window" },
    ["P033-2"] = { "consultation_room" },
    ["P035-3"] = { "grand_fountain" },
}

-- 解禁済みレシピ管理
local unlockedRecipes = {}

local function getUnlocked(player)
    if not unlockedRecipes[player.UserId] then
        unlockedRecipes[player.UserId] = {
            floor_basic = true, wall_basic = true,
            fence_wood = true, path_stone = true,
            flower_bed = true, small_house = true,
            workbench_upgrade = true,
        }
    end
    return unlockedRecipes[player.UserId]
end

------------------------------------------------------------------------
-- 正解時に呼び出す（FlashOutputServer から BindableEvent で呼ばれる）
------------------------------------------------------------------------
local patternCorrect = Instance.new("BindableEvent")
patternCorrect.Name  = "PatternCorrect"
patternCorrect.Parent = remotes

patternCorrect.Event:Connect(function(player, patternId, isCorrect)
    if not isCorrect then return end

    local progress = getProgress(player)
    local pat      = progress[patternId]
    if not pat then return end

    pat.correct   = pat.correct + 1
    pat.attempts  = pat.attempts + 1

    -- ★アップ判定
    local newStars = math.min(5, math.floor(pat.correct / CORRECT_PER_STAR))
    if newStars > pat.stars then
        pat.stars = newStars

        -- ★UP 通知をクライアントに送る
        local zone = nil
        for _, z in ipairs(PATTERN_ZONES) do
            if z.id == patternId then zone = z; break end
        end
        patternStarUp:FireClient(player, patternId, newStars,
            zone and zone.patternName or patternId)

        -- レシピ解禁チェック
        local key     = patternId .. "-" .. newStars
        local recipes = STAR_UNLOCK_RECIPES[key]
        if recipes then
            local unlocked = getUnlocked(player)
            for _, recipeId in ipairs(recipes) do
                if not unlocked[recipeId] then
                    unlocked[recipeId] = true
                    recipeUnlocked:FireClient(player, recipeId)
                    print(("[MoWISE] %s: Recipe unlocked → %s"):format(player.Name, recipeId))
                end
            end
        end

        print(("[MoWISE] %s: %s ★%d"):format(player.Name, patternId, newStars))
    end
end)

------------------------------------------------------------------------
-- 廃墟エリアの生成
------------------------------------------------------------------------
local function buildRuinsForZone(zone)
    local folder = Instance.new("Folder")
    folder.Name   = "Zone_" .. zone.id
    folder.Parent = workspace

    for i, ruinDef in ipairs(zone.ruins) do
        local part = Instance.new("Part")
        part.Name      = zone.id .. "_Ruin_" .. i
        part.Size      = ruinDef.size
        part.Color     = ruinDef.color
        part.Material  = Enum.Material.SmoothPlastic
        part.CFrame    = CFrame.new(zone.position + ruinDef.offset)
        part.Anchored  = true
        part.Parent    = folder
    end

    -- Flash Output トリガーゾーン（床パーツ）
    local triggerZone = Instance.new("Part")
    triggerZone.Name         = zone.id .. "_Trigger"
    triggerZone.Size         = Vector3.new(12, 1, 12)
    triggerZone.Transparency = 0.85
    triggerZone.Color        = Color3.fromRGB(100, 180, 255)
    triggerZone.Material     = Enum.Material.Neon
    triggerZone.Anchored     = true
    triggerZone.CanCollide   = false
    triggerZone.CFrame       = CFrame.new(zone.position)
    triggerZone.Parent       = folder

    -- SurfaceGui で パターン名を表示
    local surfGui = Instance.new("SurfaceGui")
    surfGui.Face   = Enum.NormalId.Top
    surfGui.Parent = triggerZone

    local label = Instance.new("TextLabel")
    label.Text              = zone.patternName
    label.Size              = UDim2.new(1, 0, 0.5, 0)
    label.Position          = UDim2.new(0, 0, 0.25, 0)
    label.BackgroundTransparency = 1
    label.TextColor3        = Color3.fromRGB(255, 255, 255)
    label.Font              = Enum.Font.GothamBold
    label.TextScaled        = true
    label.Parent            = surfGui

    -- ProximityPrompt（このゾーンの英語チャレンジ）
    local promptZone = Instance.new("ProximityPrompt")
    promptZone.Name     = "ZoneFlashTrigger"
    promptZone.ActionText   = "英語チャレンジ！"
    promptZone.ObjectText   = zone.patternName
    promptZone.MaxActivationDistance = 10
    promptZone.Parent       = triggerZone

    -- ProximityPrompt → BindableEvent で FlashOutputServer にゾーンセッション開始を依頼
    promptZone.Triggered:Connect(function(player)
        local startZoneFlash = remotes:FindFirstChild("StartZoneFlash")
        if startZoneFlash then
            startZoneFlash:Fire(player, zone.id)
        end
    end)

    print(("[MoWISE] Zone built: %s at %s"):format(zone.id, tostring(zone.position)))
end

-- 素材付与イベント（FlashOutputServer の正解時に呼ばれる）
local giveZoneReward = Instance.new("BindableEvent")
giveZoneReward.Name  = "GiveZoneReward"
giveZoneReward.Parent = remotes

giveZoneReward.Event:Connect(function(player, zoneId)
    local zone = nil
    for _, z in ipairs(PATTERN_ZONES) do
        if z.id == zoneId then zone = z; break end
    end
    if not zone then return end

    -- GiveMaterial は BindableEvent（MaterialSystem が作成）
    local giveMat = remotes:FindFirstChild("GiveMaterial")
    if giveMat then
        for mat, amount in pairs(zone.rewards) do
            giveMat:Fire(player, mat, amount)
        end
    end
end)

-- 起動時に全エリアを生成（WorldSetup の後に実行）
task.wait(3)
for _, zone in ipairs(PATTERN_ZONES) do
    buildRuinsForZone(zone)
end

-- プレイヤー退出時にクリア
Players.PlayerRemoving:Connect(function(player)
    playerProgress[player.UserId] = nil
    unlockedRecipes[player.UserId] = nil
end)

print("[MoWISE] ZoneSystem ready (Zone 1: 19 areas | Zone 2: 16 areas | MVP complete)")
