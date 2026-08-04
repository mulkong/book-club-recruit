#!/usr/bin/env python3
"""내부 index.html → 공개 배포용 index.html 생성기.

이 파일은 GitHub 레포에 커밋하지 않습니다. 마스킹 규칙 자체가 무엇을 감췄는지
드러내기 때문입니다. (레포에는 산출물만 올라갑니다.)

사용법:
    cd ~/Desktop/naver-bookclub
    python3 build_public.py

수정 흐름:
    이 폴더의 index.html 을 고친다 → build_public.py 실행 → 레포에서 커밋·푸시
"""
import os
import re
import sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "index.html")
OUT_DIR = os.path.expanduser("~/Desktop/book-club-recruit")
OUT = os.path.join(OUT_DIR, "index.html")

# ── 마스킹 규칙 ────────────────────────────────────────────────
# (찾을 문자열, 바꿀 문자열, 최소 등장 횟수)
REPLACEMENTS = [
    # 사내 공간 정보
    ("<h3>1784에서</h3>", "<h3>사내 공간에서</h3>", 1),
    ("1784 5층 또는 2층 파트너스룸, 각 층 큰 미팅룸을 사용합니다. 클럽별 확정 장소는 조율 중입니다.",
     "사내 미팅룸에서 모입니다. 클럽별 확정 장소는 조율 중입니다.", 1),
    ('venue:         "1784 (층·룸 조율 중)"', 'venue:         "사내 미팅룸 (조율 중)"', 1),
    ('place:    "파트너스룸 or 각 층 큰 미팅룸"', 'place:    "사내 미팅룸 (조율 중)"', 1),
    ('"모임 장소 — 1784 5층 / 2층 파트너스룸 / 식사 장소"',
     '"모임 장소 — 사내 미팅룸 / 식사 장소"', 1),
    ('note:"점심시간 · 1784"', 'note:"점심시간 · 사내"', 1),

    # 사내 시스템 이름
    ("<strong>Works 드라이브에 참석 O/X를 체크</strong>",
     "<strong>운영 시트에 참석 O/X를 체크</strong>", 1),
    ("매 모임 시작 시 Works 드라이브에 참석 O/X를 체크하며",
     "매 모임 시작 시 운영 시트에 참석 O/X를 체크하며", 1),

    # 회사명·로고형 마크 — 공개 페이지가 공식 페이지로 오인되지 않도록
    ("<title>독서 스터디 4기 모집 | NAVER</title>",
     "<title>독서 스터디 4기 모집</title>", 1),
    ("   NAVER 독서 스터디 4기 모집 페이지", "   독서 스터디 4기 모집 페이지", 1),
    ("  /* NAVER Green — 브랜드 아이덴티티 */", "  /* Primary green */", 1),
    ('<span class="brand-mark" aria-hidden="true">N</span>',
     '<span class="brand-mark" aria-hidden="true">\U0001F4D6</span>', 1),
]

# 텔러 프로필 사진은 공개 빌드에도 그대로 포함합니다 (사용자 결정).
# 사진을 다시 빼고 이니셜 아바타로 돌리려면 아래를 True 로 바꾸세요.
STRIP_PHOTOS = False
PHOTO_RE = re.compile(r'("(?:신동걸|정지혜|강민구|백송이)":\s*)"data:image/jpeg;base64,[^"]+"')

# ── 산출물에 남아 있으면 안 되는 것들 ─────────────────────────
FORBIDDEN = [
    "1784",                     # 사옥
    "Works 드라이브",            # 사내 시스템
    "파트너스룸",
    "NAVER",
]


def check_supabase_key(out):
    """SUPABASE.key 에 anon(공개) 키가 아닌 관리자 키가 들어가지 않았는지 확인.

    단어 'service_role' 을 그냥 검색하면 '넣지 마세요' 라고 적은 주석까지 걸리므로,
    실제 키 값을 열어본다. JWT 형식이면 payload 의 role 을, 신형 키면 접두어를 본다.
    """
    m = re.search(r'\bkey:\s*"([^"]*)"', out)
    if not m or not m.group(1):
        return []                                   # 아직 미설정 — 정상
    key = m.group(1)

    if key.startswith("sb_secret_") or key.startswith("sbp_"):
        return ["SUPABASE.key 가 비밀 키입니다. anon/publishable 키를 쓰세요."]
    if key.startswith("sb_publishable_"):
        return []

    parts = key.split(".")
    if len(parts) == 3:                             # JWT
        import base64
        import json
        pad = parts[1] + "=" * (-len(parts[1]) % 4)
        try:
            role = json.loads(base64.urlsafe_b64decode(pad)).get("role")
        except Exception:
            return ["SUPABASE.key 를 해석할 수 없습니다. 값을 다시 확인하세요."]
        if role != "anon":
            return [f"SUPABASE.key 의 role 이 '{role}' 입니다. anon 키만 페이지에 넣을 수 있습니다."]
        return []

    return ["SUPABASE.key 형식을 알 수 없습니다. Settings > API 의 anon public key 를 넣으세요."]


def main():
    src = open(SRC, encoding="utf-8").read()
    out = src
    problems = []

    for find, repl, least in REPLACEMENTS:
        n = out.count(find)
        if n < least:
            problems.append(f"치환 대상을 찾지 못했습니다 ({n}건): {find[:60]}")
            continue
        out = out.replace(find, repl)

    n_photo = len(PHOTO_RE.findall(out))
    if n_photo != 4:
        problems.append(f"사진이 4건이어야 하는데 {n_photo}건입니다. 내부 index.html 을 확인하세요.")
    if STRIP_PHOTOS:
        out = PHOTO_RE.sub(r'\1""', out)

    if problems:
        print("빌드 실패 — 내부 index.html 이 바뀐 것 같습니다:", file=sys.stderr)
        for p in problems:
            print("  ✗ " + p, file=sys.stderr)
        return 1

    # 검증: 금지 문자열
    leaks = [f for f in FORBIDDEN if f in out]
    if leaks:
        print("빌드 실패 — 공개 빌드에 남아 있으면 안 되는 문자열:", file=sys.stderr)
        for f in leaks:
            print(f"  ✗ {f} ({out.count(f)}건)", file=sys.stderr)
        return 1

    # 검증: 관리자 키 오입력 방지
    key_problems = check_supabase_key(out)
    if key_problems:
        print("빌드 실패 — Supabase 키 문제:", file=sys.stderr)
        for p in key_problems:
            print("  ✗ " + p, file=sys.stderr)
        return 1

    os.makedirs(OUT_DIR, exist_ok=True)
    open(OUT, "w", encoding="utf-8").write(out)

    print(f"공개 빌드 생성: {OUT}")
    print(f"  치환 {len(REPLACEMENTS)}건"
          + (f" + 사진 제거 {n_photo}건" if STRIP_PHOTOS else f" · 사진 {n_photo}장 포함"))
    print(f"  크기 {len(src.encode()) // 1024}KB → {len(out.encode()) // 1024}KB")
    print(f"  금지 문자열 {len(FORBIDDEN)}종 모두 0건 확인")
    return 0


if __name__ == "__main__":
    sys.exit(main())
