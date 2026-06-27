# Aceras — Claude Code Context

Bilingual (Spanish-first) PWA for finding, routing to, and posting free curbside items on a map. Full feature spec and roadmap: `/docs/aceras_feature_map.md`.

## Tech stack

- **Frontend:** Next.js 14 (App Router) + TypeScript + Tailwind CSS
- **i18n:** next-intl v4 — `es` default locale, `en` secondary. All UI strings go through message files (`/messages/es.json`, `/messages/en.json`). Locale routing via middleware at `src/middleware.ts`; pages live under `src/app/[locale]/`.
- **Backend:** Supabase — Postgres + PostGIS (geospatial), Auth (phone/SMS only), Storage (item photos), Realtime
- **Maps:** Mapbox GL JS + Mapbox Geocoder
- **SMS auth:** Twilio via Supabase Auth phone provider
- **Notifications:** Web Push (VAPID / service worker)
- **Hosting:** Vercel — auto-deploys from `main`

## Design principles (non-negotiable)

- Map is the home screen. Every flow returns to it within 2-3 taps.
- Spanish and English are first-class. Never machine-translate — write both natively.
- Phone-only auth. No email, no OAuth.
- Privacy by default: pickers anonymous to leavers, exact address only revealed after "Heading there."
- Dark mode default.
- Mobile-first PWA (not native app).
- Post target: ≤15 seconds from tap to posted.

## v0 scope (what to build now)

See `/docs/aceras_feature_map.md` for full detail. Summary:

1. Supabase setup — schema, env vars
2. Phone auth — Twilio + Supabase Auth, login/signup with i18n
3. Onboarding — 6 screens (language → welcome → location → phone → notifications → map)
4. Post flow — camera, location pin, optional title, submit, photo → Supabase Storage, item → DB
5. Map view — Mapbox, active pins, ghost pins, clustering, center-on-me
6. Pin detail — photo, approximate address, action buttons, share
7. Status marking — 3 paths to gone, leaver notification
8. List view — toggle from map, chronological cards
9. Notifications — service worker, web push, batching
10. Route mode — trip cart, Mapbox Directions, native maps deep link
11. Profile — language toggle, my posts, my pickups, settings

**Do not build anything listed under "What's explicitly NOT in scope" in the feature map.**

## Data model (v0)

```sql
users        — id, phone, language_pref ('es'|'en'), first_name, created_at
items        — id, leaver_id, photo_url, title, location (PostGIS POINT), address_approx,
               address_exact, status ('active'|'claimed'|'gone'|'expired'), posted_at, expires_at, picked_up_at
item_signals — id, item_id, reporter_id, signal_type ('heading_there'|'still_here'|'gone'), created_at
notifications — id, user_id, item_id, type, sent_at, opened_at
reports      — id, item_id, reporter_id, reason, status ('pending'|'reviewed'|'dismissed'), created_at
```

Key PostGIS query pattern:
```sql
SELECT * FROM items
WHERE status = 'active'
  AND ST_DWithin(location, ST_SetSRID(ST_MakePoint($lon, $lat), 4326)::geography, $radius_meters)
```

## Environment variables

```
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
NEXT_PUBLIC_MAPBOX_TOKEN
```
Twilio credentials are configured in the Supabase dashboard, not in app env.

## How to start a feature session

> Reference `/docs/aceras_feature_map.md`. Build the [feature name] feature for v0 per the spec in that doc. Don't add anything outside v0 scope.
