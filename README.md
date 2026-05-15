# Wreckfest Race Log

A keyboard-first race log for the racing game **Wreckfest**. The app is designed
to be ALT+TABbed into between races: hit `Q`, type the track name, fill four
fields, hit `Enter`. Total interaction time should be under ten seconds.

---

## Tech stack

- **Frontend** — Vue 3 (Options API), Vue Router, Tailwind CSS, Vite
- **Backend** — Supabase (Postgres + Auth)
- **Hosting** — GitHub Pages (static site)
- **CI/CD** — GitHub Actions

---

## Setup instructions

### 1. Clone & install

```bash
git clone <your-fork-url> wreckfest-race-tracker
cd wreckfest-race-tracker
npm install
```

### 2. Supabase setup (step-by-step)

1. Go to <https://supabase.com> and create a new project.
2. In the Supabase dashboard, open **SQL Editor → New query**.
3. Paste the contents of [`supabase/schema.sql`](supabase/schema.sql) and run
   it. This creates the `tracks`, `track_variations`, `vehicles`, `races`, and
   `goals` tables and enables Row Level Security so each user only sees their
   own races and goals.
4. In a new query, paste the contents of [`supabase/seed.sql`](supabase/seed.sql)
   and run it. This populates the catalogue with every base-game Wreckfest
   track (38 tracks / 98 route variations) and vehicle (84 vehicles), each
   with a thumbnail URL pulled from the Wreckfest fandom wiki. The seed is
   idempotent — re-running updates names and image URLs without touching
   user data.
5. Open **Authentication → Providers** and make sure **Email** is enabled.
6. (Recommended for local dev) Open **Authentication → Providers → Email**
   and turn **Confirm email** OFF. With it on, users must click a
   verification link before they can sign in — fine for production, annoying
   while you're testing. The login page handles both cases either way.
7. From **Project Settings → API**, copy the **Project URL** and the
   **anon public** key — you'll paste these into `.env` next.

> Never commit the `service_role` key. The frontend only ever uses the
> `anon` key; per-row access is enforced server-side by RLS policies.

### 3. Environment variables

Create a `.env` file in the repo root from the template:

```bash
cp .env.example .env
```

Then fill in:

| Variable | Description |
| --- | --- |
| `VITE_SUPABASE_URL` | The Project URL from Supabase. |
| `VITE_SUPABASE_ANON_KEY` | The anon key from Supabase. |
| `VITE_BASE_PATH` | `/` for local dev. For GitHub Pages, set to `/<repo-name>/` if hosting under a project subpath. |

### 4. Running locally

```bash
npm run dev
```

The dev server runs on <http://localhost:5173>.

To preview a production build:

```bash
npm run build
npm run preview
```

---

## Deployment (GitHub Actions → GitHub Pages)

The workflow at [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)
builds the site and publishes the `dist/` folder to GitHub Pages on every push
to `main`.

### One-time setup

1. In your GitHub repo, open **Settings → Pages** and set **Source** to
   **GitHub Actions**.
2. Open **Settings → Secrets and variables → Actions** and add two
   **secrets**:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
3. Add a **variable** (not secret) called `VITE_BASE_PATH`:
   - For a project page (`https://you.github.io/wreckfest-race-tracker/`),
     set it to `/wreckfest-race-tracker/`.
   - For a user/org page, set it to `/` (or skip the variable entirely).
4. Push to `main`. GitHub Actions will build and publish.

---

## Project structure

```
.
├── .github/workflows/deploy.yml   GitHub Actions: build + deploy to Pages
├── supabase/schema.sql            Postgres schema + RLS policies
├── index.html                     Vite entry
├── vite.config.js                 Vite config (reads VITE_BASE_PATH)
├── tailwind.config.js             Tailwind setup (dark mode via class)
└── src/
    ├── main.js                    App bootstrap (waits for session before mount)
    ├── App.vue                    Layout + global "Q" shortcut
    ├── style.css                  Tailwind entry
    ├── router/index.js            Routes + auth guard
    ├── services/                  ALL Supabase calls live here
    │   ├── supabase.js            Shared client
    │   ├── authService.js
    │   ├── trackService.js
    │   ├── vehicleService.js
    │   ├── raceService.js
    │   ├── goalService.js
    │   └── statsService.js
    ├── stores/                    Lightweight reactive stores
    │   ├── authStore.js
    │   ├── prefsStore.js          Persists last vehicle / tuning to localStorage
    │   ├── quickAddStore.js       Controls the Quick Add modal
    │   └── toastStore.js
    ├── utils/
    │   ├── timeFormat.js          Parse "1:23.456" ↔ ms
    │   ├── slug.js
    │   ├── debounce.js
    │   └── exportImport.js
    ├── components/                Reusable UI (one responsibility each)
    │   ├── NavBar.vue
    │   ├── FloatingQuickAddButton.vue
    │   ├── ToastContainer.vue
    │   ├── QuickAddModal.vue
    │   ├── TrackVariationPicker.vue
    │   ├── RaceForm.vue
    │   ├── RaceRow.vue
    │   ├── InlineAddRaceRow.vue
    │   └── TrackCard.vue
    └── pages/                     Route-level views
        ├── LoginPage.vue
        ├── TrackListPage.vue
        ├── TrackDetailPage.vue
        └── StatsPage.vue
```

---

## Design decisions

- **Vue Options API.** All components use `data() / computed / methods /
  lifecycle`. No `<script setup>` or Composition API.
- **Service layer for Supabase.** Components never call Supabase directly —
  they import a function from `src/services/`. This keeps the network surface
  in one place and makes mocking trivial later.
- **Lightweight reactive stores instead of Pinia/Vuex.** The shared state
  (auth, prefs, modal flag, toasts) is small. Plain `reactive({})` modules
  with named mutator functions keep dependencies low and cognitive overhead
  smaller than a full store library.
- **Hash-based router.** GitHub Pages doesn't do SPA fallback for arbitrary
  paths. Hash history (`#/track/...`) sidesteps that without needing a
  custom 404 page.
- **Times stored as integer milliseconds.** Avoids float comparison bugs and
  makes "biggest improvement" math trivial. The UI parses a forgiving
  `M:SS.mmm` / `SS.mmm` format so the user never has to count separators.
- **`Q` as a global shortcut.** Bound on the document level in `App.vue`,
  but suppressed when the user is typing in any input/textarea/select. The
  modal also handles `Esc`, `Enter`, and `Ctrl+Enter` (in the textarea) for
  full keyboard control.
- **Last vehicle / tuning persisted in `localStorage`.** Surveys race-night
  reality: the user grinds the same setup across many runs, so each new
  Quick Add starts pre-filled with their last choice.
- **RLS, not application checks, gates per-user data.** The frontend runs
  with the anon key only; Postgres policies guarantee a user can never read
  another user's races even if the client is malicious.

---

## Known limitations

- **Catalogue (tracks, variations, vehicles) is shared and read-only from
  the UI.** Add new entries by inserting rows in Supabase. A full admin UI
  is out of scope for the race-night MVP.
- **JSON import re-uses existing `track_variation_id` / `vehicle_id`
  values.** Importing into a different Supabase project (with different IDs)
  won't link rows correctly. Treat export as backup, not portability.
- **Stats computed client-side.** Fine up to a few thousand races per user;
  push to a SQL view if you ever exceed that.
- **No offline mode.** ALT+TABbing requires connectivity to save races.

---

## Future improvements

- Catalogue management UI (CRUD for tracks, variations, vehicles).
- Inline charts of lap-time progression on the track detail page.
- Per-vehicle PB filtering on the track detail page.
- Per-user track image uploads to Supabase Storage.
- PWA install + offline write queue with background sync.
- Optional Supabase-side preferences sync (in addition to `localStorage`)
  so a fresh device picks up your last vehicle / tuning automatically.
