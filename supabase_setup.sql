-- ════════════════════════════════════════════════════════════════
-- 독서 스터디 4기 신청 적재 테이블
-- Supabase 프로젝트 > SQL Editor 에 붙여넣고 [Run] 하세요. 한 번만 실행하면 됩니다.
-- ════════════════════════════════════════════════════════════════

create table if not exists public.applications (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),

  name          text not null check (char_length(btrim(name)) between 1 and 40),

  -- 사내 이메일만 허용. 페이지가 공개 URL이라 아무나 열 수 있지만,
  -- 사내 도메인이 아니면 DB가 거부합니다. 이게 실질적인 외부인 차단선입니다.
  email         text not null check (email ~* '^[^@[:space:]]+@(navercorp|snowcorp)\.com$'),

  team          text not null check (char_length(btrim(team)) between 1 and 60),

  club          text not null check (club in ('신동걸','정지혜','강민구','백송이')),
  club2         text          check (club2 in ('신동걸','정지혜','강민구','백송이')),

  message       text          check (message is null or char_length(message) <= 500),

  agree_rules   boolean not null check (agree_rules),
  agree_privacy boolean not null check (agree_privacy)
);

-- 같은 사람이 같은 클럽에 두 번 신청하는 것 방지 (페이지에서는 409 → 안내 문구)
create unique index if not exists applications_email_club_uniq
  on public.applications (lower(email), club);


-- ── 접근 제어 ────────────────────────────────────────────────────
-- anon(브라우저에서 쓰는 공개 역할)에게는 INSERT 만 허용합니다.
-- SELECT 권한을 아예 회수하므로, 페이지의 anon 키를 그대로 가져다 써도
-- 다른 사람의 신청 내역은 조회할 수 없습니다.

alter table public.applications enable row level security;

revoke all on public.applications from anon;
grant insert on public.applications to anon;

drop policy if exists "anon can insert" on public.applications;
create policy "anon can insert"
  on public.applications
  for insert
  to anon
  with check (true);


-- ════════════════════════════════════════════════════════════════
-- 운영진 조회용 쿼리 (SQL Editor 에서 필요할 때 실행)
-- ════════════════════════════════════════════════════════════════

-- 1) 클럽별 신청 현황 요약
--
-- select club                                                    as 클럽,
--        count(*)                                                as 신청자수,
--        greatest(0, 10 - count(*))                              as 남은자리,
--        string_agg(name || ' (' || team || ')', ', '
--                   order by created_at)                         as 명단
-- from public.applications
-- group by club
-- order by 신청자수 desc;

-- 2) 정원(10명) 초과분 = 대기자. 신청 순서대로 번호를 붙입니다.
--
-- select club as 클럽, 순번, name as 이름, team as 소속, email,
--        case when 순번 <= 10 then '확정 대상' else '대기 ' || (순번 - 10) || '번' end as 상태
-- from (
--   select *, row_number() over (partition by club order by created_at) as 순번
--   from public.applications
-- ) t
-- order by club, 순번;

-- 3) 전체 신청 내역 (CSV 내려받기: Table Editor > applications > Export)
--
-- select created_at as 신청시각, club as 클럽, club2 as 2순위,
--        name as 이름, team as 소속, email as 이메일, message as 메시지
-- from public.applications
-- order by created_at;

-- 4) 테스트 신청 정리 (배포 검증 후)
--
-- delete from public.applications where email = 'tester@navercorp.com';
