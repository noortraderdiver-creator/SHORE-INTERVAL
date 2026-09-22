# Shore Interval — going live

This is the real, deployable version of the site — GitHub for the code, Supabase for the database, Vercel for hosting. Every feature you've built (house stays, dive sites, dive shops, the community forum, booking requests, host-guest messaging, membership approval, the admin dashboard) is wired to a real Postgres database instead of the browser-only preview storage.

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) → New project. Any name/region is fine — save the database password somewhere.
2. Once it's ready, open **SQL Editor** → New query.
3. Paste in the entire contents of `supabase/schema.sql` and click **Run**. This creates one table (`records`) that backs every content type in the app, and seeds it with the starter listings, dive sites, dive shops, and forum threads you already had.
4. Go to **Settings → API Keys** (this may show as "API" or have a "Legacy API keys" tab depending on when your project was created — see note below).
5. Copy two values:
   - **Project URL**
   - The **secret key** (`sb_secret_...`) or, on older projects, the **service_role** key. Either works the same way for this app.

The secret/service_role key can do anything to your database, so it must only ever go into Vercel's environment variables — never into the frontend code or a public repo.

## 2. Push the code to GitHub

The easiest way, no terminal required:
1. Create a new empty repo at [github.com/new](https://github.com/new).
2. On the empty repo page, click **uploading an existing file**, drag in everything from this folder (`api/`, `public/`, `supabase/`, `package.json`, etc.), and commit.

## 3. Deploy on Vercel

1. Go to [vercel.com/new](https://vercel.com/new), sign in with GitHub, and import the repo.
2. Before clicking Deploy, add three **Environment Variables**:
   | Name | Value |
   |---|---|
   | `SUPABASE_URL` | your Project URL from step 1 |
   | `SUPABASE_SERVICE_ROLE_KEY` | your secret/service_role key from step 1 |
   | `ADMIN_PASSWORD` | a password you make up — this protects the admin dashboard |
3. Click **Deploy**. You'll get a live URL like `surface-interval.vercel.app`.
4. Open it. Listings, dive sites, dive shops, and forum threads should load from your database. Every future `git push` auto-redeploys.

## How the backend is structured

Rather than a separate database table for every feature, everything (listings, dive sites, dive shops, forum threads, bookings, messages, membership applications) lives in **one flexible table** called `records`, with a `collection` column telling them apart. Two API files handle all of it:

- `api/[collection]/index.js` — list everything in a collection, or create a new item
- `api/[collection]/[id].js` — update or delete one item

So `/api/listings` lists house stays, `/api/sites` lists dive sites, `/api/bookings/bk-123` updates one booking request, and so on — one small set of code instead of seven near-identical ones. If any single feature outgrows this later, it can be split into its own proper table without changing how the rest of the app talks to it.

## What's real now, and what still isn't

**Now backed by a real, persistent database:**
- House listings, with host-set pricing, extra fees, and blocked/unavailable dates
- Dive sites and dive shops, including the member-submitted pending queue
- The community forum (threads and replies)
- Booking requests and host approval
- Host ↔ member messaging per listing
- Membership applications and cert-photo review

**Still not real — worth knowing about:**
- **No per-member login.** Joining still just records a name/email/cert photo with no password — there's no session proving someone actually owns an email address. This mainly matters if you want members to securely access things across devices; it doesn't expose other people's data (see below).
- **No payments.** Approving a booking just marks it "approved" — no money moves. See below.
- **No real cert verification** beyond a human looking at the uploaded photo.

## Admin access is now password-protected

Approving members, editing or deleting listings/sites/shops/bookings, and reading anything with personal data in it (applications with cert photos, bookings with guest emails, messages) all now require the `ADMIN_PASSWORD` you set in Vercel. This is enforced on the server, not just hidden in the UI — someone would need the actual password to change or read that data, not just knowledge of the site's URL.

What this password gate does *not* do: it's a single shared password, not individual accounts, so you can't yet tell which admin did what, and everyone who has the password can do everything. That's a reasonable stopgap for one person (or a small trusted team) running the site; a multi-admin setup with per-person logins is part of the "real auth" step below.

## Adding real payments (Stripe Connect)

This is the natural next step once bookings are flowing. The shape of it:

1. **Stripe Connect** lets each host have their own connected account, so payouts go directly to them minus your platform fee (the 12% mentioned in the host application) — Stripe handles the split automatically.
2. When a host **approves** a booking request, that's the moment to create a Stripe Checkout session for the guest (nightly rate + extra fees) instead of just flipping the status, and only mark the booking fully confirmed once payment succeeds (via a Stripe webhook).
3. **Refunds** follow whatever policy you set (e.g. full refund 7+ days out, partial within 7 days, none within 24 hours) — Stripe's refund API handles the actual money movement; your code just decides how much based on how close to check-in the cancellation happens.
4. This needs Stripe's own onboarding flow for hosts (so they can receive payouts) and a webhook endpoint (`api/stripe-webhook.js`) to confirm payments — a meaningful chunk of work, but well-documented in [Stripe Connect's docs](https://stripe.com/docs/connect).

## Locking it down further

The admin password closes the biggest hole (anyone editing or reading everything), but two things are still worth doing as the site grows:

1. **Add real member accounts.** [Supabase Auth](https://supabase.com/docs/guides/auth) is free and built into the same project — email/password or magic-link sign-in. This lets members securely access their own applications/listings from any device, rather than the current lightweight "remember me in this browser" approach.
2. **Give each host their own login** rather than sharing one admin password, once you have more than one or two people who need to approve things.

## Editing the design

Everything visual is in the `<style>` block at the top of `public/index.html`, with the palette defined once as CSS variables near the top (`--abyss`, `--reef`, `--sand`, etc.).
