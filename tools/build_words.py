"""Build the bundled word list for the app from the KRDict (한국어기초사전) XML dump.

Data: 국립국어원 한국어기초사전, CC BY-SA 2.0 KR (https://krdict.korean.go.kr).
Order: word frequency from hermitdave/FrequencyWords (OpenSubtitles 2018, CC BY-SA 4.0).

Usage:
    python tools/build_words.py                  # 초급 -> assets/data/words.json
    python tools/build_words.py --levels 초급,중급
    python tools/build_words.py --src <folder>   # folder of KRDict .json or .xml files

Source: the official full download from krdict.korean.go.kr (사전 내려받기 → JSON), unzipped
into the project root (it is git-ignored); the newest "*한국어기초사전_json*" folder is picked up
automatically. Without it, the 2019 XML mirror is downloaded into tools/.cache/ (~370 MB).
"""

import argparse
import hashlib
import json
import random
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".cache"
KRDICT_BASE = "https://raw.githubusercontent.com/spellcheck-ko/korean-dict-nikl-krdict/master/"
KRDICT_FILES = [f"{n}.xml" for n in (5000, 10000, 15000, 20000, 25000, 30000,
                                     35000, 40000, 45000, 50000, 51947)]
FREQ_URL = "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/ko/ko_50k.txt"

POS_EN = {
    "명사": "noun", "의존 명사": "bound noun", "대명사": "pronoun", "수사": "numeral",
    "동사": "verb", "보조 동사": "auxiliary verb", "형용사": "adjective",
    "보조 형용사": "auxiliary adjective", "부사": "adverb", "관형사": "determiner",
    "감탄사": "interjection", "조사": "particle", "어미": "ending", "접사": "affix",
    "품사 없음": "expression",
}
# Grammar items aren't vocabulary cards; they belong in a future grammar feature.
SKIP_POS = {"어미", "접사", "조사"}
MAX_SENSES = 3
CJK = re.compile(r"[一-鿿]")
# One dump file has an unescaped "<" inside an attribute value.
ATTR_VAL = re.compile(r'val="([^"]*)"')

# Topic units of the curriculum, in recommended order: (id, English, Korean, emoji).
UNITS = [
    ("basics", "Greetings & basics", "기본 표현", "👋"),
    ("numbers", "Numbers & counting", "숫자", "🔢"),
    ("time", "Time & days", "시간", "⏰"),
    ("people", "Family & people", "가족과 사람", "👨‍👩‍👧"),
    ("food", "Food & drinks", "음식", "🍜"),
    ("home", "Home & daily life", "집과 일상", "🏠"),
    ("places", "Places & directions", "장소와 방향", "🧭"),
    ("transport", "Getting around", "교통", "🚇"),
    ("shopping", "Shopping & money", "쇼핑과 돈", "🛍️"),
    ("feelings", "Feelings", "감정", "😊"),
    ("body", "Body & health", "몸과 건강", "💪"),
    ("clothes", "Clothes & looks", "옷", "👕"),
    ("hobbies", "Hobbies & culture", "취미와 문화", "🎮"),
    ("nature", "Weather & nature", "날씨와 자연", "☀️"),
    ("school", "School & study", "학교", "🎓"),
    ("work", "Work & society", "일과 사회", "💼"),
    ("communication", "Talking & media", "소통", "💬"),
    ("describing", "Describing things", "모양과 성질", "🎨"),
    ("mind", "Thinking & abilities", "생각과 능력", "🧠"),
    ("more", "More useful words", "더 많은 단어", "📦"),
]

# KRDict semanticCategory -> unit. A "top > sub" key wins over its "top" key.
CATEGORY_UNIT = {
    "개념 > 인칭": "basics", "개념 > 지시": "basics", "개념 > 의문": "basics", "개념 > 접속": "basics",
    "개념 > 수": "numbers", "개념 > 세는 말": "numbers", "개념 > 순서": "numbers", "개념 > 양": "numbers",
    "개념 > 시간": "time", "개념 > 빈도": "time", "개념 > 속도": "time",
    "개념 > 위치 및 방향": "places", "개념 > 지역": "places",
    "개념": "describing",
    "삶 > 친족 관계": "people", "삶 > 가족 행사": "people",
    "인간 > 사람의 종류": "people", "인간 > 성격": "people", "인간 > 용모": "people",
    "식생활": "food",
    "주생활": "home", "삶 > 일상 행위": "home", "삶 > 삶의 행위": "home", "삶 > 삶의 상태": "home",
    "인간 > 감정": "feelings", "인간 > 태도": "feelings",
    "인간 > 인지 행위": "mind", "인간 > 능력": "mind",
    "인간 > 감각": "describing", "인간 > 소리": "describing",
    "인간": "body", "삶 > 병과 증상": "body", "삶 > 치료 행위": "body", "삶 > 치료 시설": "body",
    "삶 > 약품류": "body",
    "삶": "hobbies", "문화": "hobbies", "스포츠": "hobbies",
    "사회 생활 > 교통 수단": "transport", "사회 생활 > 교통 이용 장소": "transport",
    "사회 생활 > 교통 이용 행위": "transport",
    "사회 생활 > 언어 행위": "communication", "사회 생활 > 소통 수단": "communication",
    "사회 생활 > 통신 행위": "communication", "사회 생활 > 매체": "communication",
    "사회 생활 > 말": "communication",
    "사회 생활": "work",
    "경제 생활": "shopping",
    "의생활": "clothes",
    "교육": "school", "과학": "school",
    "자연": "nature", "동식물": "nature",
    "정치와 행정": "places", "종교": "places",
}


def unit_of(category: str | None, pos: str) -> str:
    if pos in ("interjection", "expression"):
        return "basics"
    if not category:
        return "more"
    top = category.split(" > ")[0]
    return CATEGORY_UNIT.get(category) or CATEGORY_UNIT.get(top) or "more"


def _jamo(syllable: str) -> tuple[int, int, int] | None:
    code = ord(syllable) - 0xAC00
    if not 0 <= code < 11172:
        return None
    return code // 588, (code % 588) // 28, code % 28


# Medial vowels an 아/어 form can end in: ㅏ ㅐ ㅓ ㅕ ㅘ ㅙ ㅝ (해, 써, 와, 돼, 줘...).
A_FORM_VOWELS = {0, 1, 4, 6, 9, 10, 14}


def conjugation_forms(entry: ET.Element) -> dict | None:
    """KRDict's 활용 forms: the 아/어 form (들어), the 으니 form (들으니) and the modifier (듣는/더운)."""
    forms = {}
    for wf in entry.findall("WordForm"):
        f = feats(wf)
        text = f.get("writtenForm", "")
        if f.get("type") != "활용" or not text:
            continue
        last = _jamo(text[-1])
        if text.endswith("니다"):
            continue
        if text.endswith("니"):
            forms.setdefault("euni", text)
        elif text.endswith("하여"):
            forms.setdefault("a", text[:-2] + "해")
        elif last and (text.endswith("는") or last[2] == 4):  # 는 or ㄴ batchim
            forms.setdefault("mod", text)
        elif last and last[2] == 0 and last[1] in A_FORM_VOWELS:
            forms.setdefault("a", text)
    return forms if {"a", "euni"} <= forms.keys() else None


def download(url: str, dest: Path) -> None:
    if dest.exists():
        return
    print(f"downloading {url}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    urllib.request.urlretrieve(url, tmp)
    tmp.rename(dest)


def parse_xml(path: Path) -> ET.Element:
    text = path.read_text(encoding="utf-8")
    text = ATTR_VAL.sub(lambda m: 'val="' + m.group(1).replace("<", "&lt;").replace(">", "&gt;") + '"', text)
    text = re.sub(r"<!DOCTYPE[^>]*>", "", text)
    return ET.fromstring(text)


def json_to_element(obj: dict, tag: str) -> ET.Element:
    """Turn a KRDict JSON node into the equivalent LMF XML element (single children are dicts, not lists)."""
    el = ET.Element(tag)
    if "att" in obj:
        el.set("att", obj["att"])
        el.set("val", str(obj.get("val", "")))
    for key, value in obj.items():
        if key in ("att", "val"):
            continue
        for child in value if isinstance(value, list) else [value]:
            if key == "feat":
                ET.SubElement(el, "feat", att=child["att"], val=str(child.get("val") or ""))
            else:
                el.append(json_to_element(child, key))
    return el


def iter_entries(src: Path):
    files = sorted(src.glob("*.json")) or sorted(src.glob("*.xml"))
    if not files:
        sys.exit(f"no .json or .xml files in {src}")
    for path in files:
        print(f"reading {path.name}")
        if path.suffix == ".json":
            data = json.loads(path.read_text(encoding="utf-8"))
            entries = data["LexicalResource"]["Lexicon"]["LexicalEntry"]
            for obj in entries if isinstance(entries, list) else [entries]:
                yield json_to_element(obj, "LexicalEntry")
        else:
            yield from parse_xml(path).iter("LexicalEntry")


def find_source(arg: str | None) -> Path:
    if arg:
        return Path(arg)
    official = sorted(ROOT.glob("*한국어기초사전_json*"))
    if official:
        return official[-1]
    for name in KRDICT_FILES:
        download(KRDICT_BASE + name, CACHE / "krdict" / name)
    return CACHE / "krdict"


def feats(el: ET.Element) -> dict:
    return {f.get("att"): (f.get("val") or "").strip() for f in el.findall("feat")}


def split_meanings(lemma: str) -> list[str]:
    parts = re.split(r"[;,]", lemma)
    return [p.strip() for p in parts if p.strip()]


MAX_EXAMPLES = 3
MAX_DIALOGUES = 2
MAX_DIALOGUE_LINE = 30


def pick_examples(sense: ET.Element) -> tuple[list[str], list[list[str]]]:
    """Up to 3 example sentences (short ones first) and 2 two-line mini dialogues."""
    sentences, phrases, dialogues = [], [], []
    for ex in sense.findall("SenseExample"):
        f = ex.findall("feat")
        kind = next((x.get("val") for x in f if x.get("att") == "type"), "")
        texts = [x.get("val").strip() for x in f if x.get("att") == "example"]
        if kind == "대화":
            if len(texts) == 2 and all(0 < len(t) <= MAX_DIALOGUE_LINE for t in texts):
                dialogues.append(texts)
        elif len(texts) == 1:
            (sentences if kind == "문장" else phrases).append(texts[0])
    short = sorted((s for s in sentences if len(s) <= 40), key=len)
    longer = sorted((s for s in sentences if len(s) > 40), key=len)
    examples = (short + longer)[:MAX_EXAMPLES] or sorted(phrases, key=len)[:1]
    dialogues.sort(key=lambda d: len(d[0]) + len(d[1]))
    return examples, dialogues[:MAX_DIALOGUES]


def parse_entry(entry: ET.Element, levels: set[str]) -> dict | None:
    f = feats(entry)
    level = f.get("vocabularyLevel")
    if level not in levels or f.get("lexicalUnit") != "단어":
        return None
    pos = f.get("partOfSpeech", "품사 없음")
    if pos in SKIP_POS:
        return None
    word = entry.find("Lemma/feat[@att='writtenForm']").get("val").strip()

    senses = []
    for sense in entry.findall("Sense"):
        en = next((feats(eq) for eq in sense.findall("Equivalent")
                   if feats(eq).get("language") == "영어"), None)
        if not en or not en.get("lemma"):
            continue
        examples, dialogues = pick_examples(sense)
        senses.append({
            "meanings": split_meanings(en["lemma"]),
            "definition": en.get("definition", ""),
            "example": examples[0] if examples else None,
            "examples": examples,
            "dialogues": dialogues,
        })
        if len(senses) == MAX_SENSES:
            break
    if not senses:
        return None

    origin = f.get("origin", "")
    wordform = entry.find("WordForm")
    pron = feats(wordform).get("pronunciation") if wordform is not None else None
    pos_en = POS_EN.get(pos, pos)
    category = f.get("semanticCategory") or None
    return {
        "id": int(entry.get("val")),
        "word": word,
        "homonym": int(f.get("homonym_number", "0") or 0),
        "pos": pos_en,
        "level": level,
        "hanja": origin if CJK.search(origin) else None,
        "pronunciation": pron or None,
        "category": category,
        "unit": unit_of(category, pos_en),
        "forms": conjugation_forms(entry) if word.endswith("다") else None,
        "senses": senses,
    }


def load_freq(path: Path) -> dict[str, int]:
    freq = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        token, _, count = line.rpartition(" ")
        if token:
            freq[token] = int(count)
    return freq


def frequency(word: str, freq: dict[str, int], headwords: set[str]) -> int:
    """Subtitle frequency; verbs/adjectives are matched through common inflections of the stem.

    Inflected forms that are dictionary words themselves are skipped (그리고 is "and", not 그리다).
    """
    if not word.endswith("다") or len(word) < 2:
        return freq.get(word, 0)
    stem = word[:-1]
    forms = [stem + s for s in ("다", "고", "지", "게", "면", "는", "요")]
    return max([freq.get(f, 0) for f in forms if f == word or f not in headwords] or [0])


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser()
    ap.add_argument("--levels", default="초급")
    ap.add_argument("--src")
    ap.add_argument("--out", default=str(ROOT / "assets" / "data" / "words.json"))
    args = ap.parse_args()
    levels = set(args.levels.split(","))

    src = find_source(args.src)
    download(FREQ_URL, CACHE / "ko_50k.txt")
    freq = load_freq(CACHE / "ko_50k.txt")

    words, dropped_no_en, headwords = [], 0, set()
    for entry in iter_entries(src):
        headwords.add(entry.find("Lemma/feat[@att='writtenForm']").get("val").strip())
        w = parse_entry(entry, levels)
        if w is None:
            lvl = feats(entry).get("vocabularyLevel")
            dropped_no_en += lvl in levels and not any(
                feats(eq).get("language") == "영어" for eq in entry.iter("Equivalent"))
            continue
        words.append(w)

    # Learning order: by level, then most frequent first. Homographs (이 "this" / 이 "tooth" / 이 "two")
    # share one subtitle count, so each further homograph gets half the previous one's share.
    score = {}
    by_word: dict[str, list[dict]] = {}
    for w in words:
        by_word.setdefault(w["word"], []).append(w)
    for group in by_word.values():
        base = frequency(group[0]["word"], freq, headwords)
        group.sort(key=lambda w: (-len(w["senses"]), w["homonym"]))
        for k, w in enumerate(group):
            score[w["id"]] = base / (2 ** k)
    level_rank = {"초급": 0, "중급": 1, "고급": 2}
    words.sort(key=lambda w: (level_rank.get(w["level"], 9), -score[w["id"]], w["id"]))
    for i, w in enumerate(words):
        w["rank"] = i + 1

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    version = hashlib.sha1(json.dumps(words, ensure_ascii=False).encode()).hexdigest()[:12]
    out.write_text(json.dumps({
        "version": version,
        "source": "한국어기초사전 (Basic Korean Dictionary), National Institute of Korean Language, CC BY-SA 2.0 KR",
        "words": words,
    }, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    unit_counts = Counter(w["unit"] for w in words)
    curriculum = out.parent / "curriculum.json"
    curriculum.write_text(json.dumps({
        "units": [
            {"id": uid, "title": title, "titleKo": title_ko, "emoji": emoji, "words": unit_counts[uid]}
            for uid, title, title_ko, emoji in UNITS
        ],
    }, ensure_ascii=False, indent=1), encoding="utf-8")

    print(f"wrote {len(words)} words to {out} ({out.stat().st_size / 1024:.0f} KB)")
    print(f"dropped (no English): {dropped_no_en}")
    print("by unit:", {uid: unit_counts[uid] for uid, *_ in UNITS})
    verbs = [w for w in words if w["word"].endswith("다") and w["pos"] in ("verb", "adjective")]
    senses = [s for w in words for s in w["senses"]]
    print(f"examples: {sum(len(s['examples']) for s in senses)}, mini dialogues: {sum(len(s['dialogues']) for s in senses)}")
    print(f"conjugation forms: {sum(1 for w in verbs if w['forms'])}/{len(verbs)} verbs and adjectives")
    print("forms sample:", {w["word"]: w["forms"] for w in verbs if w["word"] in
                            ("듣다", "덥다", "모르다", "공부하다", "쓰다", "되다", "오다", "있다", "만들다")})
    print("by level:", dict(Counter(w["level"] for w in words)))
    print("by pos:", dict(Counter(w["pos"] for w in words).most_common()))
    print("first 30:", " ".join(w["word"] for w in words[:30]))
    print("sample:")
    for w in random.Random(0).sample(words, 5):
        print(" ", json.dumps(w, ensure_ascii=False))


if __name__ == "__main__":
    main()
