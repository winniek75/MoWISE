/**
 * Word Tower vocabulary data
 * 50 words mapped to P001-P010, with Unsplash real photo URLs
 */

export interface WordTowerWord {
  id: string
  en: string
  ja: string
  image: string
  patternNo: string
  category: 'adjective' | 'noun' | 'verb' | 'place' | 'food'
  difficulty: 1 | 2 | 3
}

// Unsplash image URLs (400x400 crop, free license)
export const WORD_TOWER_WORDS: WordTowerWord[] = [
  // P001: I'm [adjective]
  { id: 'w01', en: 'tired',   ja: '疲れた',     image: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400&h=400&fit=crop', patternNo: 'P001', category: 'adjective', difficulty: 1 },
  { id: 'w02', en: 'happy',   ja: 'うれしい',   image: 'https://images.unsplash.com/photo-1535930749574-1399327ce78f?w=400&h=400&fit=crop', patternNo: 'P001', category: 'adjective', difficulty: 1 },
  { id: 'w03', en: 'hungry',  ja: 'お腹すいた', image: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=400&fit=crop', patternNo: 'P001', category: 'adjective', difficulty: 1 },
  { id: 'w04', en: 'hot',     ja: '暑い',       image: 'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=400&h=400&fit=crop', patternNo: 'P001', category: 'adjective', difficulty: 1 },
  { id: 'w05', en: 'cold',    ja: '寒い',       image: 'https://images.unsplash.com/photo-1491002052546-bf38f186af56?w=400&h=400&fit=crop', patternNo: 'P001', category: 'adjective', difficulty: 1 },
  { id: 'w06', en: 'ready',   ja: '準備OK',     image: 'https://images.unsplash.com/photo-1526676037777-05a232554f77?w=400&h=400&fit=crop', patternNo: 'P001', category: 'adjective', difficulty: 1 },

  // P002: This is [noun]
  { id: 'w07', en: 'pen',     ja: 'ペン',       image: 'https://images.unsplash.com/photo-1585336261022-680e295ce3fe?w=400&h=400&fit=crop', patternNo: 'P002', category: 'noun', difficulty: 1 },
  { id: 'w08', en: 'book',    ja: '本',         image: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=400&fit=crop', patternNo: 'P002', category: 'noun', difficulty: 1 },
  { id: 'w09', en: 'bag',     ja: 'カバン',     image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=400&fit=crop', patternNo: 'P002', category: 'noun', difficulty: 1 },
  { id: 'w10', en: 'phone',   ja: '電話',       image: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=400&fit=crop', patternNo: 'P002', category: 'noun', difficulty: 1 },
  { id: 'w11', en: 'desk',    ja: '机',         image: 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=400&h=400&fit=crop', patternNo: 'P002', category: 'noun', difficulty: 1 },

  // P004: I like [noun]
  { id: 'w12', en: 'soccer',   ja: 'サッカー',   image: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=400&h=400&fit=crop', patternNo: 'P004', category: 'noun', difficulty: 1 },
  { id: 'w13', en: 'music',    ja: '音楽',       image: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&h=400&fit=crop', patternNo: 'P004', category: 'noun', difficulty: 1 },
  { id: 'w14', en: 'pizza',    ja: 'ピザ',       image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=400&fit=crop', patternNo: 'P004', category: 'noun', difficulty: 1 },
  { id: 'w15', en: 'dogs',     ja: '犬',         image: 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400&h=400&fit=crop', patternNo: 'P004', category: 'noun', difficulty: 1 },
  { id: 'w16', en: 'cats',     ja: '猫',         image: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=400&fit=crop', patternNo: 'P004', category: 'noun', difficulty: 1 },
  { id: 'w17', en: 'reading',  ja: '読書',       image: 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=400&h=400&fit=crop', patternNo: 'P004', category: 'noun', difficulty: 1 },

  // P005: I want [noun]
  { id: 'w18', en: 'water',     ja: '水',         image: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400&h=400&fit=crop', patternNo: 'P005', category: 'noun', difficulty: 1 },
  { id: 'w19', en: 'coffee',    ja: 'コーヒー',   image: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=400&fit=crop', patternNo: 'P005', category: 'noun', difficulty: 1 },
  { id: 'w20', en: 'ice cream', ja: 'アイス',     image: 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400&h=400&fit=crop', patternNo: 'P005', category: 'food', difficulty: 1 },
  { id: 'w21', en: 'chocolate', ja: 'チョコレート', image: 'https://images.unsplash.com/photo-1481391319762-47dff72954d9?w=400&h=400&fit=crop', patternNo: 'P005', category: 'food', difficulty: 1 },

  // P006: I have [noun]
  { id: 'w22', en: 'car',       ja: '車',         image: 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=400&h=400&fit=crop', patternNo: 'P006', category: 'noun', difficulty: 1 },
  { id: 'w23', en: 'pet',       ja: 'ペット',     image: 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=400&h=400&fit=crop', patternNo: 'P006', category: 'noun', difficulty: 1 },
  { id: 'w24', en: 'homework',  ja: '宿題',       image: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400&h=400&fit=crop', patternNo: 'P006', category: 'noun', difficulty: 2 },

  // P007: I can [verb]
  { id: 'w25', en: 'swim',      ja: '泳ぐ',       image: 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=400&h=400&fit=crop', patternNo: 'P007', category: 'verb', difficulty: 1 },
  { id: 'w26', en: 'cook',      ja: '料理する',   image: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400&h=400&fit=crop', patternNo: 'P007', category: 'verb', difficulty: 1 },
  { id: 'w27', en: 'dance',     ja: '踊る',       image: 'https://images.unsplash.com/photo-1508700929628-666bc8bd84ea?w=400&h=400&fit=crop', patternNo: 'P007', category: 'verb', difficulty: 1 },
  { id: 'w28', en: 'sing',      ja: '歌う',       image: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=400&h=400&fit=crop', patternNo: 'P007', category: 'verb', difficulty: 1 },
  { id: 'w29', en: 'run',       ja: '走る',       image: 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=400&h=400&fit=crop', patternNo: 'P007', category: 'verb', difficulty: 1 },

  // P008: I'm from [place]
  { id: 'w30', en: 'Japan',     ja: '日本',       image: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&h=400&fit=crop', patternNo: 'P008', category: 'place', difficulty: 1 },
  { id: 'w31', en: 'Tokyo',     ja: '東京',       image: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400&h=400&fit=crop', patternNo: 'P008', category: 'place', difficulty: 1 },
  { id: 'w32', en: 'America',   ja: 'アメリカ',   image: 'https://images.unsplash.com/photo-1485738422979-f5c462d49f04?w=400&h=400&fit=crop', patternNo: 'P008', category: 'place', difficulty: 1 },

  // P009: It's [adjective/noun]
  { id: 'w33', en: 'sunny',     ja: '晴れ',       image: 'https://images.unsplash.com/photo-1622396481328-9b1b78cdd9fd?w=400&h=400&fit=crop', patternNo: 'P009', category: 'adjective', difficulty: 1 },
  { id: 'w34', en: 'rainy',     ja: '雨',         image: 'https://images.unsplash.com/photo-1515694346937-94d85e39e29e?w=400&h=400&fit=crop', patternNo: 'P009', category: 'adjective', difficulty: 1 },
  { id: 'w35', en: 'beautiful', ja: '美しい',     image: 'https://images.unsplash.com/photo-1490750967868-88aa4f44baee?w=400&h=400&fit=crop', patternNo: 'P009', category: 'adjective', difficulty: 2 },
  { id: 'w36', en: 'big',       ja: '大きい',     image: 'https://images.unsplash.com/photo-1557050543-4d5f4e07ef46?w=400&h=400&fit=crop', patternNo: 'P009', category: 'adjective', difficulty: 1 },
  { id: 'w37', en: 'small',     ja: '小さい',     image: 'https://images.unsplash.com/photo-1472491235688-bdc81a63246e?w=400&h=400&fit=crop', patternNo: 'P009', category: 'adjective', difficulty: 1 },

  // P010: Thank you for [noun/gerund]
  { id: 'w38', en: 'rice',      ja: 'ご飯',       image: 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=400&h=400&fit=crop', patternNo: 'P010', category: 'food', difficulty: 1 },
  { id: 'w39', en: 'bread',     ja: 'パン',       image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=400&fit=crop', patternNo: 'P010', category: 'food', difficulty: 1 },
  { id: 'w40', en: 'apple',     ja: 'りんご',     image: 'https://images.unsplash.com/photo-1568702846914-96b305d2ead1?w=400&h=400&fit=crop', patternNo: 'P010', category: 'food', difficulty: 1 },
  { id: 'w41', en: 'banana',    ja: 'バナナ',     image: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&h=400&fit=crop', patternNo: 'P010', category: 'food', difficulty: 1 },
  { id: 'w42', en: 'egg',       ja: '卵',         image: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400&h=400&fit=crop', patternNo: 'P010', category: 'food', difficulty: 1 },
  { id: 'w43', en: 'chicken',   ja: '鶏肉',       image: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=400&h=400&fit=crop', patternNo: 'P010', category: 'food', difficulty: 1 },
  { id: 'w44', en: 'salad',     ja: 'サラダ',     image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=400&fit=crop', patternNo: 'P010', category: 'food', difficulty: 1 },

  // Extra high-frequency words
  { id: 'w45', en: 'school',    ja: '学校',       image: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=400&h=400&fit=crop', patternNo: 'P009', category: 'place', difficulty: 1 },
  { id: 'w46', en: 'friend',    ja: '友達',       image: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&h=400&fit=crop', patternNo: 'P006', category: 'noun', difficulty: 1 },
  { id: 'w47', en: 'teacher',   ja: '先生',       image: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400&h=400&fit=crop', patternNo: 'P002', category: 'noun', difficulty: 1 },
  { id: 'w48', en: 'park',      ja: '公園',       image: 'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=400&h=400&fit=crop', patternNo: 'P009', category: 'place', difficulty: 1 },
  { id: 'w49', en: 'movie',     ja: '映画',       image: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400&h=400&fit=crop', patternNo: 'P004', category: 'noun', difficulty: 2 },
  { id: 'w50', en: 'sleep',     ja: '寝る',       image: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400&h=400&fit=crop', patternNo: 'P007', category: 'verb', difficulty: 1 },
]

/**
 * Pick 8 words for one round.
 * If patternNo given, prioritize words from that pattern.
 */
export function pickRoundWords(patternNo?: string): WordTowerWord[] {
  const pool = [...WORD_TOWER_WORDS]
  const selected: WordTowerWord[] = []

  if (patternNo) {
    const patternWords = pool.filter(w => w.patternNo === patternNo)
    const shuffled = patternWords.sort(() => Math.random() - 0.5)
    selected.push(...shuffled.slice(0, 4))
  }

  const remaining = pool.filter(w => !selected.includes(w)).sort(() => Math.random() - 0.5)
  while (selected.length < 8 && remaining.length > 0) {
    selected.push(remaining.shift()!)
  }

  return selected.sort(() => Math.random() - 0.5)
}

/**
 * Pick decoy words for slot display (excluding the correct answer)
 */
export function pickDecoys(correct: WordTowerWord, count: number): WordTowerWord[] {
  const sameCategory = WORD_TOWER_WORDS.filter(w => w.id !== correct.id && w.category === correct.category)
  const otherCategory = WORD_TOWER_WORDS.filter(w => w.id !== correct.id && w.category !== correct.category)

  const decoys: WordTowerWord[] = []
  const shuffledSame = sameCategory.sort(() => Math.random() - 0.5)
  const shuffledOther = otherCategory.sort(() => Math.random() - 0.5)

  // 2 same-category decoys, rest from other
  decoys.push(...shuffledSame.slice(0, Math.min(2, count)))
  while (decoys.length < count && shuffledOther.length > 0) {
    decoys.push(shuffledOther.shift()!)
  }
  while (decoys.length < count && shuffledSame.length > decoys.filter(d => d.category === correct.category).length) {
    const next = shuffledSame.find(s => !decoys.includes(s))
    if (next) decoys.push(next)
    else break
  }

  return decoys.slice(0, count)
}
