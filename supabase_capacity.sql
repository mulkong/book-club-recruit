-- ════════════════════════════════════════════════════════════════
-- 4차 설정 — app_stats() 에 정원(capacity) 포함
--
-- 정원 기준이 신청페이지 · 대시보드 · private.settings 세 곳에 흩어져 있어서,
-- 정원을 바꾸면 세 곳을 모두 고쳐야 했습니다. app_stats() 가 정원을 함께
-- 돌려주게 해서 대시보드의 하드코딩(CAPACITY = 10)을 없앱니다.
--
-- 이제 정원의 유일한 기준은 private.settings.club_capacity 입니다.
-- (신청페이지의 CLUBS[].capacity 는 카드에 숫자를 찍는 표시용으로만 남습니다)
--
-- SQL Editor 에 전체 붙여넣고 [Run]. 여러 번 실행해도 안전합니다.
-- ════════════════════════════════════════════════════════════════

create or replace function public.app_stats()
returns json
language sql
security definer
set search_path = public, private
as $$
  select json_build_object(
    'total',      (select count(*) from public.applications),
    'server_time', now(),

    -- 클럽당 정원. 대시보드가 이 값으로 확정/대기를 판정합니다.
    'capacity', coalesce(
      (select value::int from private.settings where key = 'club_capacity'), 10),

    -- 접수 창 (페이지가 기기 시계를 보정하고 상태를 판정하는 데 씁니다)
    'opens_at',  (select value::timestamptz from private.settings where key = 'apply_opens_at'),
    'closes_at', (select value::timestamptz from private.settings where key = 'apply_closes_at'),

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

    -- 메시지를 남긴 비율
    'extras', (
      select json_build_object(
        'with_message', count(*) filter (where message is not null and btrim(message) <> ''))
      from public.applications
    )
  );
$$;

revoke all on function public.app_stats() from public, anon, authenticated;
grant execute on function public.app_stats() to anon;


-- ── 확인 ────────────────────────────────────────────────────────
-- capacity / opens_at / closes_at 가 함께 나와야 정상입니다.
--   select public.app_stats();
