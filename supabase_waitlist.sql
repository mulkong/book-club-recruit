-- ════════════════════════════════════════════════════════════════
-- 3차 설정 — 대기 순번 부여 + 서버 측 접수 창 검증
--
-- 실행 순서가 중요합니다.
--   STEP 1  아래 "STEP 1" 구역 전체를 SQL Editor 에 붙여넣고 [Run]
--   STEP 2  페이지에서 테스트 신청 1건이 정상 동작하는지 확인
--   STEP 3  맨 아래 "STEP 3" 한 줄을 실행 (직접 INSERT 경로 차단)
--
-- STEP 3 을 먼저 실행하면, 페이지가 아직 배포되지 않은 동안 신청이
-- 전부 실패합니다. 반드시 순서를 지켜주세요.
-- ════════════════════════════════════════════════════════════════


-- ┌──────────────────────────────────────────────────────────────┐
-- │ STEP 1                                                        │
-- └──────────────────────────────────────────────────────────────┘

-- ── 1. 운영 설정값 ───────────────────────────────────────────────
-- 정원과 접수 창의 '진짜' 기준입니다. 페이지의 CONFIG 는 화면 표시용이고,
-- 실제 허용 여부는 여기 값으로 서버가 판정합니다. 둘을 같은 값으로 유지하세요.
insert into private.settings (key, value) values
  ('club_capacity',   '10'),
  ('apply_opens_at',  '2026-08-07T10:00:00+09:00'),
  ('apply_closes_at', '2026-08-12T18:00:00+09:00')
on conflict (key) do update set value = excluded.value;

-- 정원을 바꿀 때:   update private.settings set value='2'  where key='club_capacity';
-- 지금 바로 열 때:  update private.settings set value='2000-01-01T00:00:00+09:00' where key='apply_opens_at';


-- ── 2. 순번 계산용 인덱스 ────────────────────────────────────────
-- 클럽별 count(*) 와 순번 정렬을 함께 커버합니다.
create index if not exists applications_club_seq_idx
  on public.applications (club, created_at, id);


-- ── 3. 신청 접수 함수 ────────────────────────────────────────────
-- 이 함수 하나가 (a) 접수 창 검증 (b) INSERT (c) 순번 계산을
-- 한 트랜잭션에서 처리합니다. 그래서 동시에 몰려도 순번이 겹치지 않습니다.
--
-- 동시성 핸들링의 핵심 두 줄:
--   pg_advisory_xact_lock  같은 클럽 신청을 직렬화 (다른 클럽은 병렬 진행)
--   clock_timestamp()      락을 잡은 순서 = created_at 순서 = 순번 순서
--
-- now() 를 쓰면 안 됩니다. now() 는 '트랜잭션 시작 시각' 이라서, 늦게 시작한
-- 트랜잭션이 락을 먼저 잡는 경우 created_at 순서와 순번 순서가 어긋납니다.

create or replace function public.apply(
  p_name    text,
  p_email   text,
  p_team    text,
  p_club    text,
  p_club2   text default null,
  p_message text default null
) returns json
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_opens  timestamptz;
  v_closes timestamptz;
  v_cap    int;
  v_seq    int;
begin
  select value::timestamptz into v_opens  from private.settings where key = 'apply_opens_at';
  select value::timestamptz into v_closes from private.settings where key = 'apply_closes_at';
  select value::int         into v_cap    from private.settings where key = 'club_capacity';
  v_cap := coalesce(v_cap, 10);

  -- 접수 창 검증. 기기 시계와 무관하게 서버 시각으로만 판정합니다.
  if v_opens is not null and clock_timestamp() < v_opens then
    return json_build_object('ok', false, 'code', 'not_open', 'opens_at', v_opens);
  end if;
  if v_closes is not null and clock_timestamp() >= v_closes then
    return json_build_object('ok', false, 'code', 'closed', 'closes_at', v_closes);
  end if;

  -- 같은 클럽 신청을 직렬화. 트랜잭션이 끝나면 자동으로 풀립니다.
  perform pg_advisory_xact_lock(4218, hashtext(coalesce(p_club, '')));

  begin
    insert into public.applications
      (created_at, name, email, team, club, club2, message, agree_rules, agree_privacy)
    values
      (clock_timestamp(),
       btrim(p_name),
       lower(btrim(p_email)),
       btrim(p_team),
       p_club,
       nullif(btrim(coalesce(p_club2,   '')), ''),
       nullif(btrim(coalesce(p_message, '')), ''),
       true, true);

    -- 락을 잡고 있는 동안에는 이 클럽에 다른 INSERT 가 끼어들 수 없고,
    -- 방금 넣은 행은 이미 자기 트랜잭션에 보입니다. 따라서 count = 내 순번.
    select count(*) into v_seq from public.applications where club = p_club;

  exception
    -- 이미 신청한 사람. 오류로 끝내지 않고 '기존 신청의 순번' 을 돌려줍니다.
    -- 응답이 유실된 뒤 브라우저가 재시도한 경우(첫 요청은 이미 커밋됨)에도
    -- 엉뚱한 중복 오류 대신 올바른 순번이 보이게 하려는 것입니다.
    when unique_violation then
      select count(*) into v_seq
      from public.applications a
      where a.club = p_club
        and (a.created_at, a.id) <= (
          select created_at, id from public.applications
          where club = p_club and lower(email) = lower(btrim(p_email))
        );

      return json_build_object(
        'ok',          true,
        'already',     true,
        'seq',         v_seq,
        'capacity',    v_cap,
        'status',      case when v_seq <= v_cap then 'confirmed' else 'waitlist' end,
        'waitlist_no', case when v_seq >  v_cap then v_seq - v_cap else null end
      );

    when others then
      return json_build_object('ok', false, 'code', 'invalid', 'detail', sqlerrm);
  end;

  return json_build_object(
    'ok',          true,
    'already',     false,
    'seq',         v_seq,
    'capacity',    v_cap,
    'status',      case when v_seq <= v_cap then 'confirmed' else 'waitlist' end,
    'waitlist_no', case when v_seq >  v_cap then v_seq - v_cap else null end
  );
end;
$$;

revoke all on function public.apply(text, text, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.apply(text, text, text, text, text, text) to anon;


-- ── 4. app_list 순번 결정성 보강 ─────────────────────────────────
-- created_at 이 완전히 같은 두 행이 생기면 row_number 결과가 조회마다
-- 달라질 수 있습니다. id 를 2차 정렬키로 넣어 고정합니다.
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
      select *, row_number() over (partition by club order by created_at, id) as seq
      from public.applications
    ) a
  ), '[]'::json);
end;
$$;

revoke all on function public.app_list(text) from public, anon, authenticated;
grant execute on function public.app_list(text) to anon;


-- ── 5. 확인 ──────────────────────────────────────────────────────
-- 접수 창 밖이면 not_open / closed 가 나와야 정상입니다.
--   select public.apply('테스터','tester@navercorp.com','테스트팀','신동걸');
--
-- 클럽별 현황 + 정원 초과분:
--   select club, count(*) as 신청, greatest(0, 10 - count(*)) as 남은자리,
--          greatest(0, count(*) - 10) as 대기자
--   from public.applications group by club order by 신청 desc;


-- ┌──────────────────────────────────────────────────────────────┐
-- │ STEP 3 — 페이지 테스트가 끝난 뒤에 실행                        │
-- │                                                               │
-- │ anon 의 직접 INSERT 권한을 회수합니다. 이걸 실행해야            │
-- │   · 접수 창 검증을 우회한 제출(기기 시계 조작, devtools)이 막히고 │
-- │   · 모든 신청이 apply() 를 거쳐 순번을 받습니다.                │
-- │                                                               │
-- │ 실행 전에 반드시 페이지 배포 + 테스트 신청 1건을 확인하세요.     │
-- └──────────────────────────────────────────────────────────────┘

-- revoke insert on public.applications from anon;
-- drop policy if exists "anon can insert" on public.applications;


-- ── 되돌리기 (문제가 생겼을 때) ──────────────────────────────────
--   grant insert on public.applications to anon;
--   create policy "anon can insert" on public.applications
--     for insert to anon with check (true);
