# Deploying Mazaya

Production runs on a single host with Docker Compose ([compose.production.yml](compose.production.yml)):

- **app**: Rails (Puma behind Thruster) with Solid Queue inside Puma. It listens on `127.0.0.1:${WEB_PORT:-9030}`.
- **db**: PostgreSQL 15. Its data lives in the `db_data` volume.
- **storage** volume: uploaded images and files (Active Storage, local disk).

The host's nginx terminates TLS and proxies to the app port.

> The code and the site content ship separately. A deploy updates the code and runs migrations,
> but it never changes products, categories or images. To publish content, see
> [Publishing content](#publishing-content).

---

## First-time setup

On the server:

```bash
git clone https://github.com/EhabFayed/mazaya-rails.git
cd mazaya-rails
nano .env          # see below
docker compose -f compose.production.yml up -d --build
```

On first boot, `db:prepare` creates the database, runs migrations and runs `db:seed`.
That loads the site content from `db/seeds/content/` and creates the admin user.

### `.env`

| Variable | Required | Notes |
|---|---|---|
| `POSTGRES_PASSWORD` | yes | Database password. |
| `SECRET_KEY_BASE` | yes | Generate with `docker compose -f compose.production.yml run --rm app bin/rails secret`. |
| `APP_HOST` | yes | Public domain, e.g. `mazaya.example.com` (used in links and emails). |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | recommended | First admin user, created only when no users exist. Change the password after the first login. |
| `WEB_PORT` | no | Host port nginx proxies to (default `9030`). |
| `LEADS_NOTIFY_TO` | no | Comma-separated emails notified of new leads. |
| `MAIL_FROM`, `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN` | no | Outgoing mail. Without SMTP, lead notifications aren't sent. |

### nginx

```nginx
server {
  server_name mazaya.example.com;
  client_max_body_size 50m;   # admin uploads

  location / {
    proxy_pass http://127.0.0.1:9030;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
  # listen 443 ssl + certificates (e.g. certbot --nginx)
}
```

---

## Deploying code changes

```bash
cd mazaya-rails
git pull
docker compose -f compose.production.yml up -d --build
```

Migrations run automatically when the app container starts. Check that it came up:

```bash
docker compose -f compose.production.yml ps
docker compose -f compose.production.yml logs -f app
curl -sI http://127.0.0.1:9030/ | head -1    # expect HTTP/1.1 200
```

---

## Publishing content

Products, categories, solutions, projects, posts, documents, settings and their images are
kept in the repo as Ruby seed files, generated from a local database:

```
db/seeds/content/01_categories.rb … 15_attachments.rb   # table data
db/seeds/files/                                         # the attached images and files
```

`bin/rails db:seed` **replaces** the content on the target database with these files. Production
then matches the database they were dumped from.

| Replaced | Kept |
|---|---|
| categories, subcategories, products, solutions, projects, posts, safety articles, clients, departments, documents, content lists, settings, translations, and their images | leads and their uploaded files, users, background jobs |

> **Content edited in the production admin is lost** on the next `db:seed`. Make content changes
> locally (or copy them back) before publishing.

### 1. Locally: dump the content

```bash
docker compose up -d
docker exec mazaya-rails-app-1 bin/rails content_seed:dump
```

The dump prints a row count per table. It warns about any attachment whose file is missing from
local storage and skips it, so re-upload that file in the admin and dump again.

```bash
git add db/seeds
git commit -m "Update site content"
git push
```

### 2. On the server: load it

```bash
cd mazaya-rails
git pull
docker compose -f compose.production.yml up -d --build

# back up first: db:seed replaces content
docker compose -f compose.production.yml exec db pg_dump -U mazaya mazaya_production > ~/mazaya-$(date +%F).sql

docker compose -f compose.production.yml exec app bin/rails db:seed
docker compose -f compose.production.yml restart app
```

The restart makes every Puma worker reload translations. Page caches are invalidated by the seed.

You don't need the catalogue spreadsheet (`db/data/mazaya_catalogue_master.xlsx`) on the
server. It's only used locally to import products (`bin/rails products:import_master`), and it's
kept out of git because it's over GitHub's 100 MB limit.

---

## Backups and restore

```bash
# database
docker compose -f compose.production.yml exec db pg_dump -U mazaya mazaya_production > ~/mazaya-$(date +%F).sql

# uploaded files
docker run --rm -v mazaya-rails_storage:/data -v ~/:/backup alpine tar czf /backup/storage-$(date +%F).tgz -C /data .
```

The volume name has the compose project name as a prefix (the folder name by default). Check it
with `docker volume ls`.

Restore the database:

```bash
docker compose -f compose.production.yml exec -T db psql -U mazaya -d mazaya_production < ~/mazaya-YYYY-MM-DD.sql
```

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Production shows old products | Content isn't deployed with code. Run [Publishing content](#publishing-content). |
| `db:seed` warns `ignoring columns not in this database` | The local DB has a column production doesn't (e.g. from a migration that was run locally but never committed). Commit the migration, or ignore the warning if the code doesn't use the column. |
| Images broken after restoring only the DB | Images live in the `storage` volume. Restore it too, or run `db:seed` again. |
| `git push` rejected, "file exceeds 100 MB" | A large file (e.g. the catalogue spreadsheet) was committed. Remove it from the commit and add it to `.gitignore`. |
| Local only: app container keeps restarting with `A server is already running` | A stale `tmp/pids/server.pid` was left behind. Run `rm tmp/pids/server.pid` and restart the container. |
