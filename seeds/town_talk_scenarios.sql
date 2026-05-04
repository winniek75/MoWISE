-- =====================================================
-- C-1.3 Phase 5: Town Talk seed data
-- 9 シナリオを town_talk_scenarios に投入
--
-- 自動生成: scripts/build_town_talk_seeds_sql.ts
-- 入力    : scripts/town_talk_payloads/*.json (9 ファイル)
-- 主参照  : MoWISE_TownTalk仕様書_v1_3 §12-2 雛形
--
-- 冪等性: ON CONFLICT (scenario_id) DO UPDATE で再実行可能
-- 安全性: dollar-quote タグはシナリオ毎にユニーク ($tt_<id>$)
-- =====================================================

INSERT INTO town_talk_scenarios (
  scenario_id, pattern_no, npc_id, place, theme, difficulty,
  reward_coins, reward_friendship, mowi_message, total_turns, payload_json
) VALUES
-- lily_library_extend_v2
(
  'lily_library_extend_v2', 'P031', 'lily', 'MoWISE Library', '貸出延長', 'jh3', 75, 10, '届いたよ。少し遠くまでね。', 5,
  $tt_lily_library_extend_v2${
  "scenario_id": "lily_library_extend_v2",
  "pattern_no": "P031",
  "npc_id": "lily",
  "place": "MoWISE Library",
  "theme": "貸出延長",
  "difficulty": "jh3",
  "reward_coins": 75,
  "reward_friendship": 10,
  "mowi_message": "届いたよ。少し遠くまでね。",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Hello again. May I help you?",
      "required_keywords": [
        "extend"
      ],
      "npc_reaction_correct": "Of course. Let me check. 📅",
      "options": [
        {
          "option_id": 1,
          "text": "Could you extend the loan, please?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can you extend the loan?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"Could\" の方が丁寧だよ。"
        },
        {
          "option_id": 3,
          "text": "Extend, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "短すぎ、\"Could you\" で頼もう。"
        },
        {
          "option_id": 4,
          "text": "I want extend.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"to\" が抜けてる、\"want to extend\"。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "How many more days do you need?",
      "required_keywords": [
        "week"
      ],
      "npc_reaction_correct": "Sure, that's possible. 👍",
      "options": [
        {
          "option_id": 1,
          "text": "Could I have one more week?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I have one more week?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"Could\" の方が大人っぽいよ。"
        },
        {
          "option_id": 3,
          "text": "One week more.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文として弱い、\"Could I have\" で。"
        },
        {
          "option_id": 4,
          "text": "I need week.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"a\" が抜けてる、\"a week\" にしよう。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "May I ask why?",
      "required_keywords": [
        "finish",
        "read"
      ],
      "npc_reaction_correct": "I understand. Take your time. 📖",
      "options": [
        {
          "option_id": 1,
          "text": "I haven't finished reading it yet.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I didn't finish it.",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"haven't finished\" がより自然。"
        },
        {
          "option_id": 3,
          "text": "No finish reading.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文が壊れてる、\"I haven't\" から始めよう。"
        },
        {
          "option_id": 4,
          "text": "I'm reading still.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が変、\"I'm still reading\" で。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "Your new due date is next Friday.",
      "required_keywords": [
        "write"
      ],
      "npc_reaction_correct": "Here's a note for you. 📝",
      "options": [
        {
          "option_id": 1,
          "text": "Could you write it down for me?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can you write it down?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"Could\" でより丁寧に。"
        },
        {
          "option_id": 3,
          "text": "Write it.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Could you\" を付けて頼もう。"
        },
        {
          "option_id": 4,
          "text": "Could you write down?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"it\" が抜けてる、\"write it down\"。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Anything else?",
      "required_keywords": [
        "thank"
      ],
      "npc_reaction_correct": "You're very welcome. 😊",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you for being so kind.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Thanks a lot.",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "\"for being so kind\" を足すと丁寧。"
        },
        {
          "option_id": 3,
          "text": "Thanks, see you.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "砕けすぎ、図書館では丁寧めに。"
        },
        {
          "option_id": 4,
          "text": "Thank for kind.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"for your kindness\" の形にしよう。"
        }
      ]
    }
  ]
}$tt_lily_library_extend_v2$::jsonb
),
-- lily_library_reserve_v3
(
  'lily_library_reserve_v3', 'P031', 'lily', 'MoWISE Library', '本の予約', 'jh3', 75, 10, '届いたよ。少し遠くまでね。', 5,
  $tt_lily_library_reserve_v3${
  "scenario_id": "lily_library_reserve_v3",
  "pattern_no": "P031",
  "npc_id": "lily",
  "place": "MoWISE Library",
  "theme": "本の予約",
  "difficulty": "jh3",
  "reward_coins": 75,
  "reward_friendship": 10,
  "mowi_message": "届いたよ。少し遠くまでね。",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Hello. How can I help you today?",
      "required_keywords": [
        "reserve"
      ],
      "npc_reaction_correct": "Of course. Let me check. 📕",
      "options": [
        {
          "option_id": 1,
          "text": "Could I reserve this book, please?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I reserve this book?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"Could\" の方が丁寧だよ。"
        },
        {
          "option_id": 3,
          "text": "Reserve this for me.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Could I\" で頼もう。"
        },
        {
          "option_id": 4,
          "text": "I want reserve this.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"to\" が抜けてる、\"want to reserve\"。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "I'm sorry, it's currently checked out.",
      "required_keywords": [
        "when",
        "available"
      ],
      "npc_reaction_correct": "Probably next Monday. 📅",
      "options": [
        {
          "option_id": 1,
          "text": "When will it be available again?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "When does it come back?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"available\" の方が大人っぽい。"
        },
        {
          "option_id": 3,
          "text": "When return book?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "主語が抜けてる、文を整えよう。"
        },
        {
          "option_id": 4,
          "text": "It comes when?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が変、\"When does it\" で。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "Shall I contact you when it returns?",
      "required_keywords": [
        "call"
      ],
      "npc_reaction_correct": "I'll call you. 📞",
      "options": [
        {
          "option_id": 1,
          "text": "Could you call me when it's ready?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can you call me?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"when it's ready\" まで丁寧。"
        },
        {
          "option_id": 3,
          "text": "Call me ready.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文が壊れてる、\"when it's\" で。"
        },
        {
          "option_id": 4,
          "text": "I want call.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"you to\" が抜けてる、形を整えよう。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "Where would you like to pick it up?",
      "required_keywords": [
        "pick",
        "up"
      ],
      "npc_reaction_correct": "This counter, then. ✓",
      "options": [
        {
          "option_id": 1,
          "text": "Could I pick it up at this counter?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I pick up here?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "\"pick it up\" の \"it\" を忘れずに。"
        },
        {
          "option_id": 3,
          "text": "Pick up here.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Could I\" で頼もう。"
        },
        {
          "option_id": 4,
          "text": "I pick up.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"it\" が入れたい、\"pick it up\" で。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "All set. We'll let you know.",
      "required_keywords": [
        "thank"
      ],
      "npc_reaction_correct": "You're very welcome. 😊",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you for your help.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Thank you so much.",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "OK、\"for your help\" を付けると丁寧。"
        },
        {
          "option_id": 3,
          "text": "Thanks, OK.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "砕けすぎ、図書館では丁寧めに。"
        },
        {
          "option_id": 4,
          "text": "Thank for help.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Thank you for the help\" が形。"
        }
      ]
    }
  ]
}$tt_lily_library_reserve_v3$::jsonb
),
-- lily_library_search_v1
(
  'lily_library_search_v1', 'P031', 'lily', 'MoWISE Library', '本探し', 'jh3', 75, 10, '届いたよ。少し遠くまでね。', 5,
  $tt_lily_library_search_v1${
  "scenario_id": "lily_library_search_v1",
  "pattern_no": "P031",
  "npc_id": "lily",
  "place": "MoWISE Library",
  "theme": "本探し",
  "difficulty": "jh3",
  "reward_coins": 75,
  "reward_friendship": 10,
  "mowi_message": "届いたよ。少し遠くまでね。",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Hello. May I help you?",
      "required_keywords": [
        "help"
      ],
      "npc_reaction_correct": "Of course. What kind of book? 📚",
      "options": [
        {
          "option_id": 1,
          "text": "Could you help me find a book?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can you help me find a book?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わないけど \"Could\" の方が丁寧。"
        },
        {
          "option_id": 3,
          "text": "Please find me a book.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的。\"Could you\" で頼もう。"
        },
        {
          "option_id": 4,
          "text": "I need book help.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文として成立してないね。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "What kind of book?",
      "required_keywords": [
        "science"
      ],
      "npc_reaction_correct": "Science section, this way. 📚",
      "options": [
        {
          "option_id": 1,
          "text": "I'm looking for a science book.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I want a science book.",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"looking for\" がより自然。"
        },
        {
          "option_id": 3,
          "text": "Science book, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "短すぎ、文で答えたいね。"
        },
        {
          "option_id": 4,
          "text": "I need to a science book.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"to\" が余計、\"a science book\" が形。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "Do you know where to go?",
      "required_keywords": [
        "show",
        "way",
        "tell"
      ],
      "npc_reaction_correct": "Let me show you. ➡️",
      "options": [
        {
          "option_id": 1,
          "text": "Could you show me the way?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Where is it?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"Could you\" の方が丁寧。"
        },
        {
          "option_id": 3,
          "text": "Tell me the way.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Could you tell me\" にしよう。"
        },
        {
          "option_id": 4,
          "text": "I don't know.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "これだと「知らない」、だから聞こう。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "Here it is. This is the one I'd recommend.",
      "required_keywords": [
        "borrow"
      ],
      "npc_reaction_correct": "Of course, here it is. ✓",
      "options": [
        {
          "option_id": 1,
          "text": "Could I borrow this?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I borrow this?",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "違わない、\"Could\" がより大人っぽい。"
        },
        {
          "option_id": 3,
          "text": "I want borrow this.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"to\" が抜けてる、\"want to borrow\"。"
        },
        {
          "option_id": 4,
          "text": "Lend me this.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Could I\" で頼もう。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Enjoy reading!",
      "required_keywords": [
        "thank"
      ],
      "npc_reaction_correct": "You're very welcome. 😊",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you so much for your help.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Thank you very much.",
          "is_correct": false,
          "is_acceptable": true,
          "explanation": "OK、\"for your help\" まで言うと丁寧。"
        },
        {
          "option_id": 3,
          "text": "Thanks, bye.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "砕けすぎ、図書館では丁寧めに。"
        },
        {
          "option_id": 4,
          "text": "Thank for help.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Thank you for the help\" が形。"
        }
      ]
    }
  ]
}$tt_lily_library_search_v1$::jsonb
),
-- maria_cafe_morning_v2
(
  'maria_cafe_morning_v2', 'P021', 'maria', 'MoWISE Café', '朝のモーニング', 'jh1', 50, 10, '届いたよ。', 5,
  $tt_maria_cafe_morning_v2${
  "scenario_id": "maria_cafe_morning_v2",
  "pattern_no": "P021",
  "npc_id": "maria",
  "place": "MoWISE Café",
  "theme": "朝のモーニング",
  "difficulty": "jh1",
  "reward_coins": 50,
  "reward_friendship": 10,
  "mowi_message": "届いたよ。",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Good morning! What can I get for you?",
      "required_keywords": [
        "morning",
        "set"
      ],
      "npc_reaction_correct": "Great choice! ☀️🍳",
      "options": [
        {
          "option_id": 1,
          "text": "I'd like the morning set, please.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I want morning set.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"the\" が抜けてる。\"the morning set\"。"
        },
        {
          "option_id": 3,
          "text": "Morning set, give me.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的。\"I'd like\" でお願いしよう。"
        },
        {
          "option_id": 4,
          "text": "Good morning set.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "挨拶と混ざってる。文を分けよう。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "It comes with a drink. Coffee, tea, or juice?",
      "required_keywords": [
        "juice"
      ],
      "npc_reaction_correct": "Fresh juice, coming up. 🍊",
      "options": [
        {
          "option_id": 1,
          "text": "I'd like orange juice, please.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Juice, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "短すぎ、\"I'd like\" を付けたい。"
        },
        {
          "option_id": 3,
          "text": "I'd like juice orange.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が違う、\"orange juice\" の順。"
        },
        {
          "option_id": 4,
          "text": "I'm orange juice.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"I'm\" は「私は」、意味が変だ。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "Would you like extra eggs with that?",
      "required_keywords": [
        "eggs",
        "two"
      ],
      "npc_reaction_correct": "Sunny side up coming. 🍳",
      "options": [
        {
          "option_id": 1,
          "text": "Yes, I'd like two eggs.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Yes, two egg.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "複数形は \"eggs\"、s をつけよう。"
        },
        {
          "option_id": 3,
          "text": "Yes, I'd like egg two.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が違う、\"two eggs\" の順で。"
        },
        {
          "option_id": 4,
          "text": "No, I'd like eggs.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "ほしいのに \"No\"、逆だね。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "We have window seats. Where would you like to sit?",
      "required_keywords": [
        "window",
        "seat"
      ],
      "npc_reaction_correct": "Right this way! 🪟",
      "options": [
        {
          "option_id": 1,
          "text": "I'd like a window seat, please.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Window please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "短すぎ、\"I'd like\" で頼もう。"
        },
        {
          "option_id": 3,
          "text": "I'd like a window.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"seat\" が抜けてる、\"window seat\"。"
        },
        {
          "option_id": 4,
          "text": "I'm window seat.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"I'm\" は「私は」、変だね。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Enjoy your morning!",
      "required_keywords": [
        "thank"
      ],
      "npc_reaction_correct": "Have a great day at school! 🎒✨",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you! You too.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Thank you. Same.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Same\" は不自然、\"You too\" にしよう。"
        },
        {
          "option_id": 3,
          "text": "Yes, I enjoy.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "返事になってない、\"Thank you\" で。"
        },
        {
          "option_id": 4,
          "text": "Enjoy you.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Enjoy\" の使い方が変だね。"
        }
      ]
    }
  ]
}$tt_maria_cafe_morning_v2$::jsonb
),
-- maria_cafe_order_v1
(
  'maria_cafe_order_v1', 'P021', 'maria', 'MoWISE Café', 'ラテ注文', 'jh1', 50, 10, '届いたよ。', 5,
  $tt_maria_cafe_order_v1${
  "scenario_id": "maria_cafe_order_v1",
  "pattern_no": "P021",
  "npc_id": "maria",
  "place": "MoWISE Café",
  "theme": "ラテ注文",
  "difficulty": "jh1",
  "reward_coins": 50,
  "reward_friendship": 10,
  "mowi_message": "届いたよ。",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Welcome to MoWISE Café! What would you like?",
      "required_keywords": [
        "latte"
      ],
      "npc_reaction_correct": "Sure! One latte, coming up. ☕",
      "options": [
        {
          "option_id": 1,
          "text": "I'd like a latte, please.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I want latte.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "「a」が抜けてる。\"a latte\" にしよう。"
        },
        {
          "option_id": 3,
          "text": "I'm a latte.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"I'm\" は「私は」だ。意味が変だね。"
        },
        {
          "option_id": 4,
          "text": "Please latte.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文の形になってない。\"I'd like\" だね。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "Anything else?",
      "required_keywords": [
        "muffin"
      ],
      "npc_reaction_correct": "Great choice! 🍪",
      "options": [
        {
          "option_id": 1,
          "text": "I'd like a muffin, too.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Yes, I'd like muffin.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "「a」が抜けてる。\"a muffin\" にしよう。"
        },
        {
          "option_id": 3,
          "text": "Muffin too.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文になってない。\"I'd like\" を付けて。"
        },
        {
          "option_id": 4,
          "text": "I have a muffin.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"have\" は「持ってる」、注文と違う。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "Hot or iced?",
      "required_keywords": [
        "hot"
      ],
      "npc_reaction_correct": "One hot latte. Got it. 🔥",
      "options": [
        {
          "option_id": 1,
          "text": "I'd like it hot, please.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I'd like hot.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"it\" を指して何が hot か必要だ。"
        },
        {
          "option_id": 3,
          "text": "Hot, give me.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令形すぎ。\"I'd like\" でお願いしよう。"
        },
        {
          "option_id": 4,
          "text": "I'd like a hot.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"hot\" は形容詞。後に名詞がいるよ。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "For here or to go?",
      "required_keywords": [
        "go"
      ],
      "npc_reaction_correct": "Perfect! I'll prepare it now. ⏱",
      "options": [
        {
          "option_id": 1,
          "text": "To go, please.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I to go.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "動詞がないよ。\"To go, please\" でOK。"
        },
        {
          "option_id": 3,
          "text": "Going, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"going\" は「行く」って意味、違う。"
        },
        {
          "option_id": 4,
          "text": "Yes, go.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "Yes/Noじゃ答えにならないよ。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Have a great day!",
      "required_keywords": [
        "thank"
      ],
      "npc_reaction_correct": "See you next time! 👋✨",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you. You too!",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Yes, thank you.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "相手にも返そう、\"You too!\" を付けて。"
        },
        {
          "option_id": 3,
          "text": "Thank you. Me too.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Me too\" は「私も」、ここは \"You too\"。"
        },
        {
          "option_id": 4,
          "text": "Thanks!",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "短すぎ。\"You too!\" を付けたい。"
        }
      ]
    }
  ]
}$tt_maria_cafe_order_v1$::jsonb
),
-- maria_cafe_takeout_v3
(
  'maria_cafe_takeout_v3', 'P021', 'maria', 'MoWISE Café', 'テイクアウト', 'jh1', 50, 10, '届いたよ。', 5,
  $tt_maria_cafe_takeout_v3${
  "scenario_id": "maria_cafe_takeout_v3",
  "pattern_no": "P021",
  "npc_id": "maria",
  "place": "MoWISE Café",
  "theme": "テイクアウト",
  "difficulty": "jh1",
  "reward_coins": 50,
  "reward_friendship": 10,
  "mowi_message": "届いたよ。",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Welcome! What can I get you today?",
      "required_keywords": [
        "coffees",
        "two"
      ],
      "npc_reaction_correct": "Two coffees, got it. ☕☕",
      "options": [
        {
          "option_id": 1,
          "text": "I'd like two coffees, please.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I'd like two coffee.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "複数形は \"coffees\"、s をつけよう。"
        },
        {
          "option_id": 3,
          "text": "I'd like coffee two.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が違う、\"two coffees\" の順。"
        },
        {
          "option_id": 4,
          "text": "Two coffee me.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文の形が変、\"I'd like\" がいる。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "Sure! What kind would you like?",
      "required_keywords": [
        "latte",
        "cappuccino"
      ],
      "npc_reaction_correct": "Great combo. 👍",
      "options": [
        {
          "option_id": 1,
          "text": "One latte and one cappuccino.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "One latte one cappuccino.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"and\" でつないで、間に入れて。"
        },
        {
          "option_id": 3,
          "text": "A latte, a cappuccino.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"and\" が必要、リスト読みは変。"
        },
        {
          "option_id": 4,
          "text": "Latte cappuccino, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "数を抜いてる、\"One ... and one\"で。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "Anything else?",
      "required_keywords": [
        "cookies"
      ],
      "npc_reaction_correct": "Perfect for sharing. 🍪🍪",
      "options": [
        {
          "option_id": 1,
          "text": "Yes, I'd like two cookies.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Yes, two cookie.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "複数形は \"cookies\"、s をつけよう。"
        },
        {
          "option_id": 3,
          "text": "Yes, cookie two.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が違う、\"two cookies\"。"
        },
        {
          "option_id": 4,
          "text": "Yes, I'm cookies.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"I'm\" は「私は」、変だね。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "Will you eat here?",
      "required_keywords": [
        "go"
      ],
      "npc_reaction_correct": "All to go. Coming up. 🛍",
      "options": [
        {
          "option_id": 1,
          "text": "No, I'd like everything to go.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "No, take out.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文として弱い、\"I'd like\" を付けて。"
        },
        {
          "option_id": 3,
          "text": "Yes, to go.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Yes\" だと店内、返事が逆だね。"
        },
        {
          "option_id": 4,
          "text": "No, I to go.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "動詞がない、\"I'd like ... to go\"。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Have a great day with your sister!",
      "required_keywords": [
        "thank",
        "will"
      ],
      "npc_reaction_correct": "Take care! 👋✨",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you! We will.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Thanks. I will.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "2人分だから \"We will\" にしよう。"
        },
        {
          "option_id": 3,
          "text": "Yes, with sister.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "返事が変、\"Thank you\" から。"
        },
        {
          "option_id": 4,
          "text": "Thank. Bye.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Thank you\" が正しい形。"
        }
      ]
    }
  ]
}$tt_maria_cafe_takeout_v3$::jsonb
),
-- sam_shop_fitting_v1
(
  'sam_shop_fitting_v1', 'P024', 'sam', 'MoWISE Shop', '試着', 'jh2', 60, 10, '言えたな、次は？', 5,
  $tt_sam_shop_fitting_v1${
  "scenario_id": "sam_shop_fitting_v1",
  "pattern_no": "P024",
  "npc_id": "sam",
  "place": "MoWISE Shop",
  "theme": "試着",
  "difficulty": "jh2",
  "reward_coins": 60,
  "reward_friendship": 10,
  "mowi_message": "言えたな、次は？",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Hey there! Looking for something?",
      "required_keywords": [
        "try"
      ],
      "npc_reaction_correct": "Sure! The fitting room is right over there. 🚪",
      "options": [
        {
          "option_id": 1,
          "text": "Can I try this on?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I try this?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"on\" が抜けてる、試着は \"try on\"。"
        },
        {
          "option_id": 3,
          "text": "Try this on me?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が違う、\"Can I\" から始めよう。"
        },
        {
          "option_id": 4,
          "text": "I want try this.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"to\" が抜けてる、\"want to\" で覚えよう。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "What size do you need?",
      "required_keywords": [
        "medium"
      ],
      "npc_reaction_correct": "Medium, got it. Here you go. 👕",
      "options": [
        {
          "option_id": 1,
          "text": "Can I have a medium, please?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Medium one.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文が足りない、\"Can I have\" を使おう。"
        },
        {
          "option_id": 3,
          "text": "I'm medium.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "これだと「私は中くらい」、変だね。"
        },
        {
          "option_id": 4,
          "text": "Give me medium.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的。\"Can I have\" でお願いしよう。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "We have blue and red. Which color?",
      "required_keywords": [
        "blue"
      ],
      "npc_reaction_correct": "Good choice! Blue is popular. 💙",
      "options": [
        {
          "option_id": 1,
          "text": "Can I see the blue one?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "I want blue one.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"the\" が抜けてる、\"the blue one\"。"
        },
        {
          "option_id": 3,
          "text": "Show blue please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Can I see\" で頼もう。"
        },
        {
          "option_id": 4,
          "text": "Blue is mine.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "「青は私の」、意味が違うよ。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "How does it look?",
      "required_keywords": [
        "buy",
        "like"
      ],
      "npc_reaction_correct": "Awesome! Let's go to the register. 💳",
      "options": [
        {
          "option_id": 1,
          "text": "I like it. Can I buy it?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Yes, I like.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"like\" の後に \"it\" がいるよ。"
        },
        {
          "option_id": 3,
          "text": "It's me.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "「これは私」感想になってない。"
        },
        {
          "option_id": 4,
          "text": "Buy this.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令形すぎ、\"Can I buy it?\" に。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Come again soon!",
      "required_keywords": [
        "thank",
        "will"
      ],
      "npc_reaction_correct": "Take care! 👋",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you. I will!",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Yes, I come.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"I will\" を使おう、また来るね。"
        },
        {
          "option_id": 3,
          "text": "OK, bye.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "一言短すぎ、\"Thank you\" を付けて。"
        },
        {
          "option_id": 4,
          "text": "Sure, again.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文になってない、\"I will!\" にしよう。"
        }
      ]
    }
  ]
}$tt_sam_shop_fitting_v1$::jsonb
),
-- sam_shop_price_v2
(
  'sam_shop_price_v2', 'P024', 'sam', 'MoWISE Shop', '値段確認', 'jh2', 60, 10, '言えたな、次は？', 5,
  $tt_sam_shop_price_v2${
  "scenario_id": "sam_shop_price_v2",
  "pattern_no": "P024",
  "npc_id": "sam",
  "place": "MoWISE Shop",
  "theme": "値段確認",
  "difficulty": "jh2",
  "reward_coins": 60,
  "reward_friendship": 10,
  "mowi_message": "言えたな、次は？",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Hi! Looking for something interesting?",
      "required_keywords": [
        "notebook",
        "see"
      ],
      "npc_reaction_correct": "Sure, here you go. 📓",
      "options": [
        {
          "option_id": 1,
          "text": "Can I see that notebook?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I look notebook?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"at\" が抜けてる、\"look at\" で見るとき。"
        },
        {
          "option_id": 3,
          "text": "Show notebook me.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Can I see\" でお願いしよう。"
        },
        {
          "option_id": 4,
          "text": "I want notebook see.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が違う、\"to see\" の形で。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "It's a popular one. Anything you want to ask?",
      "required_keywords": [
        "price",
        "ask"
      ],
      "npc_reaction_correct": "It's 800 yen. 💰",
      "options": [
        {
          "option_id": 1,
          "text": "Can I ask the price?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I ask price?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"the\" が抜けてる、\"the price\"。"
        },
        {
          "option_id": 3,
          "text": "How much price?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "二重表現、\"How much is it?\" でOK。"
        },
        {
          "option_id": 4,
          "text": "Price me, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文になってない、\"Can I ask\" から。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "Nice, right? We have other colors too.",
      "required_keywords": [
        "color",
        "another"
      ],
      "npc_reaction_correct": "We have red and green. ❤️💚",
      "options": [
        {
          "option_id": 1,
          "text": "Can I see another color?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I see other color?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"another color\" を使おう。"
        },
        {
          "option_id": 3,
          "text": "Other color show me.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "命令的、\"Can I see\" で頼もう。"
        },
        {
          "option_id": 4,
          "text": "I see another.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Can I\" が必要、許可を求めよう。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "Great choice! Cash or card?",
      "required_keywords": [
        "pay",
        "card"
      ],
      "npc_reaction_correct": "Card works fine. 💳",
      "options": [
        {
          "option_id": 1,
          "text": "Can I pay by card?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Can I pay card?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"by\" が抜けてる、\"pay by card\"。"
        },
        {
          "option_id": 3,
          "text": "Card pay, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文になってない、\"Can I pay\" から。"
        },
        {
          "option_id": 4,
          "text": "I pay card.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Can I\" を使って許可を求めよう。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Thanks for shopping!",
      "required_keywords": [
        "thank",
        "good"
      ],
      "npc_reaction_correct": "See you next time! 😊",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you. Have a good day!",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Thanks. Good day.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "短すぎ、\"Have a good day\" で。"
        },
        {
          "option_id": 3,
          "text": "Yes, good day.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "返事が変、\"Thank you\" から始めよう。"
        },
        {
          "option_id": 4,
          "text": "You good day.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文の形が変、\"Have a\" を入れて。"
        }
      ]
    }
  ]
}$tt_sam_shop_price_v2$::jsonb
),
-- sam_shop_stock_v3
(
  'sam_shop_stock_v3', 'P020', 'sam', 'MoWISE Shop', '在庫確認', 'jh2', 60, 10, '言えたな、次は？', 5,
  $tt_sam_shop_stock_v3${
  "scenario_id": "sam_shop_stock_v3",
  "pattern_no": "P020",
  "npc_id": "sam",
  "place": "MoWISE Shop",
  "theme": "在庫確認",
  "difficulty": "jh2",
  "reward_coins": 60,
  "reward_friendship": 10,
  "mowi_message": "言えたな、次は？",
  "total_turns": 5,
  "version": 1,
  "created_at": "2026-05-04T00:00:00Z",
  "turns": [
    {
      "turn_no": 1,
      "npc_audio": "Welcome! Looking for anything special?",
      "required_keywords": [
        "backpack"
      ],
      "npc_reaction_correct": "Yes, plenty of options. 🎒",
      "options": [
        {
          "option_id": 1,
          "text": "Do you have a backpack?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Do you have backpack?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"a\" が抜けてる、\"a backpack\"。"
        },
        {
          "option_id": 3,
          "text": "You have backpack?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Do\" を付けたい、質問の形に。"
        },
        {
          "option_id": 4,
          "text": "Backpack, do you?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が変、\"Do you have ...\" で。"
        }
      ]
    },
    {
      "turn_no": 2,
      "npc_audio": "What color do you like?",
      "required_keywords": [
        "black",
        "one"
      ],
      "npc_reaction_correct": "Got several blacks. 🖤",
      "options": [
        {
          "option_id": 1,
          "text": "Do you have a black one?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Do you have black?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"one\" が抜けてる、\"a black one\"。"
        },
        {
          "option_id": 3,
          "text": "Black one is?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文として変、\"Do you have\" から。"
        },
        {
          "option_id": 4,
          "text": "You black one?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Do\" を付けたい、質問の形で。"
        }
      ]
    },
    {
      "turn_no": 3,
      "npc_audio": "We have small, medium, and large.",
      "required_keywords": [
        "medium"
      ],
      "npc_reaction_correct": "Medium is right here. 👍",
      "options": [
        {
          "option_id": 1,
          "text": "Do you have it in medium?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Do you have medium?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"it in\" が抜けてる、\"in medium\"。"
        },
        {
          "option_id": 3,
          "text": "Medium, do you?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "語順が変、\"Do you have\" から。"
        },
        {
          "option_id": 4,
          "text": "I want medium.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "質問の形にしよう、\"Do you have\" で。"
        }
      ]
    },
    {
      "turn_no": 4,
      "npc_audio": "How many would you like?",
      "required_keywords": [
        "two",
        "stock"
      ],
      "npc_reaction_correct": "Yes, two are available. ✓",
      "options": [
        {
          "option_id": 1,
          "text": "Do you have two in stock?",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Do you have two stock?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"in\" が抜けてる、\"in stock\"。"
        },
        {
          "option_id": 3,
          "text": "Two stocks, please.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "文として変、\"Do you have\" で聞こう。"
        },
        {
          "option_id": 4,
          "text": "You have two?",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Do\" を付けたい、質問の形に。"
        }
      ]
    },
    {
      "turn_no": 5,
      "npc_audio": "Thanks for shopping with us!",
      "required_keywords": [
        "thank",
        "back"
      ],
      "npc_reaction_correct": "See you next time! 👋",
      "options": [
        {
          "option_id": 1,
          "text": "Thank you. I'll be back.",
          "is_correct": true,
          "is_acceptable": true,
          "explanation": null
        },
        {
          "option_id": 2,
          "text": "Thanks. I come back.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"I'll come back\" にしよう。"
        },
        {
          "option_id": 3,
          "text": "Yes, back.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "返事が短い、\"Thank you\" から。"
        },
        {
          "option_id": 4,
          "text": "Thank. See you.",
          "is_correct": false,
          "is_acceptable": false,
          "explanation": "\"Thank you\" が正しい形。"
        }
      ]
    }
  ]
}$tt_sam_shop_stock_v3$::jsonb
)
ON CONFLICT (scenario_id) DO UPDATE SET
  payload_json      = EXCLUDED.payload_json,
  pattern_no        = EXCLUDED.pattern_no,
  npc_id            = EXCLUDED.npc_id,
  place             = EXCLUDED.place,
  theme             = EXCLUDED.theme,
  difficulty        = EXCLUDED.difficulty,
  reward_coins      = EXCLUDED.reward_coins,
  reward_friendship = EXCLUDED.reward_friendship,
  mowi_message      = EXCLUDED.mowi_message,
  total_turns       = EXCLUDED.total_turns,
  updated_at        = now();
