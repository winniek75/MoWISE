-- FlashOutputServer.server.lua
-- Phase 0: P001のFlash Output問題を管理するサーバーサイド
-- Phase 4: ゾーン別 Flash Output 対応

local Players    = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent を作成
local remotes = Instance.new("Folder")
remotes.Name   = "MoWISERemotes"
remotes.Parent = ReplicatedStorage

local showQuestion  = Instance.new("RemoteEvent", remotes)
showQuestion.Name   = "ShowQuestion"
local answerResult  = Instance.new("RemoteEvent", remotes)
answerResult.Name   = "AnswerResult"
local onAnswered    = Instance.new("RemoteEvent", remotes)
onAnswered.Name     = "OnAnswered"

-- P001 Layer 3 問題データ（Phase 0 ハードコード版）
local QUESTIONS = {
    { prompt = "私は疲れています。", answer = "I'm tired.",
      tiles = {"I'm", "tired", ".", "tire"} },
    { prompt = "あなたはすごいです。", answer = "You're amazing.",
      tiles = {"You're", "amazing", ".", "I'm"} },
    { prompt = "彼は私の友達です。", answer = "He's my friend.",
      tiles = {"He's", "my", "friend", ".", "She's"} },
    { prompt = "彼女は医者です。", answer = "She's a doctor.",
      tiles = {"She's", "a", "doctor", ".", "He's"} },
    { prompt = "今日は暑いです。", answer = "It's hot today.",
      tiles = {"It's", "hot", "today", ".", "This's"} },
}

-- 問題をシャッフルして出題
local function getShuffledQuestion(qData)
    local tiles = {}
    for _, t in ipairs(qData.tiles) do table.insert(tiles, t) end
    -- Fisher-Yates shuffle
    for i = #tiles, 2, -1 do
        local j = math.random(i)
        tiles[i], tiles[j] = tiles[j], tiles[i]
    end
    return { prompt = qData.prompt, answer = qData.answer, tiles = tiles }
end

-- 他スクリプトが作る BindableEvent を事前キャッシュ（起動順に依存しない）
local giveMaterial    = nil  -- MaterialSystem が作成
local enableClearance = nil  -- ClearanceSystem が作成
local mowiReaction    = nil  -- MowiSpawner が作成

task.spawn(function()
    giveMaterial    = remotes:WaitForChild("GiveMaterial", 30)
    if not giveMaterial then warn("[MoWISE] GiveMaterial not found") end
end)
task.spawn(function()
    enableClearance = remotes:WaitForChild("EnableClearance", 30)
    if not enableClearance then warn("[MoWISE] EnableClearance not found") end
end)
task.spawn(function()
    mowiReaction    = remotes:WaitForChild("MowiReaction", 30)
    if not mowiReaction then warn("[MoWISE] MowiReaction not found") end
end)

-- プレイヤーのセッション管理
local sessions = {}

-- 問題開始（ProximityPrompt などから呼び出す）
local function startSession(player)
    if sessions[player.UserId] then return end
    local idx = 1
    sessions[player.UserId] = { questionIndex = idx, score = 0 }
    local q = getShuffledQuestion(QUESTIONS[idx])
    showQuestion:FireClient(player, q, idx, #QUESTIONS)
    -- Mowi: 身構えリアクション
    if mowiReaction then mowiReaction:Fire(player, "session_start") end
    print("[MoWISE] Session started for " .. player.Name)
end

-- ===== Phase 4: ゾーン別 Flash Output =====

-- ゾーン別問題セット（各エリアのパターンに合わせた問題）
local ZONE_QUESTIONS = {
    P001 = {
        { prompt = "私は疲れています。",    answer = "I'm tired.",
          tiles  = {"I'm","tired",".","You're"} },
        { prompt = "あなたはすごいです。",   answer = "You're amazing.",
          tiles  = {"You're","amazing",".","I'm"} },
        { prompt = "彼は私の友達です。",    answer = "He's my friend.",
          tiles  = {"He's","my","friend",".","She's"} },
        { prompt = "彼女は医者です。",      answer = "She's a doctor.",
          tiles  = {"She's","a","doctor",".","He's"} },
        { prompt = "今日は暑いです。",      answer = "It's hot today.",
          tiles  = {"It's","hot","today",".","This's"} },
    },
    P002 = {
        { prompt = "これは本です。",        answer = "This is a book.",
          tiles  = {"This","is","a","book",".","These"} },
        { prompt = "こちらは田中先生です。", answer = "This is Mr. Tanaka.",
          tiles  = {"This","is","Mr.","Tanaka",".","That"} },
        { prompt = "これはいいアイデアです。",answer = "This is a good idea.",
          tiles  = {"This","is","a","good","idea",".","That's"} },
        { prompt = "これは私の家です。",    answer = "This is my house.",
          tiles  = {"This","is","my","house",".","It's"} },
        { prompt = "これは何ですか？",      answer = "What is this?",
          tiles  = {"What","is","this","?","Who"} },
    },
    P003 = {
        { prompt = "私は音楽が好きです。",  answer = "I like music.",
          tiles  = {"I","like","music",".","love"} },
        { prompt = "私は泳ぐことが好きです。",answer = "I like swimming.",
          tiles  = {"I","like","swimming",".","swim","I'd"} },
        { prompt = "私はラーメンが好きです。",answer = "I like ramen.",
          tiles  = {"I","like","ramen",".","I'd","want"} },
        { prompt = "私は読書が好きです。",  answer = "I like reading.",
          tiles  = {"I","like","reading",".","read","I'd"} },
        { prompt = "私は犬が好きです。",    answer = "I like dogs.",
          tiles  = {"I","like","dogs",".","dog","I'd"} },
    },
    P004 = {
        { prompt = "私は水が欲しいです。",  answer = "I want water.",
          tiles  = {"I","want","water",".","like","need"} },
        { prompt = "私は休みたいです。",    answer = "I want to rest.",
          tiles  = {"I","want","to","rest",".","like","sleep"} },
        { prompt = "私は新しい靴が欲しい。",answer = "I want new shoes.",
          tiles  = {"I","want","new","shoes",".","like","need"} },
        { prompt = "私は外出したいです。",  answer = "I want to go out.",
          tiles  = {"I","want","to","go","out",".","come"} },
        { prompt = "私はもっと時間が欲しい。",answer = "I want more time.",
          tiles  = {"I","want","more","time",".","like","less"} },
    },
    P005 = {
        { prompt = "私は犬を1匹飼っています。",answer = "I have a dog.",
          tiles  = {"I","have","a","dog",".","want","cat"} },
        { prompt = "私は質問があります。",  answer = "I have a question.",
          tiles  = {"I","have","a","question",".","want","problem"} },
        { prompt = "私には兄弟がいます。",  answer = "I have a brother.",
          tiles  = {"I","have","a","brother",".","sister","want"} },
        { prompt = "私は時間があります。",  answer = "I have time.",
          tiles  = {"I","have","time",".","want","no"} },
        { prompt = "私はアイデアがあります。",answer = "I have an idea.",
          tiles  = {"I","have","an","idea",".","a","want"} },
    },
    -- Phase 5: P006〜P010 問題セット
    P006 = {
        { prompt = "私は英語を少し話します。",     answer = "I can speak English a little.",
          tiles  = {"I","can","speak","English","a little",".","want","very"} },
        { prompt = "私はあなたを手伝えます。",      answer = "I can help you.",
          tiles  = {"I","can","help","you",".","want","cannot"} },
        { prompt = "私は泳げません。",             answer = "I can't swim.",
          tiles  = {"I","can't","swim",".","can","won't"} },
        { prompt = "来れますか？",                 answer = "Can you come?",
          tiles  = {"Can","you","come","?","Do","I"} },
        { prompt = "私はそれができます。",          answer = "I can do it.",
          tiles  = {"I","can","do","it",".","want","will"} },
    },
    P007 = {
        { prompt = "私は日本出身です。",            answer = "I'm from Japan.",
          tiles  = {"I'm","from","Japan",".","in","of"} },
        { prompt = "彼女はカナダ出身です。",         answer = "She's from Canada.",
          tiles  = {"She's","from","Canada",".","He's","in"} },
        { prompt = "あなたはどこ出身ですか？",       answer = "Where are you from?",
          tiles  = {"Where","are","you","from","?","do","come"} },
        { prompt = "私たちは東京出身です。",         answer = "We're from Tokyo.",
          tiles  = {"We're","from","Tokyo",".","in","I'm"} },
        { prompt = "彼は大阪出身です。",             answer = "He's from Osaka.",
          tiles  = {"He's","from","Osaka",".","She's","in"} },
    },
    P008 = {
        { prompt = "それはよい考えです。",           answer = "It's a good idea.",
          tiles  = {"It's","a","good","idea",".","the","great"} },
        { prompt = "今日は暑すぎます。",             answer = "It's too hot today.",
          tiles  = {"It's","too","hot","today",".","very","cold"} },
        { prompt = "それはあなた次第です。",          answer = "It's up to you.",
          tiles  = {"It's","up","to","you",".","for","on"} },
        { prompt = "それは難しいですね。",            answer = "It's difficult.",
          tiles  = {"It's","difficult",".","easy","That's"} },
        { prompt = "素晴らしいですね！",             answer = "It's great!",
          tiles  = {"It's","great","!","good","That's"} },
    },
    P009 = {
        { prompt = "コーヒーは好きですか？",          answer = "Do you like coffee?",
          tiles  = {"Do","you","like","coffee","?","Are","have"} },
        { prompt = "時間はありますか？",              answer = "Do you have time?",
          tiles  = {"Do","you","have","time","?","Are","want"} },
        { prompt = "英語を話しますか？",              answer = "Do you speak English?",
          tiles  = {"Do","you","speak","English","?","Can","know"} },
        { prompt = "よく旅行しますか？",              answer = "Do you ever travel?",
          tiles  = {"Do","you","ever","travel","?","always","like"} },
        { prompt = "彼のことを知っていますか？",       answer = "Do you know him?",
          tiles  = {"Do","you","know","him","?","her","have"} },
    },
    P010 = {
        { prompt = "私は学校に行きます。",            answer = "I go to school.",
          tiles  = {"I","go","to","school",".","at","the"} },
        { prompt = "私は毎朝公園に行きます。",         answer = "I go to the park every morning.",
          tiles  = {"I","go","to","the","park","every","morning",".","in"} },
        { prompt = "彼女は駅に行きます。",             answer = "She goes to the station.",
          tiles  = {"She","goes","to","the","station",".","go","in"} },
        { prompt = "私たちはカフェに行きます。",        answer = "We go to a cafe.",
          tiles  = {"We","go","to","a","cafe",".","in","the"} },
        { prompt = "どこに行きますか？",               answer = "Where do you go?",
          tiles  = {"Where","do","you","go","?","are","can"} },
    },
    -- Phase 6: P011〜P019 問題セット
    P011 = {
        { prompt = "またね！",                    answer = "See you!",
          tiles  = {"See","you","!","Bye","later"} },
        { prompt = "また明日ね。",                 answer = "See you tomorrow.",
          tiles  = {"See","you","tomorrow",".","later","Bye"} },
        { prompt = "またあとでね。",               answer = "See you later.",
          tiles  = {"See","you","later",".","tomorrow","soon"} },
        { prompt = "また来週ね。",                 answer = "See you next week.",
          tiles  = {"See","you","next","week",".","tomorrow","later"} },
        { prompt = "またすぐに会いましょう。",      answer = "See you soon.",
          tiles  = {"See","you","soon",".","later","next week"} },
    },
    P012 = {
        { prompt = "元気ですか？",                 answer = "How are you?",
          tiles  = {"How","are","you","?","do","is"} },
        { prompt = "元気ですよ、ありがとう。",        answer = "I'm fine, thank you.",
          tiles  = {"I'm","fine",",","thank","you",".","good","very"} },
        { prompt = "まあまあです。",               answer = "I'm okay.",
          tiles  = {"I'm","okay",".","fine","good"} },
        { prompt = "あなたはどうですか？",          answer = "How about you?",
          tiles  = {"How","about","you","?","are","do"} },
        { prompt = "最高です！",                   answer = "I'm great!",
          tiles  = {"I'm","great","!","fine","good"} },
    },
    P013 = {
        { prompt = "それが分かりません。",          answer = "I don't understand that.",
          tiles  = {"I","don't","understand","that",".","can't","this"} },
        { prompt = "英語が分かりません。",          answer = "I don't understand English.",
          tiles  = {"I","don't","understand","English",".","can't","Japanese"} },
        { prompt = "もう一度言ってください。",       answer = "Please say it again.",
          tiles  = {"Please","say","it","again",".","repeat","tell"} },
        { prompt = "ゆっくり話してください。",       answer = "Please speak slowly.",
          tiles  = {"Please","speak","slowly",".","say","faster"} },
        { prompt = "意味が分かりません。",          answer = "I don't understand the meaning.",
          tiles  = {"I","don't","understand","the","meaning",".","can't","a"} },
    },
    P014 = {
        { prompt = "手伝ってくれますか？",        answer = "Can you help me?",
          tiles  = {"Can","you","help","me","?","I","Will"} },
        { prompt = "もう一度言ってくれますか？",  answer = "Can you say that again?",
          tiles  = {"Can","you","say","that","again","?","tell","speak"} },
        { prompt = "これを開けてくれますか？",    answer = "Can you open this?",
          tiles  = {"Can","you","open","this","?","close","that"} },
        { prompt = "少し待ってくれますか？",       answer = "Can you wait a moment?",
          tiles  = {"Can","you","wait","a","moment","?","go","please"} },
        { prompt = "もっとゆっくり話せますか？",    answer = "Can you speak more slowly?",
          tiles  = {"Can","you","speak","more","slowly","?","say","faster"} },
    },
    P015 = {
        { prompt = "駅はどこですか？",             answer = "Where is the station?",
          tiles  = {"Where","is","the","station","?","are","a"} },
        { prompt = "トイレはどこですか？",         answer = "Where is the bathroom?",
          tiles  = {"Where","is","the","bathroom","?","are","restroom"} },
        { prompt = "出口はどこですか？",            answer = "Where is the exit?",
          tiles  = {"Where","is","the","exit","?","are","entrance"} },
        { prompt = "あなたの学校はどこですか？",    answer = "Where is your school?",
          tiles  = {"Where","is","your","school","?","are","the"} },
        { prompt = "コンビニはどこにありますか？",   answer = "Where is the convenience store?",
          tiles  = {"Where","is","the","convenience","store","?","are","a"} },
    },
    P016 = {
        { prompt = "これはいくらですか？",          answer = "How much is this?",
          tiles  = {"How","much","is","this","?","are","that"} },
        { prompt = "あれはいくらですか？",          answer = "How much is that?",
          tiles  = {"How","much","is","that","?","are","this"} },
        { prompt = "リンゴはいくらですか？",         answer = "How much is the apple?",
          tiles  = {"How","much","is","the","apple","?","are","an"} },
        { prompt = "全部でいくらですか？",           answer = "How much is it in total?",
          tiles  = {"How","much","is","it","in","total","?","all","are"} },
        { prompt = "一つはいくらですか？",           answer = "How much is one?",
          tiles  = {"How","much","is","one","?","are","each"} },
    },
    P017 = {
        { prompt = "駅を探しています。",            answer = "I'm looking for the station.",
          tiles  = {"I'm","looking","for","the","station",".","searching","a"} },
        { prompt = "トイレを探しています。",         answer = "I'm looking for the bathroom.",
          tiles  = {"I'm","looking","for","the","bathroom",".","searching","a"} },
        { prompt = "私のカバンを探しています。",      answer = "I'm looking for my bag.",
          tiles  = {"I'm","looking","for","my","bag",".","searching","a"} },
        { prompt = "よい英語の本を探しています。",    answer = "I'm looking for a good English book.",
          tiles  = {"I'm","looking","for","a","good","English","book",".","the","searching"} },
        { prompt = "友達を探しています。",           answer = "I'm looking for my friend.",
          tiles  = {"I'm","looking","for","my","friend",".","searching","a"} },
    },
    P018 = {
        { prompt = "一緒に行きましょう！",           answer = "Let's go!",
          tiles  = {"Let's","go","!","come","do"} },
        { prompt = "英語を練習しましょう。",          answer = "Let's practice English.",
          tiles  = {"Let's","practice","English",".","speak","study"} },
        { prompt = "一緒に食べましょう。",            answer = "Let's eat together.",
          tiles  = {"Let's","eat","together",".","go","drink"} },
        { prompt = "始めましょう！",                 answer = "Let's start!",
          tiles  = {"Let's","start","!","go","begin"} },
        { prompt = "お茶しましょう。",               answer = "Let's have some tea.",
          tiles  = {"Let's","have","some","tea",".","drink","coffee"} },
    },
    P019 = {
        { prompt = "嬉しい気持ちです。",             answer = "I feel happy.",
          tiles  = {"I","feel","happy",".","am","good"} },
        { prompt = "疲れた感じがします。",           answer = "I feel tired.",
          tiles  = {"I","feel","tired",".","am","sleepy"} },
        { prompt = "緊張している感じがします。",      answer = "I feel nervous.",
          tiles  = {"I","feel","nervous",".","am","excited"} },
        { prompt = "ワクワクしています。",            answer = "I feel excited.",
          tiles  = {"I","feel","excited",".","am","nervous"} },
        { prompt = "少し悲しい気持ちです。",          answer = "I feel a little sad.",
          tiles  = {"I","feel","a","little","sad",".","am","very"} },
    },
    -- Phase 7: Zone 2（街の市場）P020〜P027
    P020 = {
        { prompt = "財布は持っていますか？",          answer = "Do you have a wallet?",
          tiles  = {"Do","you","have","a","wallet","?","Are","the"} },
        { prompt = "時間はありますか？",              answer = "Do you have time?",
          tiles  = {"Do","you","have","time","?","Are","the"} },
        { prompt = "地図を持っていますか？",           answer = "Do you have a map?",
          tiles  = {"Do","you","have","a","map","?","Are","the"} },
        { prompt = "何か質問はありますか？",           answer = "Do you have any questions?",
          tiles  = {"Do","you","have","any","questions","?","Are","the"} },
        { prompt = "ペンを持っていますか？",           answer = "Do you have a pen?",
          tiles  = {"Do","you","have","a","pen","?","Are","want"} },
    },
    P021 = {
        { prompt = "コーヒーをお願いします。",          answer = "I'd like a coffee.",
          tiles  = {"I'd","like","a","coffee",".","want","the"} },
        { prompt = "窓側の席をお願いします。",          answer = "I'd like a window seat.",
          tiles  = {"I'd","like","a","window","seat",".","want","the"} },
        { prompt = "メニューを見たいのですが。",         answer = "I'd like to see the menu.",
          tiles  = {"I'd","like","to","see","the","menu",".","want","a"} },
        { prompt = "もう少し時間がほしいです。",         answer = "I'd like a little more time.",
          tiles  = {"I'd","like","a","little","more","time",".","want","need"} },
        { prompt = "チケットを2枚お願いします。",        answer = "I'd like two tickets.",
          tiles  = {"I'd","like","two","tickets",".","want","the"} },
    },
    P022 = {
        { prompt = "入ってもいいですか？",             answer = "May I come in?",
          tiles  = {"May","I","come","in","?","Can","go"} },
        { prompt = "少し質問してもいいですか？",         answer = "May I ask a question?",
          tiles  = {"May","I","ask","a","question","?","Can","the"} },
        { prompt = "写真を撮ってもいいですか？",         answer = "May I take a photo?",
          tiles  = {"May","I","take","a","photo","?","Can","make"} },
        { prompt = "座ってもいいですか？",              answer = "May I sit here?",
          tiles  = {"May","I","sit","here","?","Can","stand"} },
        { prompt = "これを借りてもいいですか？",          answer = "May I borrow this?",
          tiles  = {"May","I","borrow","this","?","Can","use"} },
    },
    P023 = {
        { prompt = "お仕事は何ですか？",              answer = "What do you do?",
          tiles  = {"What","do","you","do","?","are","work"} },
        { prompt = "普段何をしますか？",               answer = "What do you usually do?",
          tiles  = {"What","do","you","usually","do","?","are","often"} },
        { prompt = "趣味は何ですか？",                answer = "What do you enjoy doing?",
          tiles  = {"What","do","you","enjoy","doing","?","like","are"} },
        { prompt = "放課後は何をしますか？",            answer = "What do you do after school?",
          tiles  = {"What","do","you","do","after","school","?","are","in"} },
        { prompt = "週末は何をしますか？",              answer = "What do you do on weekends?",
          tiles  = {"What","do","you","do","on","weekends","?","are","in"} },
    },
    P024 = {
        { prompt = "どのくらいかかりますか？",           answer = "How long does it take?",
          tiles  = {"How","long","does","it","take","?","much","will"} },
        { prompt = "歩いてどのくらいかかりますか？",      answer = "How long does it take to walk?",
          tiles  = {"How","long","does","it","take","to","walk","?","much","go"} },
        { prompt = "駅まで何分かかりますか？",           answer = "How long does it take to the station?",
          tiles  = {"How","long","does","it","take","to","the","station","?","much","get"} },
        { prompt = "完成するまでどのくらいかかりますか？", answer = "How long does it take to finish?",
          tiles  = {"How","long","does","it","take","to","finish","?","much","done"} },
        { prompt = "車でどのくらいかかりますか？",        answer = "How long does it take by car?",
          tiles  = {"How","long","does","it","take","by","car","?","much","train"} },
    },
    P025 = {
        { prompt = "水をもらえますか？",               answer = "Can I get some water?",
          tiles  = {"Can","I","get","some","water","?","have","the"} },
        { prompt = "これをもらえますか？",              answer = "Can I get this?",
          tiles  = {"Can","I","get","this","?","have","that"} },
        { prompt = "領収書をもらえますか？",             answer = "Can I get a receipt?",
          tiles  = {"Can","I","get","a","receipt","?","have","the"} },
        { prompt = "もう一杯もらえますか？",             answer = "Can I get another one?",
          tiles  = {"Can","I","get","another","one","?","have","more"} },
        { prompt = "袋をもらえますか？",               answer = "Can I get a bag?",
          tiles  = {"Can","I","get","a","bag","?","have","the"} },
    },
    P026 = {
        { prompt = "英語を勉強するつもりです。",          answer = "I'm going to study English.",
          tiles  = {"I'm","going","to","study","English",".","will","learn"} },
        { prompt = "明日、友達に会うつもりです。",         answer = "I'm going to meet my friend tomorrow.",
          tiles  = {"I'm","going","to","meet","my","friend","tomorrow",".","will","see"} },
        { prompt = "今夜、料理するつもりです。",           answer = "I'm going to cook tonight.",
          tiles  = {"I'm","going","to","cook","tonight",".","will","make"} },
        { prompt = "旅行するつもりです。",               answer = "I'm going to travel.",
          tiles  = {"I'm","going","to","travel",".","will","go"} },
        { prompt = "早く寝るつもりです。",               answer = "I'm going to sleep early.",
          tiles  = {"I'm","going","to","sleep","early",".","will","go"} },
    },
    P027 = {
        { prompt = "それはよい考えだと思います。",         answer = "I think it's a good idea.",
          tiles  = {"I","think","it's","a","good","idea",".","feel","is"} },
        { prompt = "彼は正しいと思います。",              answer = "I think he's right.",
          tiles  = {"I","think","he's","right",".","feel","she's"} },
        { prompt = "これは難しいと思います。",             answer = "I think this is difficult.",
          tiles  = {"I","think","this","is","difficult",".","feel","easy"} },
        { prompt = "彼女は疲れていると思います。",          answer = "I think she's tired.",
          tiles  = {"I","think","she's","tired",".","feel","he's"} },
        { prompt = "もっと練習が必要だと思います。",        answer = "I think I need more practice.",
          tiles  = {"I","think","I","need","more","practice",".","feel","have"} },
    },
    -- Phase 8: Zone 2 後半（P028〜P035）MVP最終ブロック
    P028 = {
        { prompt = "お茶でもどうですか？",             answer = "How about some tea?",
          tiles  = {"How","about","some","tea","?","of","a"} },
        { prompt = "映画でもどうですか？",              answer = "How about a movie?",
          tiles  = {"How","about","a","movie","?","some","the"} },
        { prompt = "一緒に歩くのはどうですか？",          answer = "How about walking together?",
          tiles  = {"How","about","walking","together","?","going","we"} },
        { prompt = "ランチをとるのはどうですか？",         answer = "How about having lunch?",
          tiles  = {"How","about","having","lunch","?","taking","a"} },
        { prompt = "もう一度やってみるのはどうですか？",    answer = "How about trying again?",
          tiles  = {"How","about","trying","again","?","doing","one"} },
    },
    P029 = {
        { prompt = "店は何時に開きますか？",             answer = "What time does the store open?",
          tiles  = {"What","time","does","the","store","open","?","is","a"} },
        { prompt = "映画は何時に始まりますか？",           answer = "What time does the movie start?",
          tiles  = {"What","time","does","the","movie","start","?","is","a"} },
        { prompt = "バスは何時に来ますか？",              answer = "What time does the bus come?",
          tiles  = {"What","time","does","the","bus","come","?","is","arrive"} },
        { prompt = "図書館は何時に閉まりますか？",          answer = "What time does the library close?",
          tiles  = {"What","time","does","the","library","close","?","is","open"} },
        { prompt = "試合は何時に始まりますか？",            answer = "What time does the game start?",
          tiles  = {"What","time","does","the","game","start","?","is","begin"} },
    },
    P030 = {
        { prompt = "水が必要です。",                    answer = "I need some water.",
          tiles  = {"I","need","some","water",".","want","a"} },
        { prompt = "助けが必要です。",                   answer = "I need help.",
          tiles  = {"I","need","help",".","want","some"} },
        { prompt = "もっと時間が必要です。",               answer = "I need more time.",
          tiles  = {"I","need","more","time",".","want","some"} },
        { prompt = "練習する必要があります。",              answer = "I need to practice.",
          tiles  = {"I","need","to","practice",".","want","have"} },
        { prompt = "休む必要があります。",                 answer = "I need to rest.",
          tiles  = {"I","need","to","rest",".","want","have"} },
    },
    P031 = {
        { prompt = "おいしそうに見えます。",               answer = "It looks delicious.",
          tiles  = {"It","looks","delicious",".","tastes","sounds"} },
        { prompt = "難しそうに見えます。",                  answer = "It looks difficult.",
          tiles  = {"It","looks","difficult",".","seems","sounds"} },
        { prompt = "犬のように見えます。",                  answer = "It looks like a dog.",
          tiles  = {"It","looks","like","a","dog",".","is","seems"} },
        { prompt = "楽しそうに見えます。",                  answer = "It looks fun.",
          tiles  = {"It","looks","fun",".","seems","sounds"} },
        { prompt = "古いお城のように見えます。",              answer = "It looks like an old castle.",
          tiles  = {"It","looks","like","an","old","castle",".","a","seems"} },
    },
    P032 = {
        { prompt = "もう一度言っていただけますか？",           answer = "Could you say that again?",
          tiles  = {"Could","you","say","that","again","?","Can","tell"} },
        { prompt = "ゆっくり話していただけますか？",            answer = "Could you speak slowly?",
          tiles  = {"Could","you","speak","slowly","?","Can","talk"} },
        { prompt = "手伝っていただけますか？",                 answer = "Could you help me?",
          tiles  = {"Could","you","help","me","?","Can","please"} },
        { prompt = "窓を開けていただけますか？",                answer = "Could you open the window?",
          tiles  = {"Could","you","open","the","window","?","Can","close"} },
        { prompt = "もう少し待っていただけますか？",             answer = "Could you wait a little longer?",
          tiles  = {"Could","you","wait","a","little","longer","?","Can","more"} },
    },
    P033 = {
        { prompt = "手伝っていただけないかと思いまして。",        answer = "I was wondering if you could help me.",
          tiles  = {"I","was","wondering","if","you","could","help","me",".","whether","would"} },
        { prompt = "明日空いているかと思いまして。",              answer = "I was wondering if you were free tomorrow.",
          tiles  = {"I","was","wondering","if","you","were","free","tomorrow",".","are","would"} },
        { prompt = "これが正しいかどうか知りたいのですが。",        answer = "I was wondering if this is correct.",
          tiles  = {"I","was","wondering","if","this","is","correct",".","was","whether"} },
        { prompt = "一緒に来ていただけないかと思いまして。",          answer = "I was wondering if you could come with me.",
          tiles  = {"I","was","wondering","if","you","could","come","with","me",".","would","whether"} },
        { prompt = "少し早く来られるかと思いまして。",             answer = "I was wondering if you could come a bit earlier.",
          tiles  = {"I","was","wondering","if","you","could","come","a","bit","earlier",".","would","maybe"} },
    },
    P034 = {
        { prompt = "それが正しいかどうか分かりません。",           answer = "I'm not sure if that's correct.",
          tiles  = {"I'm","not","sure","if","that's","correct",".","whether","about"} },
        { prompt = "彼が来るかどうか分かりません。",               answer = "I'm not sure if he's coming.",
          tiles  = {"I'm","not","sure","if","he's","coming",".","whether","she's"} },
        { prompt = "答えが分かりません。",                        answer = "I'm not sure about the answer.",
          tiles  = {"I'm","not","sure","about","the","answer",".","of","if"} },
        { prompt = "どちらがいいか分かりません。",                  answer = "I'm not sure which is better.",
          tiles  = {"I'm","not","sure","which","is","better",".","if","about"} },
        { prompt = "何をすればいいか分かりません。",                 answer = "I'm not sure what to do.",
          tiles  = {"I'm","not","sure","what","to","do",".","if","about"} },
    },
    P035 = {
        { prompt = "面白そうですね！",                           answer = "That sounds interesting!",
          tiles  = {"That","sounds","interesting","!","fun","exciting"} },
        { prompt = "楽しそうですね！",                           answer = "That sounds fun!",
          tiles  = {"That","sounds","fun","!","great","nice"} },
        { prompt = "大変そうですね。",                           answer = "That sounds difficult.",
          tiles  = {"That","sounds","difficult",".","hard","fun"} },
        { prompt = "いいですね！",                              answer = "That sounds great!",
          tiles  = {"That","sounds","great","!","good","nice"} },
        { prompt = "素晴らしいですね！",                          answer = "That sounds wonderful!",
          tiles  = {"That","sounds","wonderful","!","great","nice"} },
    },
}

-- ゾーン別セッション管理（既存 sessions と分離）
local zoneSessions = {}  -- { [userId] = { zoneId, questionIndex, score } }

-- StartZoneFlash: ZoneSystem から BindableEvent で呼ばれる
local startZoneFlash = Instance.new("BindableEvent", remotes)
startZoneFlash.Name  = "StartZoneFlash"

startZoneFlash.Event:Connect(function(player, zoneId)
    local questions = ZONE_QUESTIONS[zoneId]
    if not questions then return end

    -- 既存セッション（P001原点の古いセッション）があれば除去
    sessions[player.UserId] = nil

    -- ゾーンセッション開始
    zoneSessions[player.UserId] = { zoneId = zoneId, questionIndex = 1, score = 0 }

    local q = getShuffledQuestion(questions[1])
    showQuestion:FireClient(player, q, 1, #questions)
    if mowiReaction then mowiReaction:Fire(player, "session_start") end
    print(("[MoWISE] Zone session started: %s → %s"):format(player.Name, zoneId))
end)

-- Phase 4 用 BindableEvent キャッシュ
local patternCorrectBE  = nil
local giveZoneRewardBE  = nil
task.spawn(function()
    patternCorrectBE = remotes:WaitForChild("PatternCorrect", 30)
    if not patternCorrectBE then warn("[MoWISE] PatternCorrect not found") end
end)
task.spawn(function()
    giveZoneRewardBE = remotes:WaitForChild("GiveZoneReward", 30)
    if not giveZoneRewardBE then warn("[MoWISE] GiveZoneReward not found") end
end)

-- 回答を受け取る（Phase 0 + Phase 4 統合ハンドラ）
onAnswered.OnServerEvent:Connect(function(player, selectedTiles)
    -- Phase 4: ゾーンセッションを優先チェック
    local zs = zoneSessions[player.UserId]
    if zs then
        local questions = ZONE_QUESTIONS[zs.zoneId]
        local idx = zs.questionIndex
        local q   = questions[idx]

        local assembled = table.concat(selectedTiles, " ")
        assembled = assembled:gsub(" %.", ".")
        assembled = assembled:gsub(" %?", "?")
        assembled = assembled:gsub(" !", "!")
        local isCorrect = (assembled == q.answer)

        if isCorrect then
            zs.score = zs.score + 1
            if mowiReaction then mowiReaction:Fire(player, "correct") end
            -- ZoneSystem に正解通知
            if patternCorrectBE then
                patternCorrectBE:Fire(player, zs.zoneId, true)
            end
            -- ゾーン素材報酬
            if giveZoneRewardBE then
                giveZoneRewardBE:Fire(player, zs.zoneId)
            end
            -- 整地解禁
            if enableClearance then enableClearance:Fire(player) end
        else
            if mowiReaction then mowiReaction:Fire(player, "incorrect") end
            if patternCorrectBE then
                patternCorrectBE:Fire(player, zs.zoneId, false)
            end
        end

        answerResult:FireClient(player, isCorrect, q.answer)

        task.wait(1.5)
        if idx < #questions then
            zs.questionIndex = idx + 1
            local nextQ = getShuffledQuestion(questions[zs.questionIndex])
            showQuestion:FireClient(player, nextQ, zs.questionIndex, #questions)
        else
            showQuestion:FireClient(player, nil, 0, 0)
            print(("[MoWISE] %s: Zone %s %d/%d 正解"):format(
                player.Name, zs.zoneId, zs.score, #questions))
            zoneSessions[player.UserId] = nil
        end
        return
    end

    -- Phase 0: 既存セッション（原点 P001）
    local session = sessions[player.UserId]
    if not session then return end

    local idx = session.questionIndex
    local q   = QUESTIONS[idx]

    local assembled = table.concat(selectedTiles, " ")
    assembled = assembled:gsub(" %.", ".")
    local isCorrect = (assembled == q.answer)

    if isCorrect then
        session.score = session.score + 1
        if giveMaterial then
            giveMaterial:Fire(player, "Wood", 3)
        end
        if enableClearance then
            enableClearance:Fire(player)
        end
        if mowiReaction then mowiReaction:Fire(player, "correct") end
    else
        if mowiReaction then mowiReaction:Fire(player, "incorrect") end
    end

    answerResult:FireClient(player, isCorrect, q.answer)

    task.wait(1.5)
    if idx < #QUESTIONS then
        session.questionIndex = idx + 1
        local nextQ = getShuffledQuestion(QUESTIONS[session.questionIndex])
        showQuestion:FireClient(player, nextQ, session.questionIndex, #QUESTIONS)
    else
        showQuestion:FireClient(player, nil, 0, 0)
        print(("[MoWISE] %s: %d/%d 正解"):format(player.Name, session.score, #QUESTIONS))
        sessions[player.UserId] = nil
    end
end)

-- FlashTriggerZone の ProximityPrompt に接続
local function connectTrigger()
    local zone = workspace:WaitForChild("FlashTriggerZone", 10)
    if not zone then return end
    local prompt = zone:WaitForChild("FlashTrigger", 10)
    if not prompt then return end
    prompt.Triggered:Connect(function(player)
        if not sessions[player.UserId] then
            startSession(player)
        end
    end)
end
task.spawn(connectTrigger)

-- フォールバック: 後から追加される ProximityPrompt にも対応
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") and obj.Name == "FlashTrigger" then
        obj.Triggered:Connect(function(player)
            if not sessions[player.UserId] then
                startSession(player)
            end
        end)
    end
end)
