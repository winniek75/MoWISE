# B101 "Where Is Momo?" イラスト生成プロンプト（Nano Banana用）

## 共通スタイル指定（全プロンプトの先頭に付ける）

```
Children's picture book illustration, soft flat pastel colors, thick clean outlines,
simple shapes, warm and cozy atmosphere, no text in image, plain light background.
Main character: a small round orange tabby cat named Momo with big friendly eyes.
```

キャラの一貫性のため、最初に表紙を生成 → 気に入った1枚を Nano Banana の参照画像にして残りを生成してください。

## 生成リスト（計17枚）

| ファイル名 | サイズ | プロンプト（共通スタイルの後に追記） |
|---|---|---|
| cover.png | 1024×1024 | The orange cat Momo peeking out from behind a school bag, playful mood, book cover composition with space at top |
| page_01.png | 1024×768 | A child hugging the orange cat Momo, both smiling |
| page_02.png | 1024×768 | The child looking around a living room with a confused expression, question marks style mood, no cat visible |
| page_03.png | 1024×768 | The child looking inside an empty cardboard box |
| page_04.png | 1024×768 | The child looking under a bed, nothing there |
| page_05.png | 1024×768 | The child checking an empty green sofa |
| page_06.png | 1024×768 | The child looking around a small garden with flowers, no cat |
| page_07.png | 1024×768 | The orange cat Momo sitting proudly on top of a red school bag, child pointing happily |
| page_08.png | 1024×768 | The child hugging Momo tightly, hearts in the air, warm ending scene |
| q1_a.png | 512×512 | A cute orange cat sitting, icon style, centered |
| q1_b.png | 512×512 | A cute brown dog sitting, icon style, centered |
| q1_c.png | 512×512 | A cute blue bird, icon style, centered |
| q1_d.png | 512×512 | A cute goldfish, icon style, centered |
| q2_a.png | 512×512 | A green sofa, icon style, centered |
| q2_b.png | 512×512 | A red school bag, icon style, centered |
| q2_c.png | 512×512 | A brown cardboard box, icon style, centered |
| q2_d.png | 512×512 | A wooden bed, icon style, centered |

## アップロード先（Supabase Storage）

すべて `reading/B101/` にファイル名そのままでアップロード。
Step 1 実装は画像未配置でもプレースホルダーで動く仕様なので、イラストは後追いでOKです。
