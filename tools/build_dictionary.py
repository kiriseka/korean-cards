"""Build the offline dictionary (assets/data/dictionary.json.gz) from the KRDict dump.

Every entry with an English translation, compact: word, part of speech, level, hanja,
pronunciation, up to 3 senses (English words + a short definition), one example and the
conjugation forms of verbs/adjectives (used to look up conjugated words).

Usage: python tools/build_dictionary.py [--src <folder of KRDict .json/.xml>]
Data: 국립국어원 한국어기초사전, CC BY-SA 2.0 KR.
"""

import argparse
import gzip
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_words as bw  # noqa: E402  (shares the dump reader and field parsers)

OUT = bw.ROOT / "assets" / "data" / "dictionary.json.gz"
MAX_DEF = 90
PHRASE_ID_OFFSET = 50_000_000


def entry(e) -> dict | None:
    f = bw.feats(e)
    if f.get("lexicalUnit") not in ("단어", "구", "관용구"):
        return None
    lemma = e.find("Lemma/feat[@att='writtenForm']")
    if lemma is None:
        return None
    word = lemma.get("val").strip()
    senses = []
    example = None
    for sense in e.findall("Sense"):
        en = next((bw.feats(q) for q in sense.findall("Equivalent") if bw.feats(q).get("language") == "영어"), None)
        if not en or not en.get("lemma"):
            continue
        d = en.get("definition", "").strip()
        senses.append({"m": bw.split_meanings(en["lemma"]), "d": d if len(d) <= MAX_DEF else d[: MAX_DEF - 1].rstrip() + "…"})
        if example is None:
            examples, _ = bw.pick_examples(sense)
            example = examples[0] if examples else None
        if len(senses) == 3:
            break
    if not senses:
        return None
    pos = bw.POS_EN.get(f.get("partOfSpeech", "품사 없음"), f.get("partOfSpeech", ""))
    wordform = e.find("WordForm")
    pron = bw.feats(wordform).get("pronunciation") if wordform is not None else None
    origin = f.get("origin", "")
    out = {
        "i": int(e.get("val")),
        "w": word,
        "p": pos if f.get("lexicalUnit") == "단어" else "phrase",
        "l": f.get("vocabularyLevel") or "",
        "s": senses,
    }
    if bw.CJK.search(origin):
        out["h"] = origin
    if pron and pron.replace("ː", "") != word:
        out["r"] = pron
    if example:
        out["e"] = example
    if word.endswith("다") and pos in ("verb", "adjective", "auxiliary verb", "auxiliary adjective"):
        forms = bw.conjugation_forms(e)
        if forms:
            out["f"] = {k: v for k, v in forms.items() if k in ("a", "euni")}
    return out


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser()
    ap.add_argument("--src")
    args = ap.parse_args()
    entries = [x for e in bw.iter_entries(bw.find_source(args.src)) if (x := entry(e))]
    # Set phrases (구/관용구) reuse their head word's KRDict id (침을 뱉다, 침이 마르다…):
    # give them their own sequential ids above every word id.
    phrases = sorted((x for x in entries if x["p"] == "phrase"), key=lambda x: (x["i"], x["w"]))
    for n, x in enumerate(phrases):
        x["i"] = PHRASE_ID_OFFSET + n
    entries.sort(key=lambda x: x["i"])
    ids = [x["i"] for x in entries]
    assert len(ids) == len(set(ids)), "duplicate dictionary ids"
    raw = json.dumps(entries, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    OUT.write_bytes(gzip.compress(raw, 9))
    print(f"{len(entries)} entries, {len(raw) / 1e6:.1f} MB json → {OUT.stat().st_size / 1e6:.1f} MB gzip")
    print("by level:", dict(Counter(x["l"] or "-" for x in entries)))
    print("with forms:", sum(1 for x in entries if "f" in x))


if __name__ == "__main__":
    main()
