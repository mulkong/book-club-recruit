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
- **모집 기간** 2026-08-07 (금) 10:00 ~ 2026-08-12 (수) 18:00 KST
- **정원** 클럽당 10명 · 4개 클럽 · 총 40석

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
