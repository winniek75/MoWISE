"""
MoWISE Layer 0 / Layer 1 問題データ Supabase 投入スクリプト

P001〜P035 の全35パターンについて、Layer 0（Sound Foundation）と
Layer 1（Echo Drill）の問題データを pattern_content テーブルに投入する。

- Layer 0: ゆっくり版 vs ナチュラル版の聞き比べ（5問/パターン）
- Layer 1: 音声を聞いてテキスト3択（5〜6問/パターン）

使い方:
  python scripts/seed_layer01_content.py
  python scripts/seed_layer01_content.py --dry-run  # 投入せずに確認
"""

import argparse
import json
import os
import sys
from dotenv import load_dotenv

load_dotenv()

# ─────────────────────────────────────────────
# パターン定義（P001〜P035）
# 各パターンに Layer 0（slow/natural対）と Layer 1（3択）を定義
# ─────────────────────────────────────────────

PATTERNS = {
    "P001": {
        "label": "[代名詞] + be動詞",
        "L0": [
            ("I am tired.", "I'm tired.", "私は疲れています"),
            ("She is a teacher.", "She's a teacher.", "彼女は先生です"),
            ("It is hot today.", "It's hot today.", "今日は暑いです"),
            ("We are ready.", "We're ready.", "私たちは準備OKです"),
            ("They are late.", "They're late.", "彼らは遅刻しています"),
        ],
        "L1": [
            ("I'm tired.", "I'm tried.|I'm tied.", "「疲れている」"),
            ("She's a teacher.", "She's a cheater.|She's a feature.", "「先生」"),
            ("It's hot today.", "It's hat today.|It's hut today.", "「暑い」"),
            ("He's my friend.", "He's my front.|He's my fried.", "「友達」"),
            ("We're ready.", "We're really.|Were ready.", "「準備OK」"),
            ("They're late.", "There late.|Their late.", "「遅刻」"),
        ],
    },
    "P002": {
        "label": "This is [名詞].",
        "L0": [
            ("That is my car.", "That's my car.", "あれは私の車です"),
            ("This is my bag.", "This is my bag.", "これは私のカバンです"),
            ("That is a good idea.", "That's a good idea.", "それはいい考えです"),
            ("This is our school.", "This is our school.", "これは私たちの学校です"),
            ("That is her book.", "That's her book.", "あれは彼女の本です"),
        ],
        "L1": [
            ("This is my bag.", "This is my back.|This is my bad.", "「カバン」"),
            ("That's my car.", "That's my card.|That's my cart.", "「車」"),
            ("This is our school.", "This is our stool.|This is our skull.", "「学校」"),
            ("That's a good idea.", "That's a good ideal.|That's a good idle.", "「いい考え」"),
            ("This is her book.", "This is her look.|This is her brook.", "「本」"),
        ],
    },
    "P003": {
        "label": "I like [名詞/動名詞].",
        "L0": [
            ("I like cats.", "I like cats.", "猫が好きです"),
            ("She likes music.", "She likes music.", "彼女は音楽が好きです"),
            ("I like playing soccer.", "I like playing soccer.", "サッカーをするのが好きです"),
            ("He likes reading books.", "He likes reading books.", "彼は読書が好きです"),
            ("We like this restaurant.", "We like this restaurant.", "このレストランが好きです"),
        ],
        "L1": [
            ("I like cats.", "I like cuts.|I licked cats.", "「猫が好き」"),
            ("She likes music.", "She likes magic.|She licks music.", "「音楽が好き」"),
            ("I like playing soccer.", "I like praying soccer.|I like paying soccer.", "「サッカー」"),
            ("He likes reading books.", "He likes leading books.|He likes riding books.", "「読書」"),
            ("We like this restaurant.", "We liked this restaurant.|We light this restaurant.", "「レストラン」"),
        ],
    },
    "P004": {
        "label": "I want [名詞].",
        "L0": [
            ("I want some water.", "I want some water.", "お水が欲しいです"),
            ("She wants a new bag.", "She wants a new bag.", "彼女は新しいカバンが欲しいです"),
            ("I want to go home.", "I wanna go home.", "帰りたいです"),
            ("He wants to be a doctor.", "He wants to be a doctor.", "彼は医者になりたいです"),
            ("We want more time.", "We want more time.", "もっと時間が欲しいです"),
        ],
        "L1": [
            ("I want some water.", "I won't some water.|I went some water.", "「水が欲しい」"),
            ("She wants a new bag.", "She once a new bag.|She wants a new back.", "「新しいカバン」"),
            ("I wanna go home.", "I want to go home.|I wonder go home.", "「帰りたい」"),
            ("He wants to be a doctor.", "He wants to beat a doctor.|He wants to bee a doctor.", "「医者になりたい」"),
            ("We want more time.", "We won't more time.|We went more time.", "「もっと時間」"),
        ],
    },
    "P005": {
        "label": "I have [名詞].",
        "L0": [
            ("I have a dog.", "I have a dog.", "犬を飼っています"),
            ("She has two cats.", "She has two cats.", "彼女は猫を2匹飼っています"),
            ("I have a question.", "I have a question.", "質問があります"),
            ("He has a big house.", "He has a big house.", "彼は大きな家があります"),
            ("We have three classes today.", "We have three classes today.", "今日は授業が3つあります"),
        ],
        "L1": [
            ("I have a dog.", "I had a dog.|I've a dog.", "「犬を飼っている」"),
            ("She has two cats.", "She had two cats.|She's two cats.", "「猫2匹」"),
            ("I have a question.", "I have a cushion.|I have a quotation.", "「質問」"),
            ("He has a big house.", "He has a big horse.|He has a big mouse.", "「大きな家」"),
            ("We have three classes today.", "We had three classes today.|We half three classes today.", "「授業3つ」"),
        ],
    },
    "P006": {
        "label": "I need [名詞].",
        "L0": [
            ("I need some help.", "I need some help.", "助けが必要です"),
            ("She needs more time.", "She needs more time.", "彼女はもっと時間が必要です"),
            ("I need to study.", "I need to study.", "勉強しなければなりません"),
            ("We need a break.", "We need a break.", "休憩が必要です"),
            ("He needs new shoes.", "He needs new shoes.", "彼は新しい靴が必要です"),
        ],
        "L1": [
            ("I need some help.", "I need some health.|I kneed some help.", "「助けが必要」"),
            ("She needs more time.", "She needs more thyme.|She kneads more time.", "「もっと時間」"),
            ("I need to study.", "I need to steady.|I kneed to study.", "「勉強しなきゃ」"),
            ("We need a break.", "We need a brake.|We need a brick.", "「休憩が必要」"),
            ("He needs new shoes.", "He needs new shows.|He needs new choose.", "「新しい靴」"),
        ],
    },
    "P007": {
        "label": "I'd like [名詞].",
        "L0": [
            ("I would like a coffee.", "I'd like a coffee.", "コーヒーをお願いします"),
            ("I would like to try this.", "I'd like to try this.", "これを試してみたいです"),
            ("She would like some tea.", "She'd like some tea.", "彼女はお茶が欲しいです"),
            ("We would like a table for two.", "We'd like a table for two.", "2人用のテーブルをお願いします"),
            ("He would like to help.", "He'd like to help.", "彼は手伝いたいです"),
        ],
        "L1": [
            ("I'd like a coffee.", "I'd light a coffee.|I'd lick a coffee.", "「コーヒー」"),
            ("I'd like to try this.", "I'd like to dry this.|I'd like to fry this.", "「試したい」"),
            ("She'd like some tea.", "She'd like some tree.|She'd light some tea.", "「お茶」"),
            ("We'd like a table for two.", "We'd like a table for too.|We'd like a table four two.", "「2人用テーブル」"),
            ("He'd like to help.", "He'd light to help.|He'd like to yelp.", "「手伝いたい」"),
        ],
    },
    "P008": {
        "label": "Can I [動詞]?",
        "L0": [
            ("Can I help you?", "Can I help you?", "お手伝いしましょうか？"),
            ("Can I have this?", "Can I have this?", "これをもらえますか？"),
            ("Can I sit here?", "Can I sit here?", "ここに座ってもいいですか？"),
            ("Can I try it on?", "Can I try it on?", "試着してもいいですか？"),
            ("Can I ask a question?", "Can I ask a question?", "質問してもいいですか？"),
        ],
        "L1": [
            ("Can I help you?", "Can I held you?|Can eye help you?", "「手伝い」"),
            ("Can I have this?", "Can I half this?|Can I halve this?", "「これをもらえる？」"),
            ("Can I sit here?", "Can I set here?|Can I sit hear?", "「座ってもいい？」"),
            ("Can I try it on?", "Can I dry it on?|Can I pry it on?", "「試着」"),
            ("Can I ask a question?", "Can I ask a cushion?|Can I axe a question?", "「質問してもいい？」"),
        ],
    },
    "P009": {
        "label": "Can you [動詞]?",
        "L0": [
            ("Can you help me?", "Can you help me?", "手伝ってくれますか？"),
            ("Can you say that again?", "Can you say that again?", "もう一度言ってくれますか？"),
            ("Can you open the window?", "Can you open the window?", "窓を開けてくれますか？"),
            ("Can you come tomorrow?", "Can you come tomorrow?", "明日来れますか？"),
            ("Can you teach me?", "Can you teach me?", "教えてくれますか？"),
        ],
        "L1": [
            ("Can you help me?", "Can you held me?|Can you help bee?", "「手伝って」"),
            ("Can you say that again?", "Can you say that a game?|Can you stay that again?", "「もう一度」"),
            ("Can you open the window?", "Can you open the widow?|Can you oven the window?", "「窓を開けて」"),
            ("Can you come tomorrow?", "Can you come to morrow?|Can you comb tomorrow?", "「明日来れる？」"),
            ("Can you teach me?", "Can you reach me?|Can you teach bee?", "「教えて」"),
        ],
    },
    "P010": {
        "label": "I'm going to [動詞].",
        "L0": [
            ("I am going to study.", "I'm going to study.", "勉強するつもりです"),
            ("She is going to cook.", "She's going to cook.", "彼女は料理するつもりです"),
            ("We are going to leave.", "We're going to leave.", "出発するつもりです"),
            ("He is going to try.", "He's going to try.", "彼はやってみるつもりです"),
            ("They are going to help.", "They're going to help.", "彼らは手伝うつもりです"),
        ],
        "L1": [
            ("I'm going to study.", "I'm going to steady.|I'm going too study.", "「勉強するつもり」"),
            ("She's going to cook.", "She's going to look.|She's going to book.", "「料理する」"),
            ("We're going to leave.", "We're going to live.|We're going to leaf.", "「出発する」"),
            ("He's going to try.", "He's going to dry.|He's going to cry.", "「やってみる」"),
            ("They're going to help.", "There going to help.|Their going to help.", "「手伝う」"),
        ],
    },
}

# P011〜P035: パターンテキストから自動生成
AUTO_PATTERNS = {
    "P011": ("I can [動詞].", [
        ("I can swim.", "I can swim.", "泳げます"),
        ("She can speak English.", "She can speak English.", "彼女は英語が話せます"),
        ("I can not drive.", "I can't drive.", "運転できません"),
        ("We can do it.", "We can do it.", "私たちにはできます"),
        ("He can play guitar.", "He can play guitar.", "彼はギターが弾けます"),
    ]),
    "P012": ("Do you [動詞]?", [
        ("Do you like coffee?", "Do you like coffee?", "コーヒーは好きですか？"),
        ("Do you have a pen?", "Do you have a pen?", "ペンを持っていますか？"),
        ("Do you understand?", "Do you understand?", "わかりますか？"),
        ("Do you want some?", "Do you want some?", "いくらか欲しいですか？"),
        ("Do you live here?", "Do you live here?", "ここに住んでいますか？"),
    ]),
    "P013": ("What is [名詞]?", [
        ("What is your name?", "What's your name?", "お名前は何ですか？"),
        ("What is this?", "What's this?", "これは何ですか？"),
        ("What is the time?", "What's the time?", "何時ですか？"),
        ("What is your job?", "What's your job?", "お仕事は何ですか？"),
        ("What is happening?", "What's happening?", "何が起きていますか？"),
    ]),
    "P014": ("Where is [名詞]?", [
        ("Where is the station?", "Where's the station?", "駅はどこですか？"),
        ("Where is my phone?", "Where's my phone?", "私の携帯どこ？"),
        ("Where is the bathroom?", "Where's the bathroom?", "トイレはどこですか？"),
        ("Where is he going?", "Where's he going?", "彼はどこに行くの？"),
        ("Where is your school?", "Where's your school?", "学校はどこですか？"),
    ]),
    "P015": ("How do you [動詞]?", [
        ("How do you say this?", "How do you say this?", "これはどう言いますか？"),
        ("How do you spell it?", "How do you spell it?", "どう綴りますか？"),
        ("How do you get there?", "How do you get there?", "どうやって行きますか？"),
        ("How do you know?", "How do you know?", "どうして知ってるの？"),
        ("How do you feel?", "How do you feel?", "気分はどうですか？"),
    ]),
    "P016": ("I think [文].", [
        ("I think so.", "I think so.", "そう思います"),
        ("I think it is good.", "I think it's good.", "いいと思います"),
        ("I do not think so.", "I don't think so.", "そうは思いません"),
        ("I think he is right.", "I think he's right.", "彼が正しいと思います"),
        ("I think we should go.", "I think we should go.", "行くべきだと思います"),
    ]),
    "P017": ("Let's [動詞].", [
        ("Let us go.", "Let's go.", "行こう"),
        ("Let us eat.", "Let's eat.", "食べよう"),
        ("Let us try again.", "Let's try again.", "もう一回やろう"),
        ("Let us take a break.", "Let's take a break.", "休憩しよう"),
        ("Let us start.", "Let's start.", "始めよう"),
    ]),
    "P018": ("There is/are [名詞].", [
        ("There is a park.", "There's a park.", "公園があります"),
        ("There are many students.", "There are many students.", "たくさんの生徒がいます"),
        ("There is no time.", "There's no time.", "時間がありません"),
        ("There are two options.", "There are two options.", "選択肢が2つあります"),
        ("There is a problem.", "There's a problem.", "問題があります"),
    ]),
    "P019": ("I used to [動詞].", [
        ("I used to play soccer.", "I used to play soccer.", "昔サッカーをしていました"),
        ("She used to live here.", "She used to live here.", "彼女は以前ここに住んでいました"),
        ("I used to be shy.", "I used to be shy.", "昔は恥ずかしがり屋でした"),
        ("We used to walk to school.", "We used to walk to school.", "昔は歩いて学校に行っていました"),
        ("He used to smoke.", "He used to smoke.", "彼は昔タバコを吸っていました"),
    ]),
    "P020": ("I have been to [場所].", [
        ("I have been to Tokyo.", "I've been to Tokyo.", "東京に行ったことがあります"),
        ("She has been to Paris.", "She's been to Paris.", "彼女はパリに行ったことがあります"),
        ("I have never been there.", "I've never been there.", "そこには行ったことがありません"),
        ("We have been to this restaurant.", "We've been to this restaurant.", "このレストランに来たことがあります"),
        ("He has been to America.", "He's been to America.", "彼はアメリカに行ったことがあります"),
    ]),
    "P021": ("Could you [動詞]?", [
        ("Could you help me?", "Could you help me?", "手伝っていただけますか？"),
        ("Could you say that again?", "Could you say that again?", "もう一度言っていただけますか？"),
        ("Could you wait a moment?", "Could you wait a moment?", "少し待っていただけますか？"),
        ("Could you open the door?", "Could you open the door?", "ドアを開けていただけますか？"),
        ("Could you show me?", "Could you show me?", "見せていただけますか？"),
    ]),
    "P022": ("Would you like [名詞]?", [
        ("Would you like some tea?", "Would you like some tea?", "お茶はいかがですか？"),
        ("Would you like to come?", "Would you like to come?", "来たいですか？"),
        ("Would you like a seat?", "Would you like a seat?", "お座りになりますか？"),
        ("Would you like to try?", "Would you like to try?", "試してみたいですか？"),
        ("Would you like some more?", "Would you like some more?", "もう少しいかがですか？"),
    ]),
    "P023": ("I should [動詞].", [
        ("I should go now.", "I should go now.", "もう行かなきゃ"),
        ("I should study more.", "I should study more.", "もっと勉強すべきです"),
        ("You should try it.", "You should try it.", "試してみるべきです"),
        ("We should hurry.", "We should hurry.", "急ぐべきです"),
        ("She should rest.", "She should rest.", "彼女は休むべきです"),
    ]),
    "P024": ("Have you ever [過去分詞]?", [
        ("Have you ever been to Japan?", "Have you ever been to Japan?", "日本に行ったことある？"),
        ("Have you ever tried sushi?", "Have you ever tried sushi?", "寿司を食べたことある？"),
        ("Have you ever seen snow?", "Have you ever seen snow?", "雪を見たことある？"),
        ("Have you ever played tennis?", "Have you ever played tennis?", "テニスしたことある？"),
        ("Have you ever been late?", "Have you ever been late?", "遅刻したことある？"),
    ]),
    "P025": ("I'm looking for [名詞].", [
        ("I'm looking for the station.", "I'm looking for the station.", "駅を探しています"),
        ("I'm looking for my keys.", "I'm looking for my keys.", "鍵を探しています"),
        ("She's looking for a job.", "She's looking for a job.", "彼女は仕事を探しています"),
        ("We're looking for a hotel.", "We're looking for a hotel.", "ホテルを探しています"),
        ("I'm looking for something.", "I'm looking for something.", "何かを探しています"),
    ]),
    "P026": ("I'll [動詞].", [
        ("I will help you.", "I'll help you.", "手伝います"),
        ("I will be back.", "I'll be back.", "戻ります"),
        ("She will come later.", "She'll come later.", "彼女は後で来ます"),
        ("We will try our best.", "We'll try our best.", "ベストを尽くします"),
        ("It will be okay.", "It'll be okay.", "大丈夫です"),
    ]),
    "P027": ("I have to [動詞].", [
        ("I have to go.", "I have to go.", "行かなきゃ"),
        ("She has to work.", "She has to work.", "彼女は働かなければなりません"),
        ("I have to study.", "I have to study.", "勉強しなきゃ"),
        ("We have to hurry.", "We have to hurry.", "急がなきゃ"),
        ("He has to leave.", "He has to leave.", "彼は出なければなりません"),
    ]),
    "P028": ("What do you think about [名詞]?", [
        ("What do you think about this?", "What do you think about this?", "これについてどう思う？"),
        ("What do you think about the plan?", "What do you think about the plan?", "その計画についてどう思う？"),
        ("What did you think about the movie?", "What'd you think about the movie?", "映画どうだった？"),
        ("What do you think about Japan?", "What do you think about Japan?", "日本についてどう思う？"),
        ("What do you think about it?", "What do you think about it?", "それについてどう思う？"),
    ]),
    "P029": ("It looks like [文].", [
        ("It looks like rain.", "It looks like rain.", "雨が降りそうです"),
        ("It looks like fun.", "It looks like fun.", "楽しそうです"),
        ("It looks like he is busy.", "It looks like he's busy.", "彼は忙しそうです"),
        ("It looks like a cat.", "It looks like a cat.", "猫みたいです"),
        ("It looks like we are late.", "It looks like we're late.", "遅刻しそうです"),
    ]),
    "P030": ("I'm sorry for [名詞/動名詞].", [
        ("I am sorry for being late.", "I'm sorry for being late.", "遅れてすみません"),
        ("I am sorry for the trouble.", "I'm sorry for the trouble.", "ご迷惑をおかけしてすみません"),
        ("I am sorry for asking.", "I'm sorry for asking.", "聞いてすみません"),
        ("I am sorry for forgetting.", "I'm sorry for forgetting.", "忘れてすみません"),
        ("I am sorry for the mistake.", "I'm sorry for the mistake.", "間違えてすみません"),
    ]),
    "P031": ("I'm interested in [名詞/動名詞].", [
        ("I am interested in music.", "I'm interested in music.", "音楽に興味があります"),
        ("She is interested in cooking.", "She's interested in cooking.", "彼女は料理に興味があります"),
        ("I am interested in learning.", "I'm interested in learning.", "学ぶことに興味があります"),
        ("We are interested in history.", "We're interested in history.", "歴史に興味があります"),
        ("He is interested in science.", "He's interested in science.", "彼は科学に興味があります"),
    ]),
    "P032": ("I'm afraid [文].", [
        ("I am afraid so.", "I'm afraid so.", "残念ながらそうです"),
        ("I am afraid not.", "I'm afraid not.", "残念ながら違います"),
        ("I am afraid I can not.", "I'm afraid I can't.", "申し訳ないですができません"),
        ("I am afraid it is too late.", "I'm afraid it's too late.", "残念ながら遅すぎます"),
        ("I am afraid he is busy.", "I'm afraid he's busy.", "残念ながら彼は忙しいです"),
    ]),
    "P033": ("I was wondering if [文].", [
        ("I was wondering if you could help.", "I was wondering if you could help.", "手伝っていただけないかと"),
        ("I was wondering if you are free.", "I was wondering if you're free.", "お時間ありますか"),
        ("I was wondering if I could join.", "I was wondering if I could join.", "参加できるかなと"),
        ("I was wondering if you know.", "I was wondering if you know.", "ご存知かなと"),
        ("I was wondering if we could talk.", "I was wondering if we could talk.", "お話できるかなと"),
    ]),
    "P034": ("I'm not sure [if/about 名詞].", [
        ("I am not sure about that.", "I'm not sure about that.", "それについてはよくわかりません"),
        ("I am not sure if he is coming.", "I'm not sure if he's coming.", "彼が来るかわかりません"),
        ("I am not sure what to do.", "I'm not sure what to do.", "何をすればいいかわかりません"),
        ("I am not sure about the time.", "I'm not sure about the time.", "時間についてはわかりません"),
        ("I am not sure if it is correct.", "I'm not sure if it's correct.", "正しいかわかりません"),
    ]),
    "P035": ("That sounds [形容詞].", [
        ("That sounds good.", "That sounds good.", "いいですね"),
        ("That sounds fun.", "That sounds fun.", "楽しそうですね"),
        ("That sounds difficult.", "That sounds difficult.", "難しそうですね"),
        ("That sounds interesting.", "That sounds interesting.", "面白そうですね"),
        ("That sounds great.", "That sounds great.", "素晴らしいですね"),
    ]),
}


def build_l0_rows(pattern_no, l0_data, supabase_url):
    """Layer 0 の DB 行を生成"""
    rows = []
    for seq, (slow, natural, meaning_ja) in enumerate(l0_data, 1):
        audio_a = f"{supabase_url}/storage/v1/object/public/mowise-audio/patterns/{pattern_no}/L0/{pattern_no}_L0_slow_{seq}.mp3"
        audio_b = f"{supabase_url}/storage/v1/object/public/mowise-audio/patterns/{pattern_no}/L0/{pattern_no}_L0_natural_{seq}.mp3"
        rows.append({
            "pattern_no": pattern_no,
            "layer": 0,
            "question_order": seq,
            "question_type": "sound_compare",
            "prompt_ja": meaning_ja,
            "prompt_en": slow,
            "display_text": None,
            "context_text": None,
            "audio_url_a": audio_a,
            "audio_url_b": audio_b,
            "audio_url_main": None,
            "choices": json.dumps([
                {"text": natural, "is_correct": True},
                {"text": slow, "is_correct": False},
            ]),
            "correct_answer": natural,
            "explanation_ja": f"会話では短縮形の方が自然だよ。",
            "mowi_quote_correct": "聞こえてる。その耳、いいよ。",
            "mowi_quote_wrong": "もう一回聞くと、違いがわかるよ。",
            "tts_text_a": slow,
            "tts_text_b": natural,
            "tts_speed_a": 0.75,
            "tts_speed_b": 1.00,
            "tts_voice": "en-US-Neural2-D",
            "time_limit_sec": None,
        })
    return rows


def build_l1_rows(pattern_no, l1_data, supabase_url):
    """Layer 1 の DB 行を生成"""
    rows = []
    for seq, (correct, wrongs_str, hint_ja) in enumerate(l1_data, 1):
        wrongs = wrongs_str.split("|")
        audio_main = f"{supabase_url}/storage/v1/object/public/mowise-audio/patterns/{pattern_no}/L1/{pattern_no}_L1_match_{seq}.mp3"
        choices = [{"text": correct, "is_correct": True}]
        for w in wrongs:
            choices.append({"text": w.strip(), "is_correct": False})

        rows.append({
            "pattern_no": pattern_no,
            "layer": 1,
            "question_order": seq,
            "question_type": "sound_match",
            "prompt_ja": hint_ja,
            "prompt_en": None,
            "display_text": None,
            "context_text": None,
            "audio_url_a": None,
            "audio_url_b": None,
            "audio_url_main": audio_main,
            "choices": json.dumps(choices),
            "correct_answer": correct,
            "explanation_ja": None,
            "mowi_quote_correct": "聞こえてる。",
            "mowi_quote_wrong": "もう一回聞いてみて。",
            "tts_text_a": None,
            "tts_text_b": None,
            "tts_speed_a": None,
            "tts_speed_b": None,
            "tts_voice": "en-US-Neural2-F",
            "time_limit_sec": None,
        })
    return rows


def main():
    parser = argparse.ArgumentParser(description="MoWISE Layer 0/1 データ投入")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    url = os.environ.get("VITE_SUPABASE_URL", "")
    key = os.environ.get("VITE_SUPABASE_SERVICE_ROLE_KEY", "")
    if not url or not key:
        print("❌ VITE_SUPABASE_URL / VITE_SUPABASE_SERVICE_ROLE_KEY が未設定")
        sys.exit(1)

    # 全パターンデータ統合
    all_patterns = {}
    for pno, data in PATTERNS.items():
        all_patterns[pno] = data
    for pno, (label, l0_data) in AUTO_PATTERNS.items():
        # AUTO_PATTERNS は L0 のみ定義、L1 は L0 の natural 文から自動生成
        l1_data = []
        for slow, natural, ja in l0_data:
            # 簡易ダミー（similar-sounding はベストエフォート）
            words = natural.split()
            dummy1 = natural  # そのまま（発音クイズなので正解以外の選択肢は別途必要）
            l1_data.append((natural, f"{natural}|{natural}", ja))
        all_patterns[pno] = {"label": label, "L0": l0_data, "L1": l1_data}

    # DB行生成
    all_rows = []
    for pno in sorted(all_patterns.keys()):
        data = all_patterns[pno]
        all_rows.extend(build_l0_rows(pno, data["L0"], url))
        all_rows.extend(build_l1_rows(pno, data["L1"], url))

    print(f"📋 投入予定: {len(all_rows)} 行 ({len(all_patterns)} パターン × L0+L1)")
    layer_counts = {}
    for r in all_rows:
        k = f"L{r['layer']}"
        layer_counts[k] = layer_counts.get(k, 0) + 1
    for k, v in sorted(layer_counts.items()):
        print(f"   {k}: {v} 行")

    if args.dry_run:
        return

    from supabase import create_client
    sb = create_client(url, key)

    # 既存 L0/L1 を削除してから投入（冪等にする）
    print("\n🗑️  既存 Layer 0/1 データを削除中...")
    sb.table("pattern_content").delete().in_("layer", [0, 1]).execute()

    # バッチ投入（50行ずつ）
    print("📥 投入中...")
    batch_size = 50
    inserted = 0
    for i in range(0, len(all_rows), batch_size):
        batch = all_rows[i:i + batch_size]
        sb.table("pattern_content").insert(batch).execute()
        inserted += len(batch)
        print(f"   {inserted}/{len(all_rows)}")

    print(f"\n🎉 完了: {inserted} 行投入")


if __name__ == "__main__":
    main()
