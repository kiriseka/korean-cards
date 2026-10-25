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


def pick_example(sense: ET.Element) -> str | None:
    sentences, phrases = [], []
    for ex in sense.findall("SenseExample"):
        f = ex.findall("feat")
        kind = next((x.get("val") for x in f if x.get("att") == "type"), "")
        texts = [x.get("val").strip() for x in f if x.get("att") == "example"]
        if len(texts) != 1:  # dialogues have two lines
            continue
        (sentences if kind == "문장" else phrases).append(texts[0])
    pool = [s for s in sentences if len(s) <= 40] or sentences or phrases
    return min(pool, key=len) if pool else None


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
        senses.append({
            "meanings": split_meanings(en["lemma"]),
            "definition": en.get("definition", ""),
            "example": pick_example(sense),
        })
        if len(senses) == MAX_SENSES:
            break
    if not senses:
        return None

    origin = f.get("origin", "")
    wordform = entry.find("WordForm")
    pron = feats(wordform).get("pronunciation") if wordform is not None else None
    return {
        "id": int(entry.get("val")),
        "word": word,
        "homonym": int(f.get("homonym_number", "0") or 0),
        "pos": POS_EN.get(pos, pos),
        "level": level,
        "hanja": origin if CJK.search(origin) else None,
        "pronunciation": pron or None,
        "category": f.get("semanticCategory") or None,
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

    print(f"wrote {len(words)} words to {out} ({out.stat().st_size / 1024:.0f} KB)")
    print(f"dropped (no English): {dropped_no_en}")
    print("by level:", dict(Counter(w["level"] for w in words)))
    print("by pos:", dict(Counter(w["pos"] for w in words).most_common()))
    print("first 30:", " ".join(w["word"] for w in words[:30]))
    print("sample:")
    for w in random.Random(0).sample(words, 5):
        print(" ", json.dumps(w, ensure_ascii=False))


if __name__ == "__main__":
    main()
