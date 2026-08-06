-- ════════════════════════════════════════════════════════════════
-- 2차 설정 — 이메일 도메인 제한 해제 + 대시보드용 조회 함수
-- Supabase > SQL Editor 에 전체 붙여넣고 [Run]. 한 번만 실행하면 됩니다.
-- ════════════════════════════════════════════════════════════════

-- ── 1. 이메일 도메인 제한 해제 ───────────────────────────────────
-- 기존에는 @navercorp.com / @snowcorp.com 만 허용했습니다.
-- 이제 형식만 검사하고 도메인은 제한하지 않습니다.
alter table public.applications drop constraint if exists applications_email_check;
alter table public.applications add constraint applications_email_check
  check (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$');


-- ── 2. 운영진 코드 보관용 비공개 스키마 ──────────────────────────
-- private 스키마는 REST API 에 노출되지 않으므로 anon 이 직접 읽을 수 없습니다.
create schema if not exists private;
revoke all on schema private from anon, authenticated;

create table if not exists private.settings (
  key   text primary key,
  value text not null
);
revoke all on private.settings from anon, authenticated;

-- ▼▼▼ 운영진 코드 ▼▼▼
-- 이 레포는 공개되어 있습니다. 코드를 여기 적으면 안 됩니다.
-- app_list() 는 anon 에게 EXECUTE 가 부여돼 있고 anon 키는 페이지에 노출되므로,
-- 이 코드가 유일한 방어선입니다. 코드가 공개되면 전체 신청자의 이름·이메일·
-- 소속·메시지를 누구나 조회할 수 있습니다.
--
-- 아래 한 줄을 SQL Editor 에서만 실행하세요 (레포에 커밋하지 말 것):
--   insert into private.settings (key, value) values ('admin_code', '<실제코드>')
--     on conflict (key) do update set value = excluded.value;
--
-- 코드는 20자 이상 무작위 문자열을 쓰세요. 추측 가능한 단어는 쓰지 마세요.


-- ── 3. 집계 통계 (코드 불필요, 개인정보 없음) ────────────────────
-- 대시보드가 20초마다 호출합니다. 이름·이메일은 절대 나가지 않습니다.
create or replace function public.app_stats()
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object(
    'total',      (select count(*) from public.applications),
    'server_time', now(),

    -- 클럽별 신청 수 (첫 신청 시각 포함)
    'clubs', coalesce((
      select json_agg(json_build_object(
               'club', club, 'applied', applied, 'first_at', first_at, 'last_at', last_at)
             order by applied desc, club)
      from (
        select club, count(*) as applied,
               min(created_at) as first_at, max(created_at) as last_at
        from public.applications group by club
      ) c
    ), '[]'::json),

    -- 2순위로 지목된 횟수
    'second_choice', coalesce((
      select json_agg(json_build_object('club', club2, 'picked', n) order by n desc, club2)
      from (select club2, count(*) as n from public.applications
            where club2 is not null group by club2) s
    ), '[]'::json),

    -- 일자별 신청 추이 (KST)
    'daily', coalesce((
      select json_agg(json_build_object('day', d, 'n', n) order by d)
      from (
        select (created_at at time zone 'Asia/Seoul')::date as d, count(*) as n
        from public.applications group by 1
      ) t
    ), '[]'::json),

    -- 소속 조직 분포 (상위 8개)
    'teams', coalesce((
      select json_agg(json_build_object('team', team, 'n', n) order by n desc, team)
      from (select team, count(*) as n from public.applications
            group by team order by n desc, team limit 8) g
    ), '[]'::json),

    -- 2순위를 적은 비율 / 메시지를 남긴 비율
    'extras', (
      select json_build_object(
        'with_second',  count(*) filter (where club2 is not null),
        'with_message', count(*) filter (where message is not null and btrim(message) <> ''))
      from public.applications
    )
  );
$$;

revoke all on function public.app_stats() from public, anon, authenticated;
grant execute on function public.app_stats() to anon;


-- ── 4. 전체 명단 (운영진 코드 필요) ──────────────────────────────
-- 코드가 틀리면 예외를 던집니다. 코드는 페이지 소스에 없고 여기서만 검증됩니다.
create or replace function public.app_list(p_code text)
returns json
language plpgsql
security definer
set search_path = public, private
as $$
declare
  ok boolean;
begin
  select p_code is not null
         and p_code = (select value from private.settings where key = 'admin_code')
    into ok;

  if not ok then
    raise exception 'invalid admin code' using errcode = '42501';
  end if;

  return coalesce((
    select json_agg(json_build_object(
             'created_at', created_at,
             'club',       club,
             'club2',      club2,
             'name',       name,
             'team',       team,
             'email',      email,
             'message',    message,
             'seq',        seq)
           order by club, seq)
    from (
      select *, row_number() over (partition by club order by created_at) as seq
      from public.applications
    ) a
  ), '[]'::json);
end;
$$;

revoke all on function public.app_list(text) from public, anon, authenticated;
grant execute on function public.app_list(text) to anon;


-- ── 5. 확인 ──────────────────────────────────────────────────────
-- select public.app_stats();
-- select public.app_list('<실제코드>');
-- select public.app_list('틀린코드');   -- 42501 예외가 나야 정상
