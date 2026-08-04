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

외부 라이브러리·CDN·웹폰트 의존이 없습니다. 파일 하나만 열어도 그대로 동작합니다.

## 신청 데이터

신청 내역은 Supabase(Postgres) 의 `applications` 테이블에 적재됩니다.
페이지에 포함된 키는 Supabase 의 **anon(공개) 키**로, 브라우저에 노출되는 것이 정상입니다.
실제 접근 제어는 DB 의 RLS 정책이 담당합니다.

- `INSERT` 만 허용 — 신청서 제출만 가능
- `SELECT` 권한 없음 — 다른 사람의 신청 내역은 아무도 조회할 수 없습니다
- 사내 이메일 도메인이 아닌 주소는 DB 제약으로 거부됩니다
- 같은 사람이 같은 클럽에 중복 신청할 수 없습니다

신청 내역 조회는 운영진이 Supabase 대시보드에서 진행합니다.

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
