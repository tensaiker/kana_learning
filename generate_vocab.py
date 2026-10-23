import os
import json

# Kana to Romaji mapping table (including compound Yoon & Dakuon)
KANA_TO_ROMAJI = {
    # Yoon (Compound 2-char kana)
    "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
    "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
    "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
    "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
    "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
    "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
    "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",
    "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
    "じゃ": "ja",  "じゅ": "ju",  "じょ": "jo",
    "びゃ": "bya", "びゅ": "byu", "びょ": "byo",
    "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
    "キャ": "kya", "キュ": "kyu", "キョ": "kyo",
    "シャ": "sha", "シュ": "shu", "ショ": "sho",
    "チャ": "cha", "チュ": "chu", "チョ": "cho",
    "ニャ": "nya", "ニュ": "nyu", "ニョ": "nyo",
    "ヒャ": "hya", "ヒュ": "hyu", "ヒョ": "hyo",
    "ミャ": "mya", "ミュ": "myu", "ミョ": "myo",
    "リャ": "rya", "リュ": "ryu", "リョ": "ryo",
    "ギャ": "gya", "ギュ": "gyu", "ギョ": "gyo",
    "ジャ": "ja",  "ジュ": "ju",  "ジョ": "jo",
    "ビャ": "bya", "ビュ": "byu", "ビョ": "byo",
    "ピャ": "pya", "ピュ": "pyu", "ピョ": "pyo",
    "ティ": "ti",  "ディ": "di",  "チェ": "che",
    "シェ": "she", "ジェ": "je",  "ファ": "fa",
    "フィ": "fi",  "フェ": "fe",  "フォ": "fo",
    # Single Hiragana
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo",
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    "わ": "wa", "を": "wo", "ん": "n",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    # Single Katakana
    "ア": "a", "イ": "i", "ウ": "u", "エ": "e", "オ": "o",
    "カ": "ka", "キ": "ki", "ク": "ku", "ケ": "ke", "コ": "ko",
    "サ": "sa", "シ": "shi", "ス": "su", "セ": "se", "ソ": "so",
    "タ": "ta", "チ": "chi", "ツ": "tsu", "テ": "te", "ト": "to",
    "ナ": "na", "ニ": "ni", "ヌ": "nu", "ネ": "ne", "ノ": "no",
    "ハ": "ha", "ヒ": "hi", "フ": "fu", "ヘ": "he", "ホ": "ho",
    "マ": "ma", "ミ": "mi", "ム": "mu", "メ": "me", "モ": "mo",
    "ヤ": "ya", "ユ": "yu", "ヨ": "yo",
    "ラ": "ra", "リ": "ri", "ル": "ru", "レ": "re", "ロ": "ro",
    "ワ": "wa", "ヲ": "wo", "ン": "n",
    "ガ": "ga", "ギ": "gi", "グ": "gu", "ゲ": "ge", "ゴ": "go",
    "ザ": "za", "ジ": "ji", "ズ": "zu", "ゼ": "ze", "ゾ": "zo",
    "ダ": "da", "ヂ": "ji", "ヅ": "zu", "デ": "de", "ド": "do",
    "バ": "ba", "ビ": "bi", "ブ": "bu", "ベ": "be", "ボ": "bo",
    "パ": "pa", "ピ": "pi", "プ": "pu", "ペ": "pe", "ポ": "po",
    "ー": "-",
}

def tokenize_kana(kana_str: str):
    kana_syllables = []
    romaji_syllables = []
    i = 0
    n = len(kana_str)

    while i < n:
        if i + 1 < n and kana_str[i:i+2] in KANA_TO_ROMAJI:
            token = kana_str[i:i+2]
            kana_syllables.append(token)
            romaji_syllables.append(KANA_TO_ROMAJI[token])
            i += 2
        elif kana_str[i] in KANA_TO_ROMAJI:
            token = kana_str[i]
            if token == "ー" and romaji_syllables:
                last_char = romaji_syllables[-1][-1]
                kana_syllables.append(token)
                romaji_syllables.append(last_char)
            elif token in ("っ", "ッ") and i + 1 < n:
                next_char = kana_str[i+1]
                next_romaji = KANA_TO_ROMAJI.get(next_char, "")
                cons = next_romaji[0] if next_romaji else "t"
                kana_syllables.append(token)
                romaji_syllables.append(cons)
            else:
                kana_syllables.append(token)
                romaji_syllables.append(KANA_TO_ROMAJI[token])
            i += 1
        else:
            i += 1

    full_romaji = "".join(romaji_syllables)
    return kana_syllables, romaji_syllables, full_romaji

def is_hiragana_str(s: str) -> bool:
    for ch in s:
        code = ord(ch)
        if 0x3040 <= code <= 0x309F:
            return True
    return False

# Base JLPT N5 - N4 Vocabulary
RAW_VOCABULARY = [
    # Animals & Nature
    ("ねこ", "cat"), ("いぬ", "dog"), ("とり", "bird"), ("さかな", "fish"),
    ("うま", "horse"), ("うし", "cow"), ("ぶた", "pig"), ("ひつじ", "sheep"),
    ("さる", "monkey"), ("くま", "bear"), ("ぞう", "elephant"), ("きりん", "giraffe"),
    ("うさぎ", "rabbit"), ("ねずみ", "mouse"), ("かめ", "turtle"), ("へび", "snake"),
    ("むし", "insect"), ("やま", "mountain"), ("かわ", "river"), ("うみ", "sea"),
    ("そら", "sky"), ("つき", "moon"), ("たいよう", "sun"), ("ほし", "star"),
    ("あめ", "rain"), ("ゆき", "snow"), ("かぜ", "wind"), ("くも", "cloud"),
    ("はな", "flower"), ("き", "tree"), ("もり", "forest"), ("はたけ", "field"),
    ("いけ", "pond"), ("しま", "island"), ("くさ", "grass"), ("はっぱ", "leaf"),
    ("いわ", "rock"), ("すな", "sand"), ("つち", "soil"), ("たに", "valley"),

    # Food & Dining
    ("みず", "water"), ("おちゃ", "green tea"), ("こうちゃ", "black tea"), ("ぎゅうにゅう", "milk"),
    ("ごはん", "cooked rice"), ("あさごはん", "breakfast"), ("ひるごはん", "lunch"), ("ばんごはん", "dinner"),
    ("にく", "meat"), ("とりにく", "chicken meat"), ("ぎゅうにく", "beef"), ("ぶたにく", "pork"),
    ("たまご", "egg"), ("やさい", "vegetables"), ("くだもの", "fruits"), ("りんご", "apple"),
    ("みかん", "mandarin orange"), ("いちご", "strawberry"), ("すいか", "watermelon"), ("ぶどう", "grapes"),
    ("さかな", "fish"), ("えび", "shrimp"), ("かい", "shellfish"), ("さとう", "sugar"),
    ("しお", "salt"), ("しょうゆ", "soy sauce"), ("す", "vinegar"), ("あぶら", "cooking oil"),
    ("みそ", "miso"), ("みそしる", "miso soup"), ("すし", "sushi"), ("さしみ", "sashimi"),
    ("そば", "soba noodles"), ("うどん", "udon noodles"), ("てんぷら", "tempura"), ("すきやき", "sukiyaki"),
    ("なべ", "hot pot"), ("おかし", "sweets"), ("あめ", "candy"), ("こおり", "ice"),
    ("さけ", "rice wine"), ("りょうり", "cooking"), ("あじ", "flavor"), ("べんとう", "box lunch"),

    # People & Family
    ("ひと", "person"), ("おとこ", "man"), ("おんな", "woman"), ("こども", "child"),
    ("あかちゃん", "baby"), ("おとな", "adult"), ("ともだち", "friend"), ("かぞく", "family"),
    ("おとうさん", "father"), ("おかあさん", "mother"), ("おにいさん", "older brother"), ("おねえさん", "older sister"),
    ("おとうと", "younger brother"), ("いもうと", "younger sister"), ("おじいさん", "grandfather"), ("おばあさん", "grandmother"),
    ("おじさん", "uncle"), ("おばさん", "aunt"), ("せんせい", "teacher"), ("がくせい", "student"),
    ("いしゃ", "doctor"), ("かんごし", "nurse"), ("けいさつ", "police"), ("てんいん", "shop clerk"),
    ("かいしゃいん", "office worker"), ("かしゅ", "singer"), ("さっか", "writer"), ("きゃく", "guest"),

    # Body Parts
    ("あたま", "head"), ("かお", "face"), ("め", "eye"), ("みみ", "ear"),
    ("はな", "nose"), ("くち", "mouth"), ("は", "tooth"), ("した", "tongue"),
    ("くび", "neck"), ("かた", "shoulder"), ("うで", "arm"), ("て", "hand"),
    ("ゆび", "finger"), ("つめ", "nail"), ("むね", "chest"), ("おなか", "stomach"),
    ("せなか", "back"), ("こし", "lower back"), ("あし", "leg/foot"), ("ひざ", "knee"),
    ("からだ", "body"), ("こころ", "heart/mind"), ("こえ", "voice"), ("ち", "blood"),

    # Home & Objects
    ("いえ", "house"), ("うち", "home"), ("へや", "room"), ("まど", "window"),
    ("とびら", "door"), ("つくえ", "desk"), ("いす", "chair"), ("ほん", "book"),
    ("ほんたな", "bookshelf"), ("でんき", "electricity/light"), ("とけい", "clock/watch"), ("かみ", "paper"),
    ("えんぴつ", "pencil"), ("ふでばこ", "pencil case"), ("かばん", "bag"), ("さいふ", "wallet"),
    ("かぎ", "key"), ("かさ", "umbrella"), ("くつ", "shoes"), ("くつした", "socks"),
    ("ふく", "clothes"), ("ぼうし", "hat"), ("めがね", "glasses"), ("かがみ", "mirror"),
    ("はこ", "box"), ("さら", "plate"), ("はし", "chopsticks"), ("ちゃわん", "rice bowl"),
    ("ゆのみ", "teacup"), ("ふとん", "futon"), ("まくら", "pillow"), ("タオル", "towel"),
    ("せっけん", "soap"), ("はブラシ", "toothbrush"), ("くし", "comb"), ("ゴミ", "trash"),

    # City & Transport
    ("まち", "city"), ("みち", "street"), ("はし", "bridge"), ("えき", "station"),
    ("てんぽ", "store"), ("みせ", "shop"), ("ぎんこう", "bank"), ("ゆうびんきょく", "post office"),
    ("びょういん", "hospital"), ("がっこう", "school"), ("だいがく", "university"), ("としょかん", "library"),
    ("こうえん", "park"), ("どうぶつえん", "zoo"), ("すいぞくかん", "aquarium"), ("えいがかん", "cinema"),
    ("じんじゃ", "shrine"), ("おてら", "temple"), ("しろ", "castle"), ("くに", "country"),
    ("がいこく", "abroad"), ("ひこうじょう", "airport"), ("みなと", "port"), ("くるま", "car"),
    ("でんしゃ", "train"), ("ちかてつ", "subway"), ("じてんしゃ", "bicycle"), ("ふね", "ship"),
    ("ひこうき", "plane"), ("きっぷ", "ticket"), ("りょこう", "travel"), ("にもつ", "baggage"),

    # Time & Days
    ("いま", "now"), ("きょう", "today"), ("あした", "tomorrow"), ("きのう", "yesterday"),
    ("あさ", "morning"), ("ひる", "afternoon"), ("ゆうがた", "evening"), ("よる", "night"),
    ("まいあさ", "every morning"), ("まいにち", "every day"), ("まいばん", "every night"), ("まいしゅう", "every week"),
    ("まいげつ", "every month"), ("まいとし", "every year"), ("こんしゅう", "this week"), ("らいしゅう", "next week"),
    ("せんしゅう", "last week"), ("こんげつ", "this month"), ("らいげつ", "next month"), ("せんげつ", "last month"),
    ("ことし", "this year"), ("らいねん", "next year"), ("きょねん", "last year"), ("じかん", "time"),
    ("ふん", "minute"), ("びょう", "second"), ("しゅう", "week"), ("つき", "month"),
    ("はる", "spring"), ("なつ", "summer"), ("あき", "autumn"), ("ふゆ", "winter"),
    ("げつようび", "Monday"), ("かようび", "Tuesday"), ("すいようび", "Wednesday"), ("もくようび", "Thursday"),
    ("きんようび", "Friday"), ("どようび", "Saturday"), ("にちようび", "Sunday"), ("やすみ", "holiday"),

    # Verbs
    ("たべる", "to eat"), ("のむ", "to drink"), ("みる", "to see"), ("きく", "to listen"),
    ("よむ", "to read"), ("かく", "to write"), ("はなす", "to speak"), ("いう", "to say"),
    ("いく", "to go"), ("くる", "to come"), ("かえる", "to return"), ("あるく", "to walk"),
    ("はしる", "to run"), ("およぐ", "to swim"), ("あそぶ", "to play"), ("ねる", "to sleep"),
    ("おきる", "to wake up"), ("すわる", "to sit"), ("たつ", "to stand"), ("あう", "to meet"),
    ("かう", "to buy"), ("うる", "to sell"), ("まつ", "to wait"), ("もつ", "to hold"),
    ("あける", "to open"), ("しめる", "to close"), ("つける", "to turn on"), ("けす", "to turn off"),
    ("おしえる", "to teach"), ("ならう", "to learn"), ("つくる", "to make"), ("つかう", "to use"),
    ("とる", "to take"), ("おく", "to put"), ("はいる", "to enter"), ("でる", "to exit"),
    ("あらう", "to wash"), ("うたう", "to sing"), ("わらう", "to laugh"), ("なく", "to cry"),
    ("おもう", "to think"), ("しる", "to know"), ("わかる", "to understand"), ("わすれる", "to forget"),
    ("おぼえる", "to remember"), ("たすける", "to help"), ("はたらく", "to work"), ("やすむ", "to rest"),

    # Adjectives
    ("おおきい", "big"), ("ちいさい", "small"), ("たかい", "tall/expensive"), ("ひくい", "low/short"),
    ("やすい", "cheap"), ("あたらしい", "new"), ("ふるい", "old"), ("よい", "good"),
    ("わるい", "bad"), ("あつい", "hot"), ("さむい", "cold"), ("つめたい", "cold to touch"),
    ("あたたかい", "warm"), ("すずしい", "cool"), ("あかるい", "bright"), ("くらい", "dark"),
    ("ながい", "long"), ("みじかい", "short"), ("おもい", "heavy"), ("かるい", "light"),
    ("はやい", "fast"), ("おそい", "slow"), ("ちかい", "near"), ("とおい", "far"),
    ("ひろい", "wide"), ("せまい", "narrow"), ("つよい", "strong"), ("よわい", "weak"),
    ("むずかしい", "difficult"), ("やさしい", "easy"), ("おもしろい", "interesting"), ("たのしい", "fun"),
    ("いそがしい", "busy"), ("おいしい", "delicious"), ("まずい", "bad tasting"), ("あまい", "sweet"),
    ("からい", "spicy"), ("すっぱい", "sour"), ("にがい", "bitter"), ("しおからい", "salty"),
    ("きれい", "pretty"), ("しずか", "quiet"), ("にぎやか", "lively"), ("べんり", "convenient"),
    ("ふべん", "inconvenient"), ("げんき", "healthy"), ("ひま", "free time"), ("じょうず", "skillful"),
    ("へた", "unskillful"), ("たいせつ", "important"), ("だいじょうぶ", "okay"),

    # Katakana Loanwords
    ("パン", "bread"), ("ペン", "pen"), ("ノート", "notebook"), ("バス", "bus"),
    ("ドア", "door"), ("テレビ", "television"), ("カメラ", "camera"), ("ラジオ", "radio"),
    ("バナナ", "banana"), ("ホテル", "hotel"), ("タクシー", "taxi"), ("コーヒー", "coffee"),
    ("ミルク", "milk"), ("ジュース", "juice"), ("コーラ", "cola"), ("ビール", "beer"),
    ("ワイン", "wine"), ("ケーキ", "cake"), ("チョコ", "chocolate"), ("アイス", "ice cream"),
    ("サラダ", "salad"), ("スープ", "soup"), ("ピザ", "pizza"), ("パスタ", "pasta"),
    ("ハンバーガー", "hamburger"), ("カレー", "curry"), ("サンドイッチ", "sandwich"), ("ステーキ", "steak"),
    ("パソコン", "computer"), ("スマホ", "smartphone"), ("ネット", "internet"), ("メール", "email"),
    ("アプリ", "app"), ("ゲーム", "game"), ("ビデオ", "video"), ("ピアノ", "piano"),
    ("ギター", "guitar"), ("スポーツ", "sports"), ("サッカー", "soccer"), ("テニス", "tennis"),
    ("スキー", "skiing"), ("プール", "pool"), ("レストラン", "restaurant"), ("スーパー", "supermarket"),
    ("コンビニ", "convenience store"), ("デパート", "department store"), ("ビル", "building"), ("アパート", "apartment"),
    ("エレベーター", "elevator"), ("エスカレーター", "escalator"), ("トイレ", "restroom"), ("シャワー", "shower"),
    ("ベッド", "bed"), ("ソファ", "sofa"), ("テーブル", "table"), ("エアコン", "air conditioner"),
    ("シャツ", "shirt"), ("ズボン", "pants"), ("スカート", "skirt"), ("コート", "coat"),
    ("セーター", "sweater"), ("ネクタイ", "necktie"), ("ブーツ", "boots"), ("サンダル", "sandals"),
    ("プレゼント", "gift"), ("パーティー", "party"), ("ニュース", "news"), ("カレンダー", "calendar"),
    ("ポスト", "mailbox"), ("チケット", "ticket"), ("パスポート", "passport"), ("チャンス", "chance"),
    ("デザート", "dessert"), ("メロン", "melon"), ("レモン", "lemon"), ("トマト", "tomato"),
    ("ポテト", "potato"), ("チーズ", "cheese"), ("バター", "butter"), ("ジャム", "jam"),
    ("フォーク", "fork"), ("スプーン", "spoon"), ("ナイフ", "knife"), ("コップ", "cup/glass"),
    ("ストロー", "straw"), ("カップ", "mug"), ("ポット", "pot/kettle"), ("フライパン", "frying pan"),
    ("ストーブ", "stove"), ("ヒーター", "heater"), ("ライト", "light"), ("スイッチ", "switch"),
    ("カーテン", "curtain"), ("シーツ", "bed sheets"), ("ブランケット", "blanket"), ("クッション", "cushion"),
    ("ブラシ", "brush"), ("シャンプー", "shampoo"), ("リンス", "conditioner"), ("ドライヤー", "hair dryer"),
    ("プラスチック", "plastic"), ("ガラス", "glass"), ("ビニール", "vinyl"), ("ゴム", "rubber"),

    # Adverbs, Conjunctions & Grammar Expressions
    ("いつも", "always"), ("よく", "often"), ("ときどき", "sometimes"), ("あまり", "not much"),
    ("ぜんぜん", "not at all"), ("とても", "very"), ("すこし", "a little"), ("たくさん", "a lot"),
    ("もうすぐ", "soon"), ("ちょうど", "exactly"), ("たぶん", "probably"), ("ぜったい", "definitely"),
    ("ゆっくり", "slowly"), ("はやく", "quickly"), ("いっしょに", "together"), ("ひとりで", "alone"),
    ("まず", "first of all"), ("つぎに", "next"), ("それから", "after that"), ("そして", "and then"),
    ("しかし", "however"), ("だから", "therefore"), ("でも", "but"), ("どうして", "why"),
    ("なぜ", "why"), ("ほんとうに", "really"), ("もちろん", "of course"), ("たしかに", "certainly"),

    # Colors & Counters
    ("あか", "red"), ("あお", "blue"), ("きいろ", "yellow"), ("しろ", "white"),
    ("くろ", "black"), ("みどり", "green"), ("ちゃいろ", "brown"), ("ピンク", "pink"),
    ("オレンジ", "orange"), ("むらさき", "purple"), ("はいいろ", "gray"), ("きんいろ", "gold"),
    ("ぎんいろ", "silver"), ("ひとつ", "one object"), ("ふたつ", "two objects"), ("みっつ", "three objects"),
    ("よっつ", "four objects"), ("いつつ", "five objects"), ("むっつ", "six objects"), ("ななつ", "seven objects"),
    ("やっつ", "eight objects"), ("ここのつ", "nine objects"), ("とお", "ten objects"),
    ("ひとり", "one person"), ("ふたり", "two people"), ("さんにん", "three people"), ("よにん", "four people"),
    ("ごにん", "five people"), ("ろくにん", "six people"), ("しちにん", "seven people"),
]

def main():
    results = []
    seen_kana = set()

    for kana, english in RAW_VOCABULARY:
        if kana in seen_kana:
            continue

        kana_syllables, romaji_syllables, romaji = tokenize_kana(kana)
        if not kana_syllables or len(kana_syllables) < 2:
            continue

        seen_kana.add(kana)
        results.append({
            "kana": kana,
            "romaji": romaji,
            "english": english,
            "isHiragana": is_hiragana_str(kana),
            "syllables": romaji_syllables,
            "kanaSyllables": kana_syllables
        })

    # Systematic JLPT inflections for verbs and adjectives
    additional = []
    for item in list(results):
        k = item["kana"]
        eng = item["english"]
        is_h = item["isHiragana"]

        if not is_h:
            continue

        # Verb forms
        if k.endswith(("る", "う", "く", "す", "つ", "ぬ", "ふ", "む")):
            # 1. -masu (polite present)
            stem = k[:-1]
            m_kana = stem + "ます"
            if m_kana not in seen_kana:
                ks, rs, r = tokenize_kana(m_kana)
                seen_kana.add(m_kana)
                additional.append({
                    "kana": m_kana, "romaji": r,
                    "english": f"{eng} (polite)",
                    "isHiragana": True, "syllables": rs, "kanaSyllables": ks
                })

            # 2. -mashita (polite past)
            m_past = stem + "ました"
            if m_past not in seen_kana:
                ks, rs, r = tokenize_kana(m_past)
                seen_kana.add(m_past)
                additional.append({
                    "kana": m_past, "romaji": r,
                    "english": f"{eng} (past polite)",
                    "isHiragana": True, "syllables": rs, "kanaSyllables": ks
                })

            # 3. -tai (desire form: "want to...")
            m_tai = stem + "たい"
            if m_tai not in seen_kana:
                ks, rs, r = tokenize_kana(m_tai)
                seen_kana.add(m_tai)
                additional.append({
                    "kana": m_tai, "romaji": r,
                    "english": f"want to {eng.replace('to ', '')}",
                    "isHiragana": True, "syllables": rs, "kanaSyllables": ks
                })

            # 4. -nai (negative plain form)
            if k.endswith("る"):
                m_nai = stem + "ない"
                if m_nai not in seen_kana:
                    ks, rs, r = tokenize_kana(m_nai)
                    seen_kana.add(m_nai)
                    additional.append({
                        "kana": m_nai, "romaji": r,
                        "english": f"to not {eng.replace('to ', '')}",
                        "isHiragana": True, "syllables": rs, "kanaSyllables": ks
                    })

        # Adjective forms: -kunai (negative) & -katta (past)
        if k.endswith("い") and not k.endswith("ない"):
            adj_stem = k[:-1]
            # -kunai
            k_neg = adj_stem + "くない"
            if k_neg not in seen_kana:
                ks, rs, r = tokenize_kana(k_neg)
                seen_kana.add(k_neg)
                additional.append({
                    "kana": k_neg, "romaji": r,
                    "english": f"not {eng}",
                    "isHiragana": True, "syllables": rs, "kanaSyllables": ks
                })

            # -katta (past)
            k_past = adj_stem + "かった"
            if k_past not in seen_kana:
                ks, rs, r = tokenize_kana(k_past)
                seen_kana.add(k_past)
                additional.append({
                    "kana": k_past, "romaji": r,
                    "english": f"was {eng}",
                    "isHiragana": True, "syllables": rs, "kanaSyllables": ks
                })

    results.extend(additional)

    # Cap to exact 1,000 words
    final_dataset = results[:1000]

    out_dir = os.path.join("assets", "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "vocabulary.json")

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(final_dataset, f, ensure_ascii=False, indent=2)

    print(f"Successfully generated {len(final_dataset)} words into {out_path}!")

if __name__ == "__main__":
    main()