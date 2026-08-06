# 독서 스터디 4기 모집 페이지

사내 독서 스터디 4기 멤버를 모집하는 한 장짜리 정적 페이지입니다.
4개 클럽을 소개하고, 클럽별 신청을 받습니다.

**배포 주소:** https://mulkong.github.io/book-club-recruit/

## 구성

| 파일 | 설명 |
|---|---|
| `index.html` | 페이지 전체. CSS·JS·이미지가 모두 인라인된 자체 완결형 단일 파일 |
| `.nojekyll` | GitHub Pages 의 Jekyll 전처리 비활성화 |
| `robots.txt` | 검색엔진 크롤링 차단 |
| `supabase_*.sql` | DB 스키마·권한·조회 함수. Supabase SQL Editor 에서 실행 |

외부 라이브러리·CDN·웹폰트 의존이 없습니다. 파일 하나만 열어도 그대로 동작합니다.

## 신청 데이터

신청 내역은 Supabase(Postgres) 의 `applications` 테이블에 적재됩니다.
페이지에 포함된 키는 Supabase 의 **anon(공개) 키**로, 브라우저에 노출되는 것이 정상입니다.
실제 접근 제어는 DB 의 권한·RLS 정책이 담당합니다.

- 저장은 `public.apply()` 함수를 통해서만 — 테이블 직접 `INSERT` 는 차단
- `SELECT` 권한 없음 — 다른 사람의 신청 내역은 아무도 조회할 수 없습니다
- 이메일은 형식만 검사하고 도메인은 제한하지 않습니다
- 같은 사람이 같은 클럽에 중복 신청할 수 없습니다

신청 내역 조회는 운영진이 Supabase 대시보드에서 진행합니다.

### 정원과 대기 순번

`apply()` 함수 하나가 **접수 창 검증 · INSERT · 순번 계산을 한 트랜잭션에서** 처리합니다.

- 정원과 접수 창의 기준값은 `private.settings` 에 있습니다. 페이지의 `CONFIG` 는 화면
  표시용이고, 실제 허용 여부는 서버가 다시 판정합니다. 두 값을 같게 유지하세요.
- 클럽별 `pg_advisory_xact_lock` 으로 같은 클럽 신청을 직렬화하므로, 동시에 몰려도
  순번이 겹치지 않습니다. `created_at` 은 락을 잡은 뒤 `clock_timestamp()` 로 찍어
  순번 순서와 시각 순서가 어긋나지 않게 합니다.
- 정원을 넘기면 신청은 그대로 접수되고 완료 화면에 **대기 N번**이 표시됩니다.
- 이미 신청한 사람이 다시 제출하면 오류 대신 기존 순번을 돌려줍니다(멱등).
  요청이 유실돼 브라우저가 재시도한 경우에도 중복 저장·중복 오류가 나지 않습니다.

정원을 바꿀 때는 `private.settings.club_capacity` 와 `index.html` 의 `CLUBS[].capacity`
**둘 다** 고쳐야 합니다.

## 수정 방법

`index.html` 하단 스크립트의 상수만 고치면 페이지 전체가 갱신됩니다.

```js
const CONFIG   = { ... }   // 모집 기간, 장소, 문의처, 허용 이메일 도메인
const SUPABASE = { ... }   // Project URL, anon key
const CLUBS    = [ ... ]   // 클럽 4개 정보 (텔러, 테마, 첫 도서, 요일, 정원)
const PENDING  = [ ... ]   // 조율 중인 항목
const FAQS     = [ ... ]   // 자주 묻는 질문
```

확정되지 않은 값은 `TBD` 상수를 쓰면 페이지에서 "추후 공지" 배지로 표시됩니다.

## 배포

`main` 브랜치에 푸시하면 GitHub Pages 가 자동으로 반영합니다.
(Settings → Pages → Source: `main` / `/ (root)`)
