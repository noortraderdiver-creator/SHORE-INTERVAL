-- Surface Interval — full schema
-- Run this once in your Supabase project's SQL editor
-- (Dashboard → SQL Editor → New query → paste this whole file → Run)
--
-- One generic table backs every content type in the app (listings, dive
-- sites, dive shops, forum threads, bookings, messages, and membership
-- applications). Each row belongs to a "collection" (like a table name)
-- and stores its fields as JSON in `data`, plus a top-level `status` for
-- anything that goes through an approve/reject flow.
--
-- This trades some relational strictness for being able to add new
-- content types later without a migration — reasonable for where this
-- project is now. If you outgrow it, each collection can be split into
-- its own proper table later without changing the app's data shape much.

create table if not exists records (
  collection text not null,
  id text not null,
  data jsonb not null default '{}'::jsonb,
  status text,
  created_at timestamptz default now(),
  primary key (collection, id)
);

create index if not exists records_collection_created_idx
  on records (collection, created_at desc);

-- Row Level Security is on by default in Supabase. These policies allow
-- open read/write with the anon key, matching how the app currently works
-- (no real user accounts yet — see README "Locking it down before real
-- users show up"). Tighten these once real authentication is in place.
alter table records enable row level security;

create policy "public read" on records for select using (true);
create policy "public insert" on records for insert with check (true);
create policy "public update" on records for update using (true);
create policy "public delete" on records for delete using (true);

-- ---------- seed data ----------

insert into records (collection, id, data, status, created_at) values
('listings','si-1','{"title":"Dock house on the house reef","location":"Bonaire, Dutch Caribbean","region":"Caribbean","site":"Salt Pier","viz":30,"depth":24,"price":118,"hostCert":"Divemaster / Pro","desc":"Shore-entry dive house two minutes from Salt Pier. Wake up, walk in — no boat needed most mornings.","amenities":["Tank storage","Rinse station","Shore entry","Gear drying room"],"fees":[{"label":"Cleaning fee","amount":20},{"label":"Tank-fill fee","amount":8}],"hostName":"Marco T.","hostEmail":"marco@example.com","blockedDates":[]}', null, now()),
('listings','si-2','{"title":"Room above the compressor shed","location":"Dahab, Egypt","region":"Red Sea","site":"Blue Hole","viz":25,"depth":40,"price":64,"hostCert":"Rescue","desc":"Simple room attached to a family-run fill station. Quiet during the week, full of stories on weekends.","amenities":["Compressor access","Tank storage","Rinse station"],"fees":[{"label":"Cleaning fee","amount":10},{"label":"Tank-fill fee","amount":6}],"hostName":"Yuki S.","hostEmail":"yuki@example.com","blockedDates":[]}', null, now()),
('listings','si-3','{"title":"Stilt house over the lagoon","location":"Raja Ampat, Indonesia","region":"Indo-Pacific","site":"Cape Kri","viz":20,"depth":35,"price":145,"hostCert":"Divemaster / Pro","desc":"Wooden stilt house with a private jetty. Boat pickup for Cape Kri and Sardine Reef arranged with neighbors.","amenities":["Boat dock","Gear drying room","Tank storage"],"fees":[{"label":"Cleaning fee","amount":25},{"label":"Boat-dock fee","amount":15}],"hostName":"Marco T.","hostEmail":"marco@example.com","blockedDates":[]}', null, now()),
('listings','si-4','{"title":"Beach bungalow, black sand entry","location":"Tulamben, Bali","region":"Indo-Pacific","site":"USAT Liberty Wreck","viz":18,"depth":30,"price":52,"hostCert":"Advanced","desc":"Two-minute walk to the Liberty wreck. Basic, honest, and exactly what a wreck-diving trip needs.","amenities":["Shore entry","Rinse station","Tank storage"],"fees":[{"label":"Cleaning fee","amount":12}],"hostName":"Dana K.","hostEmail":"dana@example.com","blockedDates":[]}', null, now()),
('listings','si-5','{"title":"Guesthouse near Coron town pier","location":"Coron, Philippines","region":"Southeast Asia","site":"Barracuda Lake","viz":22,"depth":38,"price":47,"hostCert":"Open Water","desc":"Family guesthouse a short tricycle ride from the pier. Hosts arrange boats to the WWII wrecks.","amenities":["Tank storage","Rinse station"],"fees":[{"label":"Cleaning fee","amount":8}],"hostName":"Owen R.","hostEmail":"owen@example.com","blockedDates":[]}', null, now()),
('listings','si-6','{"title":"Reef-front cabana, Utila","location":"Utila, Honduras","region":"Central America","site":"Black Hills","viz":24,"depth":28,"price":58,"hostCert":"Rescue","desc":"Hammock, cold shower, warm water — the classic Utila trade-off. Whale shark season books out fast.","amenities":["Shore entry","Boat dock","Gear drying room"],"fees":[{"label":"Cleaning fee","amount":12},{"label":"Gear-storage fee","amount":5}],"hostName":"Dana K.","hostEmail":"dana@example.com","blockedDates":[]}', null, now()),
('listings','si-7','{"title":"Longtail-boat family home","location":"Similan Islands, Thailand","region":"Southeast Asia","site":"Richelieu Rock","viz":20,"depth":32,"price":73,"hostCert":"Advanced","desc":"Mainland base for liveaboard-adjacent day trips out to Richelieu Rock. Great for surface interval naps.","amenities":["Boat dock","Tank storage","Compressor access"],"fees":[{"label":"Cleaning fee","amount":15},{"label":"Tank-fill fee","amount":7}],"hostName":"Priya N.","hostEmail":"priya@example.com","blockedDates":[]}', null, now()),
('listings','si-8','{"title":"Converted boathouse, north shore","location":"Cozumel, Mexico","region":"Caribbean","site":"Palancar Reef","viz":28,"depth":26,"price":96,"hostCert":"Divemaster / Pro","desc":"Actual boathouse, actually on the water. Drift-dive drop-offs arranged with the dive shop next door.","amenities":["Boat dock","Rinse station","Tank storage","Gear drying room"],"fees":[{"label":"Cleaning fee","amount":18},{"label":"Boat-dock fee","amount":12}],"hostName":"Marco T.","hostEmail":"marco@example.com","blockedDates":[]}', null, now())
on conflict (collection, id) do nothing;

insert into records (collection, id, data, status, created_at) values
('sites','ds-1','{"name":"Cape Kri","location":"Raja Ampat, Indonesia","area":"Indo-Pacific","level":"Advanced","desc":"Famous for the highest fish count ever recorded on a single dive. Strong currents, reef hooks recommended.","experiences":[{"author":"Marco T.","body":"Best drift dive of my life. Went through 4 times in one week and it was different every time.","media":null,"mediaType":null,"createdAt":"2026-08-10T10:00:00Z"}]}', 'approved', now()),
('sites','ds-2','{"name":"Blue Hole","location":"Dahab, Egypt","area":"Red Sea","level":"Open Water (shallow) / Tec (deep)","desc":"Iconic sinkhole reachable from shore. The shallow saddle is easy; the deeper Arch has claimed lives — stay within your training.","experiences":[{"author":"Yuki S.","body":"Did the shallow reef side only, gorgeous coral garden right at the entry. Skipped the arch, not trained for it.","media":null,"mediaType":null,"createdAt":"2026-07-22T09:00:00Z"}]}', 'approved', now()),
('sites','ds-3','{"name":"Salt Pier","location":"Bonaire, Dutch Caribbean","area":"Caribbean","level":"Open Water","desc":"Shore-entry site under an active salt-loading pier. Check with the harbor before diving — closed when ships are docked.","experiences":[]}', 'approved', now()),
('sites','ds-4','{"name":"USAT Liberty Wreck","location":"Tulamben, Bali","area":"Indo-Pacific","level":"Open Water","desc":"A WWII cargo ship a few meters from the beach, now covered in coral. Great for both new wreck divers and photographers.","experiences":[{"author":"Dana K.","body":"Did a night dive here and it was a completely different site — mandarin fish came out right at dusk.","media":null,"mediaType":null,"createdAt":"2026-06-30T20:00:00Z"}]}', 'approved', now()),
('sites','ds-5','{"name":"Richelieu Rock","location":"Similan Islands, Thailand","area":"Southeast Asia","level":"Advanced","desc":"A submerged pinnacle famous for whale shark sightings, best visited by liveaboard or an early boat from the mainland.","experiences":[]}', 'approved', now())
on conflict (collection, id) do nothing;

insert into records (collection, id, data, status, created_at) values
('shops','shop-1','{"name":"Buddy Dive Bonaire","location":"Bonaire, Dutch Caribbean","area":"Caribbean","services":["Tank fills","Gear rental","Nitrox","Courses"],"note":"Unlimited shore diving with a truck rental — pretty much the standard Bonaire setup.","addedBy":"Marco T."}', 'approved', now()),
('shops','shop-2','{"name":"Big Blue Dahab","location":"Dahab, Egypt","area":"Red Sea","services":["Tank fills","Boat charters","Courses"],"note":"Good instructors, patient with nervous first-timers at the Blue Hole.","addedBy":"Yuki S."}', 'approved', now()),
('shops','shop-3','{"name":"Papua Explorers","location":"Raja Ampat, Indonesia","area":"Indo-Pacific","services":["Boat charters","Gear rental","Nitrox"],"note":"Runs the boats out to Cape Kri, knows the current schedule by heart.","addedBy":"Marco T."}', 'approved', now()),
('shops','shop-4','{"name":"Utila Dive Centre","location":"Utila, Honduras","area":"Central America","services":["Tank fills","Courses","Repairs"],"note":"Reasonably priced whale shark trips, honest about when sightings are unlikely.","addedBy":"Dana K."}', 'approved', now())
on conflict (collection, id) do nothing;

insert into records (collection, id, data, status, created_at) values
('threads','th-1','{"category":"Trip reports","title":"Just back from Raja Ampat — worth the flights","author":"Marco T.","authorCert":"Divemaster / Pro","posts":[{"author":"Marco T.","authorCert":"Divemaster / Pro","body":"Ten days, six dive sites, one seasick day. Cape Kri lived up to the hype.","createdAt":"2026-08-10T10:00:00Z"},{"author":"Priya N.","authorCert":"Advanced","body":"How was the current at Cape Kri? Debating if I need more dives first.","createdAt":"2026-08-10T14:20:00Z"}]}', null, now()),
('threads','th-2','{"category":"Gear talk","title":"Backplate and wing vs. jacket BCD for warm water travel","author":"Dana K.","authorCert":"Rescue","posts":[{"author":"Dana K.","authorCert":"Rescue","body":"Switching from a jacket BCD, wondering if backplate/wing is worth it for mostly warm-water reef diving.","createdAt":"2026-08-08T09:00:00Z"}]}', null, now())
on conflict (collection, id) do nothing;
