# CLAUDE.md

독서 스터디 4기 모집 페이지. Claude Code 로 작업할 때 먼저 읽는 문서입니다.

> **이 레포는 공개되어 있습니다.** GitHub Pages 로 서빙하기 위해 public 이며,
> `raw.githubusercontent.com` 으로 모든 파일을 누구나 내려받을 수 있습니다.
> 커밋한 것은 히스토리에 영구히 남아, 파일을 지워도 SHA 를 아는 사람은 계속
> 접근할 수 있습니다.
>
> 사내 시스템 이름·경로는 이 문서에 적기로 했습니다(운영 편의 우선). 다만
> **운영진 코드와 비밀 키는 값을 적지 않습니다.** 그것들은 사내 정보가 아니라
> 접근 자격증명이고, 공개되면 신청자 본인이 아닌 제3자의 개인정보가 열립니다.

---

## 무엇인가

사내 독서 스터디 4기 멤버를 모집하는 한 장짜리 정적 페이지입니다. 4개 클럽을
소개하고 클럽별 신청을 받으며, 정원이 차면 대기 순번을 부여합니다.

- **배포 주소** https://mulkong.github.io/book-club-recruit/
- **현황 대시보드** https://pages.navercorp.com/protein-harness/bookclub-status/
- **모집 기간** 2026-08-07 (금) 10:00 ~ 2026-08-12 (수) 18:00 KST
- **정원** 클럽당 10명 · 4개 클럽 · 총 40석
- **지원 항목** 식사 + 음료 + 도서 (클럽 회비)

### 클럽 4개

| 텔러 | 테마 | 키워드 | 첫 도서 | 모임 |
|---|---|---|---|---|
| 신동걸 | 투자 A to Z, 편향 없이 다 읽기 | 주식 · 부동산 · 폭넓게 | 송희구 \| 나의 첫 번째 부동산 교과서 | 점심 · 수요일 |
| 정지혜 | 바빠도 1권은 제대로 읽자 | 연금 · 자산배분 · 완독 | 박곰희 \| 박곰희의 연금부자수업 | 점심 · 1·3주차 수요일 |
| 강민구 | 멘탈을 지키는 주식 투자 | 멘탈 · 확률론적 사고 · AI 투자 | 홍진채 \| 주식하는 마음 | 점심 · 목요일 |
| 백송이 | 정답보다 길목을 보는 시야 | — | 오건영 \| 부의 갈림길 | 점심 · 월·수·금 중 (변동) |

전 클럽 공통: 모임 주기 격주 · 도서 1달 1권 · 정원 10명.
클럽마다 테마가 겹치지 않게 구성했으므로 한 곳을 골라 신청하는 것이 기본입니다.

### 운영 규칙 (페이지에 명시된 내용)

- 결원이 생기면 **대기자 명단 순번대로** 충원합니다. 정원이 찬 클럽도 대기
  신청을 받습니다.
- 매 모임 참석 O/X 를 운영 시트에 기록합니다.
- 신청 후 수정은 어렵고, 문의는 운영진에게 받습니다.
- 아직 조율 중인 항목은 `PENDING` 배열에 있고 페이지 하단에 목록으로 표시됩니다.

## 구성

| 파일 | 설명 |
|---|---|
| `index.html` | 페이지 전체. CSS·JS·이미지가 전부 인라인된 자체 완결형 단일 파일 |
| `supabase_setup.sql` | `applications` 테이블 · 접근 제어 (1차) |
| `supabase_dashboard.sql` | 이메일 도메인 제한 해제 · `app_stats()` · `app_list()` (2차) |
| `supabase_waitlist.sql` | `apply()` — 대기 순번 부여 · 서버 측 접수 창 검증 (3차) |
| `supabase_capacity.sql` | `app_stats()` 에 정원·접수 창 포함 (4차) |
| `.nojekyll` | GitHub Pages 의 Jekyll 전처리 비활성화 |
| `robots.txt` | 검색엔진 크롤링 차단 (직접 접근은 막지 않음) |

외부 라이브러리·CDN·웹폰트 의존이 없습니다. `index.html` 하나만 열어도 동작합니다.

---

## 개발

### 페이지 수정

`index.html` 하단 `<script>` 의 상수만 고치면 페이지 전체가 갱신됩니다.

```js
const CONFIG   = { ... }   // 모집 기간, 장소, 문의처, 오픈·마감 시각
const SUPABASE = { ... }   // Project URL, anon key
const CLUBS    = [ ... ]   // 클럽 4개 (텔러, 테마, 첫 도서, 요일, 정원)
const PENDING  = [ ... ]   // 조율 중인 항목
const FAQS     = [ ... ]   // 자주 묻는 질문
```

확정되지 않은 값은 `TBD` 상수를 쓰면 "추후 공지" 배지로 표시됩니다.

### 페이지가 그려지는 순서

`index.html` 은 마크업이 거의 비어 있고, 하단 스크립트가 상수를 읽어 DOM 을
채웁니다. 어디를 고쳐야 하는지 찾을 때 이 순서를 보세요.

| 함수 / 위치 | 그리는 것 |
|---|---|
| `CONFIG`, `CLUBS`, `PHOTOS`, `COVERS` | 데이터 (이 위에 아무것도 그리지 않음) |
| `applyState()` / `msToNextTransition()` | 접수 상태 판정 (`before` / `open` / `closed`) |
| 클럽 카드 렌더 | 텔러·테마·키워드·도서 카드·정원·장소·신청 버튼·상세 패널 |
| `paintApplyState()` | 모든 신청 버튼·히어로 배지의 라벨과 잠금/마감 상태 |
| `paintSeats()` | 카드의 정원 표시를 실시간 인원으로 (`2 / 10명 · 8자리 남음`) |
| `paintWaitBanner()` | 모달 상단 대기자 안내 배너 |
| `refreshStats()` | `app_stats()` 호출 → 시계 보정 + `SEATS` 갱신 → 위 셋 다시 그림 |
| `openApply()` / `resetForm()` / `validate()` | 신청 모달 |
| `postSupabase()` / submit 핸들러 | 전송 (타임아웃·재시도·`apply()` 호출) |
| `showDone(p, seat)` | 완료 화면 (`seat` 가 있으면 대기 순번 표시) |
| `renderKpi` 등 (대시보드) | 별도 파일 — 아래 배포 절 참고 |

**전역 상태는 세 개뿐입니다.**

```js
let CLOCK_SKEW = 0;     // 서버시각 - 기기시각 (ms)
let SEATS = null;       // { "신동걸": 2, ... } — null 이면 아직 모름
const READY = ...       // SUPABASE 설정 여부
```

### 오픈·마감 시각

`CONFIG.applyOpensAt` / `applyClosesAt` 한 쌍으로 버튼 잠금과 모집 기간 표기가
모두 결정됩니다.

| 값 | 동작 |
|---|---|
| `""` | 잠김. 회색 버튼 + "신청 오픈 준비 중" |
| `"2026-08-07T10:00:00+09:00"` | 그 시각까지 잠기고, 되면 새로고침 없이 열림 |
| `"open"` | 즉시 오픈 |
| 잘못된 형식 | 안전하게 잠김 처리 |

`+09:00` 오프셋이 명시돼 있어 접속자 타임존과 무관하게 KST 기준으로 동작합니다.

**주의 — 이 값은 화면 표시용입니다.** 실제 접수 허용 여부는 DB 의
`private.settings.apply_opens_at` / `apply_closes_at` 로 서버가 판정합니다.
테스트로 페이지만 열어도 서버가 거부하므로, **두 값을 항상 같이 바꾸세요.**

### 문법 검사

Node 없이 확인하려면 macOS 내장 JavaScriptCore 를 씁니다.

```bash
python3 -c "
import re
s=open('index.html',encoding='utf-8').read()
m=re.findall(r'<script>(.*?)</script>', s, re.S)[-1]
open('/tmp/chk.js','w',encoding='utf-8').write('(function(){\n'+m+'\n});\nprint(\"PARSE OK\");\n')
"
/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc /tmp/chk.js
```

파싱만 확인합니다. **TDZ(`let`/`const` 선언 순서) 오류는 잡히지 않습니다.**
`let` 로 선언한 값을 그보다 앞줄에서 호출되는 함수가 읽으면 페이지 로드가
`ReferenceError` 로 죽습니다. `SEATS` 를 파일 앞쪽에 둔 이유가 이것입니다.
`paintApplyState` 가 `isClubFull` → `SEATS` 를 읽고, 그 호출이 선언보다 앞에
있었습니다. 선언 위치를 옮길 때는 호출 순서를 함께 확인하세요.

`function` 선언은 호이스팅되므로 위치가 자유롭습니다. `reqSignal` 이 파일
뒤쪽에 있으면서 앞쪽 `refreshStats` 에서 호출되는 것이 그래서 괜찮습니다.

### 이미지 (프로필 사진 · 도서 표지)

전부 base64 로 인라인합니다. 외부 의존 없이 파일 하나로 동작하는 것이 이
페이지의 전제이기 때문입니다.

```js
const PHOTOS = { "신동걸": "data:image/jpeg;base64,...", ... }   // 160x160 q82
const COVERS = { "나의 첫 번째 부동산 교과서": "data:image/jpeg;base64,...", ... }
```

`build_public.py` 는 `PHOTOS` 가 정확히 4장인지 검사하고, 아니면 빌드를
중단합니다. 사진을 늘리거나 줄이면 그 검사도 같이 고쳐야 합니다.

**도서 표지 받는 법 — 상품ID 경로에 함정이 있습니다.**

```
❌ https://contents.kyobobook.co.kr/sih/fit-in/458x0/pdt/S000220119415.jpg
   → HTTP 200 + content-type: image/jpeg 로 응답하지만
     "제공된 상품이미지가 없습니다" 플레이스홀더입니다.
     4권 모두 같은 파일이 오므로 md5 를 비교하면 바로 드러납니다.

✅ https://contents.kyobobook.co.kr/sih/fit-in/458x0/pdt/<ISBN13>.jpg
```

현재 쓰는 ISBN:

| 도서 | ISBN13 | 교보 상품ID |
|---|---|---|
| 나의 첫 번째 부동산 교과서 | 9791193904435 | S000220119415 |
| 박곰희의 연금부자수업 | 9791168342941 | S000216900602 |
| 주식하는 마음 | 9791130632032 | S000001687015 |
| 부의 갈림길 | 9791124591048 | S000220119843 |

교보문고 상세 페이지는 스크래핑이 막혀 있습니다(빈 응답). 저자명·ISBN 은
검색으로 찾고, **받은 표지를 눈으로 확인**하세요. 표지에 저자명이 적혀 있어
교차 검증이 됩니다.

가공 (macOS 내장 `sips`, 카드 표시 크기 52x76 의 2배 이상):

```bash
curl -s -o cover.jpg -A "Mozilla/5.0" \
  "https://contents.kyobobook.co.kr/sih/fit-in/458x0/pdt/<ISBN>.jpg"
sips -Z 200 cover.jpg --setProperty format jpeg --setProperty formatOptions 68
python3 -c "import base64;print('data:image/jpeg;base64,'+base64.b64encode(open('cover.jpg','rb').read()).decode())"
```

4장 합계 96KB, 페이지 전체 215KB 입니다. 더 키우면 첫 로딩이 느려집니다.

> 표지는 출판사 이미지를 복사해 공개 페이지에 재배포하는 형태입니다. 사내
> 독서모임 페이지에서는 흔한 관행이지만, 이 레포가 공개라는 점은 인지하고
> 쓰기로 했습니다. 부담되면 표지를 빼고 `저자명 | 도서명` 링크만 남기면 됩니다.

---

## 자주 하는 작업

### 정원 바꾸기

두 곳입니다. **DB 가 판정 기준이므로 DB 를 반드시 고쳐야 합니다.**

```sql
update private.settings set value = '12' where key = 'club_capacity';   -- 판정
```
```js
capacity: 12,   // index.html CLUBS[] 4곳 — 카드 표시용
```

대시보드는 `app_stats().capacity` 를 읽으므로 고칠 곳이 없습니다.

### 오픈·마감 시각 바꾸기

```sql
update private.settings set value = '2026-08-07T10:00:00+09:00' where key = 'apply_opens_at';
update private.settings set value = '2026-08-12T18:00:00+09:00' where key = 'apply_closes_at';
```
```js
applyOpensAt:  "2026-08-07T10:00:00+09:00",   // index.html CONFIG — 표시용
applyClosesAt: "2026-08-12T18:00:00+09:00",
```

### 테스트로 미리 열어보기

페이지만 열면 서버가 `not_open` 으로 거부합니다. 둘 다 바꿔야 합니다.

```sql
update private.settings set value = '2000-01-01T00:00:00+09:00' where key = 'apply_opens_at';
```
```js
applyOpensAt:  "open",
```

**끝나면 원복하고, 테스트 데이터도 지우세요.** 라이브 페이지가 열린 상태로
남으면 공지 전에 아무나 신청할 수 있습니다.

### 도서 교체

`CLUBS[].book` / `author` / `bookUrl` / `cover` 네 개를 같이 고칩니다.
`COVERS` 키는 `book` 값과 일치해야 합니다 (`cover: COVERS["<book>"]`).

### 클럽 정보 · FAQ · 조율 중 항목

`CLUBS` / `FAQS` / `PENDING` 배열만 고치면 됩니다. 마크업은 건드릴 필요 없습니다.

---

## 작업 폴더 두 개

**원본은 이 레포가 아닙니다.** 사내 정보가 담긴 내부 소스를 마스킹해서
공개본을 만드는 구조입니다.

```
~/Desktop/naver-bookclub/        내부 소스 (원본) — git 아님
  index.html                     ← 여기를 고칩니다
  build_public.py                ← 마스킹 빌드 스크립트
  supabase_*.sql

~/Desktop/book-club-recruit/     공개 레포 (산출물) — git, GitHub Pages
  index.html                     ← build_public.py 가 생성. 직접 고치지 마세요
```

수정 흐름:

```bash
# 1. 내부 소스를 고친다
vi ~/Desktop/naver-bookclub/index.html

# 2. 공개본 생성 (마스킹 + 검증)
cd ~/Desktop/naver-bookclub && python3 build_public.py

# 3. 공개 레포에서 커밋·푸시
cd ~/Desktop/book-club-recruit && git add -A && git commit && git push
```

`build_public.py` 는 치환에 실패하거나 금지 문자열이 남으면 **빌드를 중단**합니다.
사옥명·사내 시스템 이름·회사명을 일반 표현으로 바꾸고, `SUPABASE.key` 가
비밀 키(`sb_secret_`, `sbp_`, role ≠ anon)면 거부합니다.

공개 레포의 `index.html` 을 직접 고치면 다음 빌드에서 덮어써집니다.

---

## 배포

### 신청 페이지 — GitHub Pages

`main` 브랜치에 푸시하면 자동 반영합니다.
(Settings → Pages → Source: `main` / `/ (root)`)

반영까지 30초~2분 걸리고, `cache-control` 때문에 브라우저는 강제 새로고침
(⌘⇧R) 이 필요합니다. 반영 확인:

```bash
curl -s "https://mulkong.github.io/book-club-recruit/index.html" | grep -c "찾을문자열"
```

### 현황 대시보드 — Naver Pages

운영진용 신청 현황 대시보드는 별도 폴더에서 별도 시스템으로 배포합니다.

```
소스   ~/Desktop/bookclub-dashboard/index.html   (단일 파일, git 아님)
주소   https://pages.navercorp.com/protein-harness/bookclub-status/
```

```bash
export PATH="$HOME/.local/bin:$PATH"

naver-pages whoami        # 세션 확인
naver-pages login         # 만료 시 (브라우저 SSO — 대화형이라 사람이 실행해야 함)

naver-pages deploy ~/Desktop/bookclub-dashboard \
  --workspace protein-harness --site bookclub-status
```

`cache-control: public, max-age=60` 이라 배포 직후에도 브라우저 캐시가 남습니다.
서버 반영 확인은 캐시를 우회해서:

```bash
curl -s -H "Cache-Control: no-cache" \
  "https://pages.navercorp.com/protein-harness/bookclub-status/?cb=$(date +%s)" \
  | grep -c "찾을문자열"
```

대시보드가 하는 일:

- 20초마다 `app_stats()` 호출 — 총 신청·확정·대기·남은 자리, 클럽별 미터,
  일자별 추이, 소속 분포, **클럽별 대기자** (여기까지 코드 불필요)
- 운영진 코드를 입력하면 `app_list(code)` 로 전체 명단. 클럽별 그룹 머리글과
  `전체 / 확정 대상 / 대기자` 필터, 필터 상태 그대로 CSV 내려받기
- 정원은 `app_stats().capacity` 에서 읽습니다. 하드코딩하지 마세요

---

## 신청 데이터

Supabase(Postgres) 의 `public.applications` 테이블에 적재됩니다.
페이지의 키는 **anon(공개) 키**로, 브라우저에 노출되는 것이 정상입니다.
접근 제어는 DB 권한과 함수가 담당합니다.

```
저장  →  public.apply()  를 통해서만. 테이블 직접 INSERT 는 권한 회수됨
읽기  →  anon 에게 SELECT 권한 없음
중복  →  (lower(email), club) unique — 같은 클럽 중복 신청 불가
이메일 →  형식만 검사. 도메인 제한 없음
```

### 정원과 대기 순번

`apply()` 하나가 **접수 창 검증 · INSERT · 순번 계산을 한 트랜잭션에서** 처리합니다.
동시에 몰려도 순번이 겹치지 않는 이유는 두 줄입니다.

```sql
perform pg_advisory_xact_lock(4218, hashtext(p_club));   -- 같은 클럽 신청을 직렬화
insert into ... (created_at, ...) values (clock_timestamp(), ...);
```

`now()` 를 쓰면 안 됩니다. `now()` 는 **트랜잭션 시작 시각**이라, 늦게 시작한
트랜잭션이 락을 먼저 잡으면 `created_at` 순서와 순번 순서가 어긋납니다.
`clock_timestamp()` 를 락 획득 후에 찍으면 락 순서 = 시각 순서 = 순번 순서가 됩니다.

락을 쥔 동안 그 클럽에 다른 INSERT 가 끼어들 수 없고 방금 넣은 행은 자기
트랜잭션에 이미 보이므로, `count(*)` 가 그대로 자기 순번입니다.

응답:

```json
{"ok": true, "already": false, "seq": 12, "capacity": 10,
 "status": "waitlist", "waitlist_no": 2}
```

- `already: true` — 이미 신청한 사람. 오류가 아니라 **기존 순번**을 돌려줍니다.
  응답이 유실돼 브라우저가 재시도한 경우에도 중복 저장·중복 오류가 나지 않습니다.
- `status` — `confirmed` (정원 내) 또는 `waitlist`
- 정원을 넘겨도 신청은 그대로 받습니다. 완료 화면에 "대기 N번" 이 표시됩니다.

**클라이언트에서 인원을 세어 정원을 막으면 안 됩니다.** 두 명이 동시에 "9명" 을
읽고 둘 다 INSERT 하면 11명이 됩니다. 페이지가 읽는 인원 수는 화면 표시 전용이고,
판정은 반드시 `apply()` 안에서 해야 합니다.

### 정원의 기준은 한 곳

```
private.settings.club_capacity     ← 유일한 기준. 판정에 쓰입니다
index.html  CLUBS[].capacity       ← 카드에 숫자를 찍는 표시용
```

한때 대시보드에도 `CAPACITY = 10` 이 하드코딩돼 있어, 정원을 2로 낮춘 상태에서
신청자 화면은 "대기 2번", 대시보드는 "확정 대상" 으로 **같은 사람을 다르게
판정하는** 일이 있었습니다. `app_stats()` 가 `capacity` 를 반환하게 해서
해결했습니다. 정원을 바꿀 때는 `private.settings` 를 고치세요.

### 조회 함수

| 함수 | 권한 | 내용 |
|---|---|---|
| `app_stats()` | anon EXECUTE | 집계만. 개인정보 없음. 정원·접수 창·서버 시각 포함 |
| `app_list(code)` | anon EXECUTE | 전체 명단. **운영진 코드 필요** |
| `apply(...)` | anon EXECUTE | 신청 저장 + 순번 부여 |

### 운영진 코드

`app_list()` 의 코드는 DB 의 `private.settings.admin_code` 에만 있습니다.
`private` 스키마는 REST API 에 노출되지 않아 `anon` 이 직접 읽을 수 없습니다.

**값을 이 레포의 어떤 파일에도 적지 마세요.** `anon` 키는 페이지에 노출되고
`app_list()` 는 `anon` 에게 EXECUTE 가 부여돼 있으므로, 이 코드가 유일한
방어선입니다. 코드가 공개되면 인증 없이 아래 한 줄로 전체 신청자의
이름·이메일·소속·메시지가 조회됩니다.

```bash
curl -X POST "$U/rest/v1/rpc/app_list" -H "apikey: $K" \
  -H "Content-Type: application/json" -d '{"p_code":"<코드>"}'
```

바꾸는 방법 (SQL Editor 에서만):

```sql
update private.settings set value = '<새코드>' where key = 'admin_code';
```

20자 이상 무작위 문자열을 쓰세요. 코드를 바꾸면 대시보드에 다시 입력해야 합니다.

> **이력**: 초기 코드가 `supabase_dashboard.sql` 에 담겨 공개 레포에 커밋된
> 적이 있습니다 (`8279589` 이후). 그 값은 히스토리에서 누구나 읽을 수 있으므로
> 폐기된 것으로 취급하고 재사용하지 마세요. 지금 코드가 그 값이면 바꿔야 합니다.

---

## 오픈 전 점검

```bash
K="<anon key>"; U="https://<project>.supabase.co"

# 정원·접수 창·잔여 데이터
curl -s -X POST "$U/rest/v1/rpc/app_stats" \
  -H "apikey: $K" -H "Authorization: Bearer $K" \
  -H "Content-Type: application/json" -d '{}'

# 오픈 전이면 not_open 이 나와야 정상 (행이 생기지 않음)
curl -s -X POST "$U/rest/v1/rpc/apply" \
  -H "apikey: $K" -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
  -d '{"p_name":"확인","p_email":"probe@example.invalid","p_team":"t","p_club":"신동걸"}'

# 직접 INSERT 는 401 이어야 정상 (200/400 이면 권한 회수가 안 된 것)
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$U/rest/v1/applications" \
  -H "apikey: $K" -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
  -d '{"name":"확인","email":"probe@example.invalid","team":"t","club":"신동걸","agree_rules":true,"agree_privacy":true}'
```

체크리스트:

- [ ] `app_stats().capacity` 가 실제 정원과 같은가
- [ ] `opens_at` / `closes_at` 가 `index.html` 의 `CONFIG` 와 같은가
- [ ] `apply()` 가 접수 창 밖에서 `not_open` / `closed` 를 돌려주는가
- [ ] 직접 INSERT 가 401 인가
- [ ] 테스트 데이터가 남아 있지 않은가
- [ ] 운영진 코드가 레포·페이지 어디에도 없는가

### 테스트 데이터 정리

테스트 신청은 지울 수 있는 도메인으로 넣으세요.

```sql
delete from public.applications where email like '%@wl-test.invalid';
```

**이 조건 하나만 쓰세요.** `... like '...' = false` 같은 부정 조건은
"테스트가 아닌 모든 행" = 실제 신청자 전원을 지웁니다.

### 동시성 테스트

같은 클럽에 동시 요청을 보내 `seq` 가 겹치지 않는지 확인합니다.

```bash
for i in $(seq 1 20); do
  curl -s -X POST "$U/rest/v1/rpc/apply" \
    -H "apikey: $K" -H "Authorization: Bearer $K" -H "Content-Type: application/json" \
    -d "{\"p_name\":\"버스트$i\",\"p_email\":\"b$i@wl-test.invalid\",\"p_team\":\"t\",\"p_club\":\"신동걸\"}" &
done
wait
```

`seq` 고유값 개수가 요청 수와 같아야 합니다. 겹치면 advisory lock 이 동작하지
않는 것입니다.

---

## 동시 트래픽 대응

오픈 정각에 요청이 몰리는 상황을 전제로 만들어져 있습니다.

- **정각 반응** — 오픈·마감 감시가 고정 주기가 아니라 다음 전환 시각까지 자는
  방식입니다. 09:59 에 페이지를 열어둔 사람도 10:00:00 에 바로 열립니다.
- **시계 보정** — `app_stats().server_time` 으로 기기 시계를 맞춥니다.
  실패해도 기기 시계로 동작하며, 허용 여부는 서버가 다시 판정합니다.
- **타임아웃** — 요청 15초. 없으면 "전송 중…" 에서 무한 대기합니다.
- **재시도** — 429/5xx 만 1회, 지터 백오프. 4xx 는 재시도해도 결과가 같습니다.
  첫 요청이 저장된 뒤 실패한 경우에도 `apply()` 가 기존 순번을 돌려주므로
  재시도가 중복으로 이어지지 않습니다.

`created_at` 을 클라이언트가 보내지 않는 것도 의도입니다. 서버가 찍으므로
순번 기준 시각이 기기 시계에 흔들리지 않습니다.

---

## 개발 이력과 결정

왜 이렇게 되어 있는지 — 되돌리려 할 때 먼저 읽으세요.

### 1차 · 페이지와 적재 (`80af04e` ~ `8279589`)

정적 페이지 + Supabase 직접 INSERT. `anon` 에게 INSERT 만 주고 SELECT 는
회수해서, 페이지에 키가 노출되어도 남의 신청은 못 읽게 했습니다.

### 2차 · 오픈 게이트와 대시보드 (`f05c186`)

`CONFIG.applyOpensAt` 로 버튼을 잠그고, 사내 이메일 도메인 제한을 풀었습니다.
도메인 제한이 외부인 차단선이었으므로, 이때부터 공개 URL 에서 누구나 신청할 수
있게 됐습니다. 남은 방어는 honeypot 과 중복 차단뿐입니다.

당시 커밋 메시지에 "콘솔로 강제 제출해도 저장되지 않게 이중 방어" 라고 적혀
있지만, **둘 다 클라이언트 측 검사였습니다.** 실제로는 기기 시계를 조작하거나
devtools 로 제출하면 접수 창 밖에도 저장됐습니다. 3차에서 서버 검증으로
막았습니다.

### 3차 · 대기 순번과 동시성 (`ebc6e6b` ~)

"40명이 넘으면 대기자로 넘어가나요?" 라는 질문을 확인하다 **대기자 기능이 아예
없다**는 것을 발견해 만들었습니다. `capacity` 는 카드에 숫자를 찍는 값이었고,
제출 경로에는 정원 확인이 없었습니다.

`apply()` 를 만들면서 몇 가지를 의도적으로 선택했습니다.

- **클라이언트 카운트 방식을 쓰지 않았습니다.** 두 명이 동시에 "9명" 을 읽고
  둘 다 INSERT 하면 11명이 됩니다. 오히려 정원 체크가 없던 원래 코드가
  경쟁 조건에는 안전했습니다.
- **advisory lock + `clock_timestamp()`** — 이유는 위 "정원과 대기 순번" 절 참고.
- **중복 신청을 오류로 처리하지 않았습니다.** 기존 순번을 돌려주는 멱등 응답으로
  만들어, 응답이 유실된 뒤 재시도해도 엉뚱한 중복 오류가 나지 않게 했습니다.
- **`apply()` 가 없으면 직접 INSERT 로 폴백**하는 경로를 넣었습니다. 마이그레이션
  전에 배포되어도 신청이 유실되지 않게 하려는 것이었고, 4차에서 직접 INSERT
  권한을 회수하면서 사실상 죽은 경로가 됐습니다. 남겨둔 것은 무해합니다.

검증: 같은 클럽 동시 20건에서 `seq` 고유값 20개 · 중복 0.

### 4차 · 실시간 인원과 UI (`dfd2a7d`)

정원 2명으로 테스트했는데 2명이 차도 화면이 그대로였습니다. 페이지가 현재
인원을 **조회하지 않았기 때문**입니다. `app_stats()` 를 읽어 카드·버튼·모달에
반영했습니다.

**정원이 차도 버튼을 잠그지 않습니다.** 대기 신청을 계속 받는 것이 의도이므로,
잠긴 상태(회색+자물쇠)와 구분되게 주황색 `대기자로 신청하기` 로 둡니다.

### 5차 · 정리 (`621b1f6` ~ `312f01f`)

- 2순위 클럽 항목 제거 (신청 폼·완료 화면·대시보드·CSV·`app_stats`)
- `app_stats()` 에 `capacity` 추가 → 대시보드 하드코딩 제거
- 도서 표지·저자명·교보문고 링크
- 운영진 코드를 `supabase_dashboard.sql` 에서 제거

### 겪은 함정 목록

같은 실수를 반복하지 않기 위한 기록입니다.

| 증상 | 원인 |
|---|---|
| 정원이 차도 화면 그대로 | 페이지가 실시간 인원을 조회하지 않음 |
| 신청자 화면과 대시보드가 같은 사람을 다르게 판정 | 대시보드에 `CAPACITY = 10` 하드코딩 |
| 표지가 4권 모두 같은 이미지 | 상품ID 경로가 플레이스홀더를 200 으로 반환 |
| 페이지가 열려도 제출이 거부됨 | DB `apply_opens_at` 을 같이 안 바꿈 |
| 배포했는데 화면이 안 바뀜 | 브라우저 캐시 — ⌘⇧R 필요 |
| 검증 스크립트가 이미지를 덮어씀 | 루프에서 두 URL 을 같은 파일명으로 받음 |
| `delete ... like '...' = false` | "테스트가 아닌 모든 행" = 실제 신청자 전원 삭제 |

---

## 알려진 미해결

- **마감 후 대기 접수 경로 없음** — 마감 시각이 지나면 `apply()` 가 `closed` 로
  거부하므로 대기 신청도 불가합니다. 별도 페이지를 만들지 말고
  `private.settings` 에 `waitlist_closes_at` 를 추가해 같은 페이지에서 접수 창을
  2단으로 두는 편이 낫습니다. 데이터가 갈라지지 않고, 중복 신청 차단이 그대로
  걸리고, `apply()` 는 이미 `seq > capacity → waitlist` 로 판정하므로 로직 추가가
  없습니다.
- **`club2` 컬럼** — "2순위 클럽" 항목을 페이지에서 제거했지만 컬럼과
  `apply()` 의 `p_club2` 파라미터는 남아 있습니다. 컬럼 삭제는 되돌릴 수 없어
  별도 판단이 필요합니다.
