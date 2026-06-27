# Aceras — Feature Map

*Detailed feature spec for Claude Code reference. Organized by version with implementation-ready detail for v0 and roadmap-level detail for subsequent versions.*

## How to use this doc

Keep this in the repo root or in `/docs/` so Claude Code can read it as context. When starting a new feature session, reference the relevant version section. The v0 section is detailed enough to build from; v1+ sections describe intent so you can plan ahead without locking in specifics.

## Cross-cutting design principles

These apply to every version unless explicitly overridden:

- **Map-first.** The map is the home screen. Every interaction either starts on the map or returns to it. No navigation flow should require the user to leave the map for more than 2-3 taps.
- **Bilingual parity.** Spanish and English are both first-class. Both copy decks are written natively, not translated. The language toggle is always one tap away (header pill on map, also in Profile).
- **Spanish-first defaults.** First-time user sees Spanish by default unless browser locale is clearly English. The language onboarding screen always asks explicitly.
- **Phone-only auth.** No email, no password, no Google sign-in. Phone number + SMS verification only.
- **Privacy by default.** Picker identity never shown to leaver. Leaver shown by first name only. Items purge from DB 30 days after expiration. No backend heatmaps of picker activity.
- **Dark mode default.** Cleaner for map UI, easier outdoor use, lower battery drain.
- **Mobile web (PWA).** Not native. Installable to home screen on iOS and Android. Android-first for install flow testing.
- **15-second post target.** From "Add" button tap to "Posted" confirmation. Friction here = lost supply.
- **No ads, no freemium in v0.** Free for everyone until pilot validates the behavior.

## Tech stack (locked for v0)

- **Frontend:** Next.js 14 (App Router) + TypeScript + Tailwind CSS
- **i18n:** next-intl with `es` (default) and `en` locales
- **Backend:** Supabase (Postgres + PostGIS, Auth, Storage, Realtime)
- **Maps:** Mapbox GL JS (Mapbox Geocoder for address search)
- **SMS auth:** Twilio (via Supabase Auth phone provider)
- **Hosting:** Vercel (auto-deploy from main branch)
- **Notifications:** Web push (OneSignal free tier or roll-your-own with VAPID)

---

# v0 — Foundation

**Goal:** Ship the smallest possible product that lets the core behavior happen end-to-end. Validate whether bilingual map-first curbside discovery works before adding any features.

## v0 Feature: Onboarding (6 screens)

**Screen 1 — Language selection**

- Two large buttons: "Español" and "English"
- Default selection based on browser locale, but always ask explicitly
- Choice saved to user record (created at phone verification step)
- Tap selection → next screen

**Screen 2 — Welcome / three pillars**

- Aceras wordmark
- Three pillar icons + labels:
  - DESCUBRE / DISCOVER — "Cosas gratis cerca de ti, ahora mismo" / "Free items near you, right now"
  - REGALA / GIVE — "Comparte lo que ya no necesitas" / "Share what you don't need"
  - PLANEA TU RUTA / PLAN YOUR ROUTE — "Arma un recorrido por hallazgos cercanos" / "Build a loop through nearby finds"
- "Empezar / Get Started" button bottom

**Screen 3 — Location**

- "Encuentra tu vecindario / Find your neighborhood"
- Two options: "Usar mi ubicación / Use my location" (preferred, triggers iOS/Android permission) OR "Ingresar dirección / Enter an address" (uses Mapbox Geocoder)
- Show map preview with 10-mile radius circle around selected location
- "Continuar / Continue"

**Screen 4 — Phone verification**

- Phone number input with country code (default +1)
- Send SMS via Twilio (through Supabase Auth phone provider)
- 6-digit code entry on next screen
- On success: create user record with `phone`, `language_pref`, `created_at`. No name, no email collected.

**Screen 5 — Notifications opt-in (optional, skippable)**

- "No te pierdas un hallazgo / Don't miss a find"
- Brief explanation
- "Permitir notificaciones / Allow notifications" button triggers browser permission
- "Ahora no / Not now" — skip

**Screen 6 — Drop into map**

- No "you're done" screen. Just navigate directly to the Map view.

## v0 Feature: Bottom navigation (3 slots)

Persistent bottom nav across all screens except onboarding:

1. **Mapa / Map** (home icon) — left
2. **Publicar / Post** (+, larger button) — center
3. **Perfil / Profile** (person icon) — right

List view is accessible via a toggle on the Map screen, not its own nav slot.

## v0 Feature: Map screen (home)

**Header:**
- Left: small ES/EN segmented toggle pill (both visible, active highlighted, tap to switch). Tapping reloads UI strings without page reload.
- Center: Aceras wordmark (small)
- Right: filter icon

**Map area:**
- Mapbox GL JS, dark theme
- Centered on user location at app open (or last-known location if permission denied)
- Pins:
  - **Active pins:** bright color (warm — terracotta/gold). Photo thumbnail in pin.
  - **Ghost pins:** gray, semi-transparent. Shown for items claimed in the last 6 hours. Tappable but show "claimed" status.
- Pin clustering at low zoom levels
- Floating "Center on me" button (bottom right, above nav)
- Floating "List view" toggle button (top right of map area)

**Bottom sheet (collapsed by default):**
- Drag up to expand
- Shows item count: "X hallazgos cerca / X finds nearby"
- Quick filter chips: All / Within 5 mi / Within 10 mi / Last 24h
- Drag up further → expands into list view of nearby items

**Tap pin → pin detail screen (modal slide-up)**

## v0 Feature: List view (toggle from map)

- Chronological list of nearby active items
- Each card: photo thumbnail, title, distance, posted-time, leaver first name
- Tap card → pin detail screen
- Pull-to-refresh
- "Volver al mapa / Back to map" button top right

## v0 Feature: Pin detail screen

Triggered by tapping a pin on map or a card in list view:

- Full-screen photo
- **Approximate address** — street + cross street, NOT exact house number. Exact number revealed only after picker taps "Heading there"
- Leaver first name only
- Posted X hours ago
- Distance from picker
- Action buttons (large, 44pt min, thumb-friendly):
  - **Voy en camino / Heading there** — marks picker intent, sends notification to leaver, reveals exact address to the picker
  - **Aún está / Still here** — community confirmation
  - **Se acabó / Gone** — community archive signal
- **Compartir / Share** — opens native share sheet with deep link to this pin (includes Open Graph metadata for nice WhatsApp/SMS previews)
- **Agregar a mi ruta / Add to my route** — adds to picker's current trip cart

## v0 Feature: Post flow

Triggered by tapping the (+) button in bottom nav. Target: ≤15 seconds from tap to posted.

1. **Camera opens immediately.** No "what type" prompt — everything is Free in v0. Option to use camera roll if user prefers.
2. **Photo captured.** Required. Single photo only in v0 (multi-photo deferred to v1).
3. **Location pin confirmation screen.** Map shown with pin auto-placed at user's GPS location. User can drag pin to fine-tune to actual curb position.
4. **Optional title.** One-line text input with placeholder ("Mesa, silla, etc.")
5. **Submit button.** Writes to DB.
6. **Confirmation toast:** "¡Publicado! Avisamos a la gente cerca. / Posted! We're notifying people nearby."
7. **Auto-redirect to map** showing the new pin.

**Auto-expiration:** 24 hours from posted_at, unless leaver manually extends (deferred to v1) or marks gone.

## v0 Feature: Status marking

Three paths for an item to reach "gone" status:

1. **Picker confirms pickup** — after tapping "Heading there," picker can confirm "Recogí esto / I picked this up" from a follow-up notification or by returning to the pin detail. Primary path — most authoritative.
2. **Leaver marks gone** — one-tap from leaver's post notification or their My Posts list in Profile.
3. **Community backstop** — any user can mark "Se acabó / Gone" from pin detail. Two such reports = auto-archive.

When item moves to "gone" (any path), leaver receives notification: "Tu artículo fue recogido / Your item was picked up." Notification never reveals picker identity.

## v0 Feature: Notifications

- **Opt-in only** (from onboarding Screen 5, or Profile settings)
- **Picker-side:** "New items posted within X miles" — batched, max one notification per 30 minutes
- **Leaver-side:** "Someone is heading there" (when picker taps Heading There) and "Your item was picked up" (when item marked gone)
- **Quiet hours configurable** in Profile
- **Default off** — let user choose to opt in, don't push

Implementation: Web Push API with VAPID keys, or OneSignal free tier as wrapper. Service worker registered in Next.js app.

## v0 Feature: Route mode

Picker-driven, not automatic. The picker selects which pins they want, then the app builds a route through them.

**Flow:**
1. Picker taps "Add to my route" on multiple pin detail screens
2. Floating trip cart appears at bottom of map: "3 hallazgos en tu ruta · 18 min / 3 finds in your route · 18 min"
3. Picker can expand cart to review/remove selected pins
4. Tap "Construir ruta / Build route" → generates optimized loop through selected pins (Mapbox Directions API)
5. Route screen: ordered list of stops with photo, distance, total estimated drive time
6. Tap "Empezar navegación / Start navigation" → deep link to native Maps app (Apple Maps on iOS, Google Maps on Android) with the route loaded

**Edge case:** if a pin in the trip gets claimed by someone else mid-trip, picker receives notification ("El sofá en Foothill se acabó / The couch at Foothill is gone") with option to swap in a nearby alternative without rebuilding entire route.

## v0 Feature: Share button

On every pin detail screen. Generates a deep link to that specific pin. Tap → native iOS/Android share sheet → user shares to WhatsApp, SMS, or any other app.

Implementation:
- Each pin has a permalink URL: `aceras.co/p/{pin_id}`
- Open Graph metadata: og:image (photo), og:title (item title), og:description (location + posted time)
- When recipient taps link, opens Aceras directly to that pin detail screen

## v0 Feature: Profile screen

- **First name** (optional, editable)
- **Phone** (read-only, masked: +1 ••• ••• 1234)
- **Language toggle** (immediate switch, no restart)
- **Notification settings** (toggle types + quiet hours)
- **Mis publicaciones / My posts** — history of items I've posted (active, expired, gone)
- **Mis recogidas / My pickups** — history of items I've claimed
- **About / Privacy / Terms** (links)
- **Logout**

## v0 Data model (minimal)

```
users
  id (uuid, pk)
  phone (text, unique)
  language_pref (text: 'es' | 'en')
  first_name (text, nullable)
  created_at (timestamp)

items
  id (uuid, pk)
  leaver_id (uuid, fk to users)
  photo_url (text)
  title (text, nullable)
  location (geography(POINT, 4326))  -- PostGIS
  address_approx (text)  -- cached: street + cross street
  address_exact (text)   -- only revealed to picker after "Heading there"
  status (text: 'active' | 'claimed' | 'gone' | 'expired')
  posted_at (timestamp)
  expires_at (timestamp)  -- default posted_at + 24h
  picked_up_at (timestamp, nullable)

item_signals
  id (uuid, pk)
  item_id (uuid, fk to items)
  reporter_id (uuid, fk to users)
  signal_type (text: 'heading_there' | 'still_here' | 'gone')
  created_at (timestamp)

notifications
  id (uuid, pk)
  user_id (uuid, fk to users)
  item_id (uuid, fk to items, nullable)
  type (text)
  sent_at (timestamp)
  opened_at (timestamp, nullable)

reports
  id (uuid, pk)
  item_id (uuid, fk to items)
  reporter_id (uuid, fk to users)
  reason (text)
  status (text: 'pending' | 'reviewed' | 'dismissed')
  created_at (timestamp)
```

**Key queries:**
- Active pins within radius: `SELECT * FROM items WHERE status = 'active' AND ST_DWithin(location, $user_loc, $radius_meters)`
- Ghost pins (recently claimed): `SELECT * FROM items WHERE status IN ('claimed', 'gone') AND picked_up_at > NOW() - INTERVAL '6 hours' AND ST_DWithin(location, $user_loc, $radius_meters)`

## v0: What's explicitly NOT in scope

If you find yourself building any of these, stop:

- Categories or filtering by item type
- Multi-photo posts
- Long-form descriptions
- Profile photos
- Chat or messaging
- Ratings / reviews
- Reputation scores
- Verified picker tiers
- Take-it-all listings
- Garage sales
- Categories
- Private groups / communities
- Family accounts
- Shared trips
- Computer vision
- Any paid features
- Sponsored pins
- Pickup analytics
- Address concealment toggle (beyond the default approximate/exact reveal)

---

# v1 — Listing variety + light coordination

**Goal:** Address the friction points pilot users surface. Add lightweight coordination tools.

**Estimated effort:** ~70-110 hours

## v1 Features

- **Multi-photo posts** — up to 4 photos per item, swipeable in pin detail
- **Longer descriptions** — optional text field, 200 char limit
- **Categories and filtering** — Furniture, Electronics, Kids, Home Goods, Tools, Clothing, Sports, Appliances, Misc. Filter chips on map and list view.
- **Optional profile photos** — never required, always optional. Used only on picker confirmation UI for leaver trust (not in pin detail).
- **Micro-messages (constrained, pin-specific)** — short single messages tied to a pin. Examples: "Voy en 5 min / 5 min away" picker→leaver, "Tomé el escritorio, quedan las sillas / Took the desk, chairs still there" picker→all interested pickers. Constrained: max 60 chars, single message per user per pin, no free-form chat. Expires with the pin.
- **Better Spanish/English copy polish throughout** — informed by pilot feedback

---

# v1.5 — Trust infrastructure

**Goal:** Build the foundational trust layer that unlocks v2's "Take it all" feature.

**Estimated effort:** ~80-120 hours

## v1.5 Features

- **Identity-verified picker tier** — pickers can opt into ID verification (Persona, Stripe Identity, or similar). Verified status is shown as a badge.
- **Two-way ratings/reviews** — after a confirmed pickup, both parties can rate (1-5) and leave a short comment.
- **Reputation score** — aggregated rating for verified pickers and active leavers.
- **Printable sticker + QR code verification system** — leavers can generate a printable sticker for each item with a unique QR pointing at the pin. Item announces itself to the street; neighbors can scan to verify.
- **Light moderation tooling** — admin dashboard for handling reports, banning bad actors, archiving flagged content.

---

# v2 — "Take it all" listings

**Goal:** Capture the "I just want this gone" use case that 1-800-GOT-JUNK currently owns at $300-800 per visit.

**Estimated effort:** ~100-150 hours

## v2 Features

- **New listing type: "Take it all"** — leaver posts a pile (single photo or up to 4 photos), description of contents, asks for whole-pile pickup. Different visual treatment on map (special pin color or icon).
- **Verified-picker-only claims** — only verified pickers (from v1.5) can claim a Take-it-all listing.
- **Before/after photo confirmation** — picker uploads "before" photo on arrival, "after" photo confirming pile cleared.
- **Listing fee** — leaver pays $20-50 to post (Stripe). Or zero-cost listing with B2B claim mechanism.
- **B2B claim** — junk haulers, donation pickup services can pay a subscription to be eligible for Take-it-all listings, with priority over individual pickers.
- **Address concealment / fuzzy location** — show item at curb area only, exact address revealed only on claim confirmation. Privacy feature for sensitive listings.

---

# v2.5 — B2B revenue layer

**Goal:** Unlock the primary monetization tier. Local-intent advertising and B2B subscriptions, no display ads.

**Estimated effort:** ~80-120 hours

## v2.5 Features

- **Estate sale company subscriptions** — flat monthly fee ($100-500) for promoted listings on the map
- **Junk hauler / donation pickup integrations** — Goodwill, Habitat ReStore, junk haulers compete to claim full-pile listings
- **Sponsored / promoted pins** — local businesses (thrift stores, antique stores, moving companies, junk haulers) pay for visibility on map
- **Boost / promoted individual posts** — leavers and small B2B pay to move a post to the top of map and feed for X hours
- **Pickup analytics for leavers** — views, time-to-pickup, success rate by category and time of day. Could be premium tier for individuals; included for B2B.
- **Civic / sustainability partnerships** — municipalities pay for white-labeled or co-branded versions tied to waste-reduction goals

---

# v3 — Richer coordination

**Goal:** Solve the multi-user coordination patterns that v0 deferred to "share via WhatsApp."

**Estimated effort:** ~100-150 hours

## v3 Features

- **Shared trips** — send your planned route URL to a co-picker. They open it, see your selected pins, can claim items or just see what you're doing. Solves "Dad and I are splitting up Saturday."
- **Family accounts** — multiple phones, one shared map view. Mom and adult kid see each other's pins, posts, and routes.
- **Private circles (closed groups)** — Buy Nothing-style. A church group, an extended family, a neighborhood block — small group sees each other's posts first or only.
- **Scheduled / bulk posts for power leavers** — downsizers and estate organizers schedule multiple items in advance.

---

# v3+ — Speculative / opportunistic

**Goal:** Long-tail features to consider based on pilot and v1-v2 learnings. Don't commit to any of these without strong signal.

## v3+ Possibilities

- **Garage sales as separate listing type** — date ranges, multi-day events, route planning for Saturday-morning garage-sale circuits
- **Expansion to a second metro** (only after density and economics work in metro #1)
- **Computer vision for posting** — AI auto-detects object type, generates title, estimates value
- **Picker premium tier** — expanded viewing radius (25+ miles), multi-location saving, advanced filters
- **Police outreach portal** — verification mechanism for officers responding to suspicious-pickup calls. Built quietly, never marketed to picker users, no backend data access for law enforcement.

---

## Build order priority (within v0)

Recommended Claude Code session sequence:

1. **Project skeleton** — Next.js + TS + Tailwind + next-intl + Vercel deploy (hello world bilingual)
2. **Supabase setup** — project created, env vars wired, base schema migrated
3. **Phone auth flow** — Twilio + Supabase Auth, login/signup screens with i18n
4. **Onboarding flow** — 6 screens (language, welcome, location, phone, notifications, drop-in)
5. **Post flow** — camera, location, title, submit. Photo upload to Supabase Storage. Item written to DB with PostGIS point.
6. **Map view** — Mapbox integration, active pins, ghost pins, clustering, "center on me" button
7. **Pin detail** — full-screen photo, approximate address, action buttons, share button
8. **Status marking** — three paths to gone, leaver notification on pickup
9. **List view** — toggle from map, chronological cards
10. **Notifications** — service worker, web push, opt-in flow, batching logic
11. **Route mode** — trip cart, route building via Mapbox Directions, native maps deep link
12. **Profile screen** — language toggle, my posts, my pickups, settings

Each step is one focused Claude Code session. Don't combine steps in a single prompt.

## How to feed this to Claude Code

When starting a session for a specific feature:

> Reference `/docs/aceras_feature_map.md`. Build the [Post flow] feature for v0 per the spec in that doc. Use the existing Supabase, Mapbox, and Twilio setup. Don't add anything not in the v0 scope.

Or for the initial CLAUDE.md generation, point Claude Code at this doc as the primary context: "Read /docs/aceras_feature_map.md and generate a CLAUDE.md that summarizes the project context, tech stack, and v0 scope for future sessions."
