"""Build assets/data/pictures.json: an emoji for each word that is easy to picture (Picture Pick).

Usage:
    python tools/build_pictures.py

Each entry below is (word, meaning hint, emoji). The hint picks the right homograph: it must appear
in the first sense's meanings (배 "pear" vs 배 "ship"). Without a hint the word must be unambiguous
among nouns, preferring 초급. The script fails on a missing or ambiguous word, or on an emoji used
twice, so a picture always has exactly one right answer.

Rules for the list: one word per emoji; no near-synonyms or hyponyms side by side (개 but not
강아지, 신발 but not 구두); emoji from Unicode 12 or earlier so they render on older Android.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORDS = ROOT / "assets" / "data" / "words.json"
OUT = ROOT / "assets" / "data" / "pictures.json"
VERSION = 1

PICTURES = [
    # Fruit
    ("사과", "apple", "🍎"), ("오렌지", "", "🍊"), ("바나나", "", "🍌"), ("배", "pear", "🍐"),
    ("레몬", "", "🍋"), ("딸기", "", "🍓"), ("복숭아", "", "🍑"), ("포도", "", "🍇"),
    ("망고", "", "🥭"), ("수박", "", "🍉"), ("파인애플", "", "🍍"), ("멜론", "", "🍈"),
    ("키위", "", "🥝"), ("밤", "chestnut", "🌰"),
    # Vegetables and ingredients
    ("감자", "", "🥔"), ("당근", "", "🥕"), ("토마토", "", "🍅"), ("고추", "", "🌶️"),
    ("오이", "", "🥒"), ("고구마", "", "🍠"), ("배추", "", "🥬"), ("가지", "eggplant", "🍆"),
    ("옥수수", "", "🌽"), ("버섯", "", "🍄"), ("양파", "", "🧅"), ("마늘", "", "🧄"),
    ("땅콩", "", "🥜"), ("계란", "", "🥚"), ("고기", "", "🍖"), ("소금", "", "🧂"),
    ("얼음", "", "🧊"), ("꿀", "", "🍯"), ("버터", "", "🧈"),
    # Food
    ("밥", "", "🍚"), ("빵", "", "🍞"), ("떡", "", "🍡"), ("라면", "", "🍜"),
    ("아이스크림", "", "🍦"), ("사탕", "", "🍬"), ("초콜릿", "", "🍫"), ("케이크", "", "🍰"),
    ("쿠키", "", "🍪"), ("샐러드", "", "🥗"), ("팝콘", "", "🍿"), ("버거", "", "🍔"),
    ("튀김", "", "🍤"), ("찌개", "", "🍲"), ("도넛", "", "🍩"),
    # Drinks
    ("물", "water", "💧"), ("커피", "", "☕"), ("맥주", "", "🍺"), ("우유", "", "🥛"),
    ("주스", "", "🧃"), ("콜라", "", "🥤"), ("와인", "", "🍷"),
    # Animals
    ("말", "horse", "🐴"), ("개", "dog", "🐕"), ("고양이", "", "🐱"), ("돼지", "", "🐷"),
    ("토끼", "", "🐰"), ("닭", "", "🐔"), ("소", "cow", "🐮"), ("호랑이", "", "🐯"),
    ("코끼리", "", "🐘"), ("뱀", "", "🐍"), ("물고기", "", "🐟"), ("판다", "", "🐼"),
    ("문어", "", "🐙"), ("캥거루", "", "🦘"), ("얼룩말", "", "🦓"), ("곰", "", "🐻"),
    ("원숭이", "", "🐵"), ("사자", "lion", "🦁"), ("개구리", "", "🐸"), ("거북", "", "🐢"),
    ("양", "sheep", "🐑"), ("쥐", "mouse", "🐭"), ("오리", "", "🦆"), ("나비", "butterfly", "🦋"),
    ("벌", "bee", "🐝"), ("모기", "", "🦟"), ("거미", "", "🕷️"), ("개미", "", "🐜"),
    ("고래", "", "🐳"), ("새우", "", "🦐"), ("게", "crab", "🦀"), ("오징어", "", "🦑"),
    ("독수리", "", "🦅"), ("공룡", "", "🦕"), ("용", "dragon", "🐉"), ("앵무새", "", "🦜"),
    ("돌고래", "", "🐬"), ("달팽이", "", "🐌"), ("무당벌레", "", "🐞"),
    # Body
    ("이", "tooth", "🦷"), ("손", "hand", "✋"), ("눈", "eye", "👁️"), ("입", "mouth", "👄"),
    ("다리", "leg", "🦵"), ("발", "foot", "🦶"), ("팔", "arm", "💪"), ("코", "nose", "👃"),
    ("귀", "ear", "👂"), ("혀", "", "👅"),
    # Clothes and things you wear
    ("신발", "", "👟"), ("양말", "", "🧦"), ("티셔츠", "", "👕"), ("바지", "", "👖"),
    ("원피스", "", "👗"), ("수영복", "", "👙"), ("모자", "", "🧢"), ("넥타이", "", "👔"),
    ("안경", "", "👓"), ("장갑", "", "🧤"), ("목도리", "", "🧣"), ("반지", "", "💍"),
    ("우산", "", "☂️"), ("지갑", "", "👛"), ("가방", "", "🎒"),
    # Around the house
    ("카메라", "", "📷"), ("열쇠", "", "🔑"), ("침대", "", "🛏️"), ("컴퓨터", "", "🖥️"),
    ("라디오", "", "📻"), ("시계", "", "⏰"), ("의자", "", "🪑"), ("소파", "", "🛋️"),
    ("휴지", "", "🧻"), ("비누", "", "🧼"), ("텔레비전", "", "📺"), ("달력", "", "📅"),
    ("촛불", "", "🕯️"), ("쓰레기통", "", "🗑️"), ("휴대폰", "", "📱"), ("문", "door", "🚪"),
    ("화장실", "", "🚽"), ("상자", "", "📦"), ("숟가락", "", "🥄"), ("젓가락", "", "🥢"),
    ("칼", "knife", "🔪"), ("접시", "", "🍽️"), ("병", "bottle", "🍾"), ("약", "medicine", "💊"),
    # School and stationery
    ("책", "", "📚"), ("연필", "", "✏️"), ("펜", "", "🖊️"), ("가위", "scissors", "✂️"),
    ("지도", "map", "🗺️"), ("종이", "", "📄"), ("편지", "", "✉️"),
    # Free time
    ("축구", "", "⚽"), ("야구", "", "⚾"), ("농구", "", "🏀"), ("테니스", "", "🎾"),
    ("탁구", "", "🏓"), ("배드민턴", "", "🏸"), ("수영", "", "🏊"), ("스키", "", "🎿"),
    ("낚시", "", "🎣"), ("게임", "", "🎮"), ("인형", "", "🧸"), ("피아노", "", "🎹"),
    ("기타", "guitar", "🎸"), ("바이올린", "", "🎻"), ("드럼", "", "🥁"), ("노래", "", "🎵"),
    ("영화", "", "🎬"), ("그림", "", "🖼️"), ("선물", "", "🎁"), ("풍선", "", "🎈"),
    ("텐트", "", "⛺"), ("메달", "", "🏅"), ("표", "ticket", "🎫"), ("연", "kite", "🪁"),
    # Getting around
    ("비행기", "", "✈️"), ("자동차", "", "🚗"), ("트럭", "", "🚚"), ("버스", "", "🚌"),
    ("자전거", "", "🚲"), ("배", "ship", "🚢"), ("기차", "", "🚆"), ("지하철", "", "🚇"),
    ("오토바이", "", "🏍️"), ("신호등", "", "🚦"), ("로켓", "", "🚀"),
    # Places
    ("집", "", "🏠"), ("학교", "", "🏫"), ("병원", "", "🏥"), ("은행", "", "🏦"),
    ("우체국", "", "🏣"), ("교회", "", "⛪"), ("호텔", "", "🏨"), ("산", "mountain", "⛰️"),
    ("바다", "", "🌊"), ("섬", "island", "🏝️"), ("사막", "", "🏜️"), ("성", "castle", "🏰"),
    ("공장", "", "🏭"),
    # Nature and weather
    ("해", "sun", "☀️"), ("달", "moon", "🌙"), ("별", "star", "⭐"), ("구름", "", "☁️"),
    ("비", "rain", "🌧️"), ("눈", "snow", "❄️"), ("바람", "wind", "🌬️"), ("무지개", "", "🌈"),
    ("번개", "", "⚡"), ("눈사람", "", "⛄"), ("태풍", "", "🌀"), ("불", "fire", "🔥"),
    ("꽃", "", "🌸"), ("나무", "", "🌳"), ("선인장", "", "🌵"), ("지구", "", "🌍"),
    ("단풍", "", "🍁"),
    # People
    ("아기", "", "👶"), ("할아버지", "", "👴"), ("할머니", "", "👵"), ("경찰", "", "👮"),
    ("요리사", "", "👨‍🍳"), ("의사", "doctor", "👨‍⚕️"), ("학생", "", "👨‍🎓"), ("선생님", "", "👩‍🏫"),
    ("왕", "king", "👑"), ("천사", "", "👼"), ("유령", "", "👻"), ("소방관", "", "👨‍🚒"),
    ("농부", "", "👨‍🌾"),
    # Feelings and the body's doings
    ("사랑", "", "❤️"), ("눈물", "", "😢"), ("웃음", "", "😄"), ("잠", "", "😴"),
    ("감기", "", "🤧"),
    # Money
    ("돈", "", "💵"), ("카드", "", "💳"),
    # Colours
    ("빨간색", "", "🔴"), ("파란색", "", "🔵"), ("초록색", "", "🟢"), ("노란색", "", "🟡"),
    ("검은색", "", "⚫"), ("흰색", "", "⚪"), ("보라색", "", "🟣"), ("주황색", "", "🟠"),
    ("갈색", "", "🟤"),
]


def resolve(by_word, word, hint):
    candidates = [w for w in by_word.get(word, []) if w["pos"] == "noun"]
    if hint:
        candidates = [w for w in candidates if any(hint in m for m in w["senses"][0]["meanings"])]
    if len(candidates) > 1:
        beginner = [w for w in candidates if w["level"] == "초급"]
        if len(beginner) == 1:
            candidates = beginner
    if len(candidates) != 1:
        found = [(w["id"], w["level"], w["senses"][0]["meanings"][:2]) for w in by_word.get(word, [])]
        raise SystemExit(f"{word} ({hint or 'no hint'}): {len(candidates)} matches among {found}")
    return candidates[0]


def main():
    words = json.loads(WORDS.read_text(encoding="utf-8"))["words"]
    by_word = {}
    for w in words:
        by_word.setdefault(w["word"], []).append(w)

    seen_emoji, seen_ids, out = {}, set(), []
    for word, hint, emoji in PICTURES:
        if emoji in seen_emoji:
            raise SystemExit(f"{emoji} is used for both {seen_emoji[emoji]} and {word}")
        seen_emoji[emoji] = word
        w = resolve(by_word, word, hint)
        if w["id"] in seen_ids:
            raise SystemExit(f"{word} is listed twice")
        seen_ids.add(w["id"])
        out.append(({"id": w["id"], "word": w["word"], "emoji": emoji}, w["level"]))

    rows = ",\n".join(json.dumps(p, ensure_ascii=False) for p, _ in out)
    OUT.write_text(f'{{"version": {VERSION}, "pictures": [\n{rows}\n]}}\n', encoding="utf-8")
    beginner = sum(1 for _, level in out if level == "초급")
    print(f"{len(out)} pictures ({beginner} 초급) -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    sys.exit(main())
