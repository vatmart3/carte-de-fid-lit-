-- ═══════════════════════════════════════════════════════════════════════
--  La Carte du Boucher — schéma Supabase
--  À coller tel quel dans Supabase → SQL Editor → Run.
--  Idempotent : peut être rejoué sans casser les données existantes.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 1. Tables ──────────────────────────────────────────────────────────

create table if not exists public.shop (
  id   int primary key default 1,
  data jsonb not null,
  constraint shop_single_row check (id = 1)
);

create sequence if not exists public.card_seq start 1001;

create table if not exists public.clients (
  id          text primary key,
  token       uuid not null default gen_random_uuid(),
  name        text not null,
  phone       text not null,
  email       text,
  bday_day    smallint check (bday_day between 1 and 31),
  bday_month  smallint check (bday_month between 1 and 12),
  created     date not null default current_date,
  code        text not null,
  points      int  not null default 0,
  lifetime    int  not null default 0,
  spent       numeric(10,2) not null default 0,
  visits      int  not null default 0,
  last_visit  date,
  referred_by text references public.clients(id) on delete set null,
  note        text
);
-- Colonnes ajoutées après coup : l'installation existante est mise à niveau.
alter table public.clients add column if not exists bday_day   smallint;
alter table public.clients add column if not exists bday_month smallint;
alter table public.clients add column if not exists consent_at timestamptz;
alter table public.clients add column if not exists notice     text;
alter table public.clients add column if not exists marketing  boolean not null default false;
alter table public.clients add column if not exists marketing_at timestamptz;

-- Minimisation : l'année de naissance n'est utile à aucun usage du programme.
-- Si une ancienne colonne « bday » existe, on n'en garde que le jour et le mois.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'clients' and column_name = 'bday') then
    execute 'update public.clients
                set bday_day   = coalesce(bday_day, extract(day from bday)::smallint),
                    bday_month = coalesce(bday_month, extract(month from bday)::smallint)
              where bday is not null';
    execute 'alter table public.clients drop column bday';
    raise notice 'Année de naissance supprimée : seuls le jour et le mois sont conservés.';
  end if;
end $$;

create unique index if not exists clients_token_key on public.clients(token);
create unique index if not exists clients_phone_key on public.clients(phone);
create unique index if not exists clients_code_key  on public.clients(code);

create table if not exists public.moves (
  id         bigserial primary key,
  client_id  text not null references public.clients(id) on delete cascade,
  t          date not null default current_date,
  amount     numeric(10,2) not null default 0,
  points     int not null default 0,
  label      text not null,
  kind       text not null check (kind in ('buy','reward','gift','ref','welcome','adj')),
  created_at timestamptz not null default now()
);
create index if not exists moves_client_idx on public.moves(client_id, t desc, id desc);

-- Le journal ne contient jamais de nom : seulement le numéro de carte, pour
-- que l'effacement d'une fiche (art. 17) n'en laisse aucune trace nominative.
create table if not exists public.log (
  id         bigserial primary key,
  t          date not null default current_date,
  m          text not null,
  client_id  text,
  created_at timestamptz not null default now()
);
alter table public.log add column if not exists client_id text;
create index if not exists log_client_idx on public.log(client_id);

-- Le personnel autorisé. Un compte Supabase ne suffit pas : il faut être ici.
create table if not exists public.staff (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name    text,
  added   timestamptz not null default now()
);

-- ── 2. Réglages par défaut ─────────────────────────────────────────────

insert into public.shop (id, data) values (1, jsonb_build_object(
  'name', 'Boucherie Vatuone',
  'city', 'Sète',
  'tagline', 'Artisan boucher — viandes de pays',
  'ppe', 1, 'welcome', 20, 'birthday', 50, 'godfather', 50, 'godchild', 25,
  'retention_years', 3,
  'legal', jsonb_build_object(
    'raison_sociale', '', 'adresse', '', 'siret', '',
    'contact_email', '', 'contact_tel', '', 'directeur', ''),
  'rewards', jsonb_build_array(
    jsonb_build_object('p', 100, 'label', '500 g de merguez maison offerts'),
    jsonb_build_object('p', 200, 'label', '10 € de remise sur votre achat'),
    jsonb_build_object('p', 350, 'label', 'Un poulet fermier offert'),
    jsonb_build_object('p', 500, 'label', 'Plateau apéritif charcuterie offert'),
    jsonb_build_object('p', 800, 'label', '30 € de remise + le colis du boucher')),
  'tiers', jsonb_build_array(
    jsonb_build_object('min', 0,    'label', 'Nouveau'),
    jsonb_build_object('min', 300,  'label', 'Fidèle'),
    jsonb_build_object('min', 800,  'label', 'Habitué'),
    jsonb_build_object('min', 1500, 'label', 'Ambassadeur'))
)) on conflict (id) do nothing;

-- ── 3. Verrouillage : personne n'atteint les tables sans être du personnel ──

alter table public.shop    enable row level security;
alter table public.clients enable row level security;
alter table public.moves   enable row level security;
alter table public.log     enable row level security;
alter table public.staff   enable row level security;

create or replace function public.is_staff() returns boolean
  language sql stable security definer set search_path = public, pg_temp as
$$ select exists (select 1 from public.staff s where s.user_id = auth.uid()) $$;

do $$
declare t text;
begin
  foreach t in array array['shop','clients','moves','log','staff'] loop
    execute format('drop policy if exists staff_all on public.%I', t);
    execute format(
      'create policy staff_all on public.%I for all to authenticated
         using (public.is_staff()) with check (public.is_staff())', t);
  end loop;
end $$;

-- Le client anonyme n'a aucun accès direct aux tables : il passe par les
-- quatre fonctions ci-dessous, et rien d'autre.
revoke all on public.shop, public.clients, public.moves, public.log, public.staff from anon;

-- Le tout premier compte créé devient automatiquement le personnel : plus besoin
-- de recopier son identifiant à la main. Les suivants ne le sont pas.
create or replace function public.enroll_first_staff() returns trigger
  language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not exists (select 1 from public.staff) then
    insert into public.staff (user_id, name) values (new.id, coalesce(new.email, 'Compte principal'));
  end if;
  return new;
end $$;

do $$
begin
  execute 'drop trigger if exists enroll_first_staff on auth.users';
  execute 'create trigger enroll_first_staff after insert on auth.users
             for each row execute function public.enroll_first_staff()';
exception when others then
  raise notice 'Inscription automatique du personnel indisponible sur ce projet. Ajoutez le compte à la main : insert into public.staff (user_id, name) select id, ''Le boucher'' from auth.users where email = ''...'';';
end $$;

-- ── 4. Ce que le public peut faire ─────────────────────────────────────

-- Retire les accents sans dépendre de l'extension unaccent.
create or replace function public.unaccent_fallback(t text) returns text
  language sql immutable set search_path = pg_temp as
$$ select translate(coalesce(t,''),
     'àâäáãåçéèêëíìîïñóòôöõúùûüýÿÀÂÄÁÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜÝ',
     'aaaaaaceeeeiiiinooooouuuuyyAAAAAACEEEEIIIINOOOOOUUUUY') $$;

-- Réglages publics (barème, récompenses) — pour la page d'inscription.
create or replace function public.public_shop() returns jsonb
  language sql stable security definer set search_path = public, pg_temp as
$$ select data - 'pin' from public.shop where id = 1 $$;

-- La carte d'un client, à partir de son lien personnel.
create or replace function public.get_card(p_token uuid) returns jsonb
  language plpgsql stable security definer set search_path = public, pg_temp as $$
declare c public.clients; out jsonb;
begin
  select * into c from public.clients where token = p_token;
  if not found then return null; end if;
  select jsonb_build_object(
    'id', c.id, 'name', c.name, 'phone', c.phone, 'email', c.email,
    'bday_day', c.bday_day, 'bday_month', c.bday_month,
    'marketing', c.marketing, 'consent_at', c.consent_at,
    'created', c.created, 'code', c.code,
    'points', c.points, 'lifetime', c.lifetime, 'spent', c.spent, 'visits', c.visits,
    'last_visit', c.last_visit,
    'parrain', (select p.name from public.clients p where p.id = c.referred_by),
    'filleuls', coalesce((select jsonb_agg(f.name order by f.created)
                          from public.clients f where f.referred_by = c.id), '[]'::jsonb),
    'hist', coalesce((select jsonb_agg(jsonb_build_object(
              't', m.t, 'a', m.amount, 'p', m.points, 'w', m.label, 'k', m.kind)
              order by m.t desc, m.id desc)
            from public.moves m where m.client_id = c.id), '[]'::jsonb),
    'shop', (select data - 'pin' from public.shop where id = 1)
  ) into out;
  return out;
end $$;

-- Retrouver son lien : téléphone + jour et mois de naissance.
drop function if exists public.find_card(text, date);
create or replace function public.find_card(p_phone text, p_day int, p_month int) returns jsonb
  language sql stable security definer set search_path = public, pg_temp as
$$ select jsonb_build_object('token', token) from public.clients
   where phone = regexp_replace(p_phone, '[^0-9+]', '', 'g')
     and bday_day = p_day and bday_month = p_month $$;

-- Créer sa carte. Les points de bienvenue et de parrainage sont calculés ici,
-- côté serveur : le navigateur ne peut pas s'en attribuer davantage.
drop function if exists public.create_card(text, text, date, text, text);
create or replace function public.create_card(
    p_name text, p_phone text, p_day int, p_month int,
    p_email text default null, p_ref text default null,
    p_marketing boolean default false, p_notice text default null) returns jsonb
  language plpgsql security definer set search_path = public, pg_temp as $$
declare
  s jsonb; nid text; ncode text; ph text; par public.clients;
  welcome int; godchild int; godfather int; total int;
begin
  ph := regexp_replace(coalesce(p_phone,''), '[^0-9+]', '', 'g');
  if length(btrim(coalesce(p_name,''))) < 3 then raise exception 'nom_invalide'; end if;
  if length(ph) < 9 then raise exception 'telephone_invalide'; end if;
  if p_day is null or p_month is null or p_day < 1 or p_day > 31
     or p_month < 1 or p_month > 12 then raise exception 'date_invalide'; end if;
  if exists (select 1 from public.clients where phone = ph) then
    raise exception 'telephone_deja_utilise'; end if;

  select data into s from public.shop where id = 1;
  welcome   := coalesce((s->>'welcome')::int, 0);
  godchild  := coalesce((s->>'godchild')::int, 0);
  godfather := coalesce((s->>'godfather')::int, 0);

  if p_ref is not null and btrim(p_ref) <> '' then
    select * into par from public.clients
      where upper(code) = upper(btrim(p_ref)) or id = btrim(p_ref);
    if not found then raise exception 'code_parrain_inconnu'; end if;
  end if;

  nid   := nextval('public.card_seq')::text;
  ncode := upper(substring(regexp_replace(unaccent_fallback(split_part(btrim(p_name), ' ', 1)),
           '[^A-Za-z]', '', 'g') from 1 for 3)) || '-' || nid;
  total := welcome + case when par.id is not null then godchild else 0 end;

  insert into public.clients (id, name, phone, email, bday_day, bday_month, code,
                              points, lifetime, referred_by,
                              consent_at, notice, marketing, marketing_at)
    values (nid, btrim(p_name), ph, nullif(btrim(coalesce(p_email,'')), ''), p_day, p_month,
            ncode, total, total, par.id,
            now(), coalesce(p_notice, 'v1'), coalesce(p_marketing, false),
            case when p_marketing then now() end);
  insert into public.moves (client_id, amount, points, label, kind)
    values (nid, 0, welcome, 'Bienvenue — carte créée', 'welcome');

  if par.id is not null then
    insert into public.moves (client_id, amount, points, label, kind)
      values (nid, 0, godchild, 'Parrainé par ' || par.name, 'ref');
    update public.clients
      set points = points + godfather, lifetime = lifetime + godfather
      where id = par.id;
    insert into public.moves (client_id, amount, points, label, kind)
      values (par.id, 0, godfather, 'Parrainage de ' || btrim(p_name), 'ref');
  end if;

  insert into public.log (m, client_id) values ('Carte n° ' || nid || ' créée', nid);
  return (select jsonb_build_object('id', id, 'token', token)
          from public.clients where id = nid);
end $$;

-- ── 4 bis. Les droits du client, exercés depuis sa carte ───────────────
-- Rectification (art. 16), effacement (art. 17), opposition au marketing
-- (art. 21) et portabilité (art. 20) : le porteur du lien agit lui-même,
-- sans passer par la boutique.

create or replace function public.update_card(
    p_token uuid, p_name text, p_email text, p_phone text,
    p_day int, p_month int) returns jsonb
  language plpgsql security definer set search_path = public, pg_temp as $$
declare c public.clients; ph text;
begin
  select * into c from public.clients where token = p_token;
  if not found then raise exception 'lien_inconnu'; end if;
  ph := regexp_replace(coalesce(p_phone, c.phone), '[^0-9+]', '', 'g');
  if length(btrim(coalesce(p_name, ''))) < 3 then raise exception 'nom_invalide'; end if;
  if length(ph) < 9 then raise exception 'telephone_invalide'; end if;
  if exists (select 1 from public.clients x where x.phone = ph and x.id <> c.id) then
    raise exception 'telephone_deja_utilise'; end if;
  if p_day is null or p_month is null or p_day < 1 or p_day > 31
     or p_month < 1 or p_month > 12 then raise exception 'date_invalide'; end if;

  update public.clients
     set name = btrim(p_name), phone = ph,
         email = nullif(btrim(coalesce(p_email, '')), ''),
         bday_day = p_day, bday_month = p_month
   where id = c.id;
  insert into public.log (m, client_id) values ('Fiche n° ' || c.id || ' modifiée par le client', c.id);
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.set_marketing(p_token uuid, p_on boolean) returns jsonb
  language plpgsql security definer set search_path = public, pg_temp as $$
declare c public.clients;
begin
  select * into c from public.clients where token = p_token;
  if not found then raise exception 'lien_inconnu'; end if;
  update public.clients
     set marketing = coalesce(p_on, false),
         marketing_at = case when coalesce(p_on, false) then now() end
   where id = c.id;
  insert into public.log (m, client_id) values ('Fiche n° ' || c.id ||
    (case when p_on then ' : offres acceptées' else ' : offres refusées' end), c.id);
  return jsonb_build_object('marketing', coalesce(p_on, false));
end $$;

-- Effacement : la fiche et tout son historique disparaissent (cascade).
-- La boutique n'en garde qu'une trace anonyme, sans nom ni coordonnées.
create or replace function public.delete_card(p_token uuid) returns jsonb
  language plpgsql security definer set search_path = public, pg_temp as $$
declare c public.clients;
begin
  select * into c from public.clients where token = p_token;
  if not found then raise exception 'lien_inconnu'; end if;
  delete from public.clients where id = c.id;
  delete from public.log where client_id = c.id;
  insert into public.log (m) values ('Une fiche a été supprimée à la demande du client');
  return jsonb_build_object('ok', true);
end $$;

-- ── 5. Ce que le boucher peut faire ────────────────────────────────────

create or replace function public.record_purchase(p_id text, p_amount numeric, p_label text)
  returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare ppe numeric; pts int; c public.clients;
begin
  if not public.is_staff() then raise exception 'acces_refuse'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'montant_invalide'; end if;
  select coalesce((data->>'ppe')::numeric, 1) into ppe from public.shop where id = 1;
  pts := round(p_amount * ppe);
  update public.clients set points = points + pts, lifetime = lifetime + pts,
         spent = spent + p_amount, visits = visits + 1, last_visit = current_date
    where id = p_id returning * into c;
  if not found then raise exception 'client_inconnu'; end if;
  insert into public.moves (client_id, amount, points, label, kind)
    values (p_id, p_amount, pts, coalesce(nullif(btrim(p_label),''), 'Achat en boutique'), 'buy');
  insert into public.log (m, client_id) values ('Encaissement ' || to_char(p_amount, 'FM999999.00')
    || ' € — n° ' || p_id, p_id);
  return jsonb_build_object('points', c.points, 'gagnes', pts, 'name', c.name);
end $$;

create or replace function public.use_reward(p_id text, p_points int, p_label text)
  returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare c public.clients;
begin
  if not public.is_staff() then raise exception 'acces_refuse'; end if;
  select * into c from public.clients where id = p_id for update;
  if not found then raise exception 'client_inconnu'; end if;
  if c.points < p_points then raise exception 'solde_insuffisant'; end if;
  update public.clients set points = points - p_points where id = p_id returning * into c;
  insert into public.moves (client_id, amount, points, label, kind)
    values (p_id, 0, -p_points, p_label, 'reward');
  insert into public.log (m, client_id) values ('Récompense « ' || p_label || ' » — n° ' || p_id, p_id);
  return jsonb_build_object('points', c.points);
end $$;

create or replace function public.adjust_points(p_id text, p_points int, p_label text)
  returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare c public.clients;
begin
  if not public.is_staff() then raise exception 'acces_refuse'; end if;
  if p_points = 0 then raise exception 'points_nuls'; end if;
  update public.clients
     set points = points + p_points,
         lifetime = lifetime + greatest(p_points, 0)
   where id = p_id returning * into c;
  if not found then raise exception 'client_inconnu'; end if;
  insert into public.moves (client_id, amount, points, label, kind)
    values (p_id, 0, p_points, coalesce(nullif(btrim(p_label),''), 'Ajustement'), 'adj');
  insert into public.log (m, client_id) values ((case when p_points > 0 then '+' else '' end)
    || p_points || ' points — n° ' || p_id, p_id);
  return jsonb_build_object('points', c.points);
end $$;

create or replace function public.gift_birthday(p_id text)
  returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare g int; c public.clients;
begin
  if not public.is_staff() then raise exception 'acces_refuse'; end if;
  if exists (select 1 from public.moves where client_id = p_id and kind = 'gift'
             and extract(year from t) = extract(year from current_date)) then
    raise exception 'cadeau_deja_offert'; end if;
  select coalesce((data->>'birthday')::int, 0) into g from public.shop where id = 1;
  update public.clients set points = points + g, lifetime = lifetime + g
    where id = p_id returning * into c;
  if not found then raise exception 'client_inconnu'; end if;
  insert into public.moves (client_id, amount, points, label, kind)
    values (p_id, 0, g, 'Cadeau d''anniversaire', 'gift');
  insert into public.log (m, client_id) values ('Cadeau anniversaire — n° ' || p_id, p_id);
  return jsonb_build_object('points', c.points, 'offerts', g);
end $$;

-- Reprise d'un fichier existant (sauvegarde JSON de la version hors ligne).
create or replace function public.import_clients(p_data jsonb)
  returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare c jsonb; h jsonb; n int := 0; maxid bigint := 1000;
begin
  if not public.is_staff() then raise exception 'acces_refuse'; end if;
  for c in select * from jsonb_array_elements(p_data->'clients') loop
    insert into public.clients (id, name, phone, email, bday_day, bday_month, created, code,
                                points, lifetime, spent, visits, last_visit, referred_by,
                                consent_at, notice, marketing)
    values (c->>'id', c->>'name', regexp_replace(c->>'phone', '[^0-9+]', '', 'g'),
            nullif(c->>'email',''),
            -- sauvegarde récente (jour/mois) ou ancienne (date complète)
            coalesce((c->>'bday_day')::smallint,
                     nullif(split_part(coalesce(c->>'bday',''), '-', 3), '')::smallint),
            coalesce((c->>'bday_month')::smallint,
                     nullif(split_part(coalesce(c->>'bday',''), '-', 2), '')::smallint),
            coalesce(nullif(c->>'created','')::date, current_date), c->>'code',
            coalesce((c->>'points')::int, 0), coalesce((c->>'lifetime')::int, 0),
            coalesce((c->>'spent')::numeric, 0), coalesce((c->>'visits')::int, 0),
            (select max((mv->>'t')::date)
               from jsonb_array_elements(coalesce(c->'hist','[]'::jsonb)) mv
              where mv->>'k' = 'buy'), null,
            nullif(c->>'consent_at','')::timestamptz, c->>'notice',
            coalesce((c->>'marketing')::boolean, false))
    on conflict (id) do nothing;
    n := n + 1;
    maxid := greatest(maxid, coalesce((c->>'id')::bigint, 1000));
    for h in select * from jsonb_array_elements(coalesce(c->'hist', '[]'::jsonb)) loop
      insert into public.moves (client_id, t, amount, points, label, kind)
      values (c->>'id', (h->>'t')::date, coalesce((h->>'a')::numeric, 0),
              coalesce((h->>'p')::int, 0), coalesce(h->>'w', '—'), coalesce(h->>'k', 'adj'));
    end loop;
  end loop;
  -- deuxième passe : les parrainages, une fois toutes les fiches présentes
  for c in select * from jsonb_array_elements(p_data->'clients') loop
    if coalesce(c->>'by', '') <> '' then
      update public.clients set referred_by = c->>'by' where id = c->>'id';
    end if;
  end loop;
  perform setval('public.card_seq', maxid + 1, false);
  if p_data ? 'shop' then
    update public.shop set data = (p_data->'shop') - 'pin' where id = 1;
  end if;
  insert into public.log (m) values ('Import de ' || n || ' fiches');
  return jsonb_build_object('imported', n);
end $$;

-- ── 5 bis. Conservation limitée ────────────────────────────────────────
-- Les fiches sans passage depuis la durée fixée dans les réglages
-- (trois ans par défaut) n'ont plus de raison d'être conservées.

create or replace function public.stale_cards(p_years int default null) returns jsonb
  language plpgsql stable security definer set search_path = public, pg_temp as $$
declare y int;
begin
  if not public.is_staff() then raise exception 'acces_refuse'; end if;
  select coalesce(p_years, (data->>'retention_years')::int, 3) into y from public.shop where id = 1;
  return coalesce((select jsonb_agg(jsonb_build_object(
           'id', id, 'name', name, 'last', coalesce(last_visit, created)))
         from public.clients
         where coalesce(last_visit, created) < current_date - (y || ' years')::interval),
         '[]'::jsonb);
end $$;

create or replace function public.purge_stale(p_years int default null) returns jsonb
  language plpgsql security definer set search_path = public, pg_temp as $$
declare y int; n int;
begin
  if not public.is_staff() then raise exception 'acces_refuse'; end if;
  select coalesce(p_years, (data->>'retention_years')::int, 3) into y from public.shop where id = 1;
  create temporary table if not exists _gone (id text) on commit drop;
  delete from _gone;
  with g as (
    delete from public.clients
     where coalesce(last_visit, created) < current_date - (y || ' years')::interval
    returning id)
  insert into _gone select id from g;
  select count(*) into n from _gone;
  delete from public.log where client_id in (select id from _gone);
  if n > 0 then
    insert into public.log (m) values (n || ' fiche(s) supprimée(s) — inactivité de plus de ' || y || ' ans');
  end if;
  return jsonb_build_object('supprimees', n, 'annees', y);
end $$;

-- Purge automatique (facultatif) : activer l'extension pg_cron dans
-- Supabase → Database → Extensions, puis exécuter une fois :
--   select cron.schedule('purge-fidelite', '0 3 1 * *',
--     $q$ select public.purge_stale(); $q$);
-- Sans cela, la purge se lance depuis Réglages → Données personnelles.

-- ── 6. Droits ──────────────────────────────────────────────────────────

-- Le boucher accède aux tables ; le filtre par personnel reste assuré par les
-- politiques RLS ci-dessus (un compte connecté hors personnel ne voit rien).
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete
  on public.shop, public.clients, public.moves, public.log to authenticated;
grant select on public.staff to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Postgres accorde l'exécution des fonctions à PUBLIC par défaut : on retire
-- d'abord, on redonne ensuite, sinon « anon » hérite des fonctions du boucher.
revoke execute on function
    public.record_purchase(text, numeric, text),
    public.use_reward(text, int, text),
    public.adjust_points(text, int, text),
    public.gift_birthday(text),
    public.import_clients(jsonb),
    public.stale_cards(int),
    public.purge_stale(int),
    public.is_staff()
  from public, anon;

grant execute on function public.public_shop(),
                          public.get_card(uuid),
                          public.find_card(text, int, int),
                          public.create_card(text, text, int, int, text, text, boolean, text),
                          public.update_card(uuid, text, text, text, int, int),
                          public.set_marketing(uuid, boolean),
                          public.delete_card(uuid) to anon, authenticated;
grant execute on function public.record_purchase(text, numeric, text),
                          public.use_reward(text, int, text),
                          public.adjust_points(text, int, text),
                          public.gift_birthday(text),
                          public.import_clients(jsonb),
                          public.stale_cards(int),
                          public.purge_stale(int),
                          public.is_staff() to authenticated;
