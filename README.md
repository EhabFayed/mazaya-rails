# ألومنيوم مزايا — Mazaya Aluminium website

Rails 8 marketing site for Mazaya Aluminium (Arabic, RTL). Information
architecture v2: two tracks (B2B "حلول الأعمال" / B2C "المنتجات") plus a shared
trunk (about, quality, safety, original-vs-counterfeit, news, contact).

## Sources of truth

| What | Where |
|---|---|
| Page copy (headlines, descriptions, CTAs) | `config/locales/ar.yml` + `en.yml` (defaults) — every key can be overridden from **/admin/translations** (stored in `translations`, layered via `I18n::DbOverrides`). |
| Structured content (categories, products, solutions, projects, posts, safety guides, documents, clients, departments, lists, settings) | Database tables managed from **/admin**. `app/models/site_data.rb` exposes them to the views with the original constant API (`SiteData::PRODUCTS`, `SiteData.product(slug)`…) via `const_missing`, cached per `settings.content_version`. Empty tables fall back to the seed defaults in `app/models/site_data/defaults.rb`; `db/seeds.rb` imports those defaults (idempotent). |
| Design system | `public/site.css` (v1 colours, GE SS Two font, radii) + partials in `app/views/shared/` |
| Behaviour | `public/site.js` (WhatsApp wiring, mega menu, lead forms, gated downloads, filters) |

## Routes

```
/                     home (router between the two tracks)
/b2b                  B2B hub          /solutions, /solutions/:slug
/catalog              e-catalog        /rfq            /partners
/projects, /projects/:slug
/products             B2C hub          /products/:category(?sub=&kind=)  /products/:category/:slug
/about /original /quality /safety(/:slug) /news(/:slug) /contact /search?q=
POST /leads           every form (kind: rfq|quote|partner|download|contact)
/downloads/:key       gated files (needs the mz_gate cookie set by a download lead)
```

Arabic is the default at `/…`; English lives at `/en/…` (same routes). The header language pill links to the same page in the other language and `<link hreflang>` tags are emitted.

Legacy v1 URLs (`/ladders`, `/carts`, `/custom`, `*.html`) redirect permanently.

## Local setup (macOS)

```sh
brew install ruby@3.2 libpq vips postgresql@17   # or use the Docker compose file
export PATH="/opt/homebrew/opt/ruby@3.2/bin:$PATH"
bundle config set --local build.pg --with-pg-config=/opt/homebrew/opt/libpq/bin/pg_config
bundle install
bin/rails db:prepare
bin/rails server
```

## Admin (/admin)

Session login (`users` table, bcrypt). Roles: `admin` (everything), `editor` (content), `sales` (leads).
First user is created by `bin/rails db:seed` (`ADMIN_EMAIL` / `ADMIN_PASSWORD`, default admin@mazaya.local / mazaya-admin-2026 — change it).
Sections: dashboard (KPIs + "pending before launch" checklist), leads pipeline, products (+ Excel/CSV import), categories, custom solutions, projects, news & articles, safety guides, documents & catalogues (PDF upload), content lists (stats, steps, comparison table…), client logos, departments, page copy (translations), settings (WhatsApp, address, map, RFQ response time, notification emails), users.

## Leads, notifications

- Every form POSTs to `/leads`; attachments go to Active Storage (`storage/`, or set `ACTIVE_STORAGE_SERVICE`).
- `LeadMailer` emails each new lead to `LEADS_NOTIFY_TO` (comma-separated) via SMTP settings in `.env.example`. Unset = no email, lead still saved.
- `/admin/leads` lists, filters and exports leads (CSV). HTTP Basic auth via `ADMIN_USER` / `ADMIN_PASSWORD` (`admin`/`admin` outside production).
- `/sitemap.xml` (both locales, hreflang), `robots.txt`, JSON-LD (Organization everywhere; Product + BreadcrumbList on product pages), styled `public/404|422|500.html`.
- Deploy: `config/deploy.yml` (Kamal) with the variables from `.env.example`.

## Checks

```sh
bin/rails test        # smoke test of every route + lead capture
bin/rubocop
bin/brakeman --no-pager
```

## Pending from the client

- Excel sheet of categories / sub-categories / products (replaces the sample tree in `SiteData`).
- Real PDFs: full catalogue, per-category catalogues, technical catalogue, company profile, TDS, user guides (all currently `public/downloads/placeholder.pdf`).
- Project details and photos for the five reference projects; certificates and test reports; factory address, hours, phone, email, Google Maps embed; official WhatsApp number (`SiteData::WHATSAPP_DISPLAY`).
- Confirmation of which client logos may appear in the trust strip.
