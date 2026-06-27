-- Enable PostGIS for geospatial queries
create extension if not exists postgis;

-- users
-- Note: auth.users is managed by Supabase Auth. This table extends it with app-specific fields.
create table public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  phone       text unique not null,
  language_pref text not null default 'es' check (language_pref in ('es', 'en')),
  first_name  text,
  created_at  timestamptz not null default now()
);

alter table public.users enable row level security;

create policy "Users can read and update their own record"
  on public.users for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- items
create table public.items (
  id             uuid primary key default gen_random_uuid(),
  leaver_id      uuid not null references public.users(id) on delete cascade,
  photo_url      text not null,
  title          text,
  location       geography(point, 4326) not null,
  address_approx text not null,
  address_exact  text not null,
  status         text not null default 'active'
                   check (status in ('active', 'claimed', 'gone', 'expired')),
  posted_at      timestamptz not null default now(),
  expires_at     timestamptz not null default now() + interval '24 hours',
  picked_up_at   timestamptz
);

alter table public.items enable row level security;

create policy "Authenticated users can read items"
  on public.items for select
  using (auth.uid() is not null);

create policy "Leavers can insert their own items"
  on public.items for insert
  with check (auth.uid() = leaver_id);

create policy "Leavers can update their own items"
  on public.items for update
  using (auth.uid() = leaver_id);

create index items_location_idx on public.items using gist (location);
create index items_status_expires_idx on public.items (status, expires_at);

-- item_signals (heading_there, still_here, gone)
create table public.item_signals (
  id          uuid primary key default gen_random_uuid(),
  item_id     uuid not null references public.items(id) on delete cascade,
  reporter_id uuid not null references public.users(id) on delete cascade,
  signal_type text not null check (signal_type in ('heading_there', 'still_here', 'gone')),
  created_at  timestamptz not null default now(),
  unique (item_id, reporter_id, signal_type)
);

alter table public.item_signals enable row level security;

create policy "Authenticated users can read signals"
  on public.item_signals for select
  using (auth.uid() is not null);

create policy "Authenticated users can insert signals"
  on public.item_signals for insert
  with check (auth.uid() = reporter_id);

create index item_signals_item_idx on public.item_signals (item_id);

-- notifications
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  item_id    uuid references public.items(id) on delete set null,
  type       text not null,
  sent_at    timestamptz not null default now(),
  opened_at  timestamptz
);

alter table public.notifications enable row level security;

create policy "Users can read their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create index notifications_user_idx on public.notifications (user_id, sent_at desc);

-- reports
create table public.reports (
  id          uuid primary key default gen_random_uuid(),
  item_id     uuid not null references public.items(id) on delete cascade,
  reporter_id uuid not null references public.users(id) on delete cascade,
  reason      text not null,
  status      text not null default 'pending'
                check (status in ('pending', 'reviewed', 'dismissed')),
  created_at  timestamptz not null default now()
);

alter table public.reports enable row level security;

create policy "Users can insert reports"
  on public.reports for insert
  with check (auth.uid() = reporter_id);

-- Auto-archive items with 2+ "gone" signals
create or replace function public.check_gone_signals()
returns trigger language plpgsql security definer as $$
begin
  if new.signal_type = 'gone' then
    if (
      select count(*) from public.item_signals
      where item_id = new.item_id and signal_type = 'gone'
    ) >= 2 then
      update public.items set status = 'gone' where id = new.item_id and status = 'active';
    end if;
  end if;
  return new;
end;
$$;

create trigger on_gone_signal
  after insert on public.item_signals
  for each row execute function public.check_gone_signals();

-- Create public.users record when auth.users is created (phone auth)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.users (id, phone)
  values (new.id, coalesce(new.phone, ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
