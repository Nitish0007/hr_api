# HR API

Rails 8 JSON API for employee CRUD, JWT auth, and salary analytics (PostgreSQL, Redis cache, Solid Queue). Ruby **3.4.2** (see `.ruby-version`).

## Documentation


| Doc                                                                                | Purpose                                                                   |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| **[docs/API.md](docs/API.md)**                                                     | HTTP API: auth, employees, analytics, errors                              |
| **[docs/ARCHITECTURE_AND_REQUIREMENTS.md](docs/ARCHITECTURE_AND_REQUIREMENTS.md)** | Requirements, core entities, deployment-style architecture (for diagrams) |
| **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)**                                       | Production / Docker / CI / Solid Queue notes                              |


## Development environment setup

### Option A — Docker Compose (recommended)

1. Add a `**.env.dev`** in the project root (not committed) so Postgres and Rails agree on credentials. Example:
  ```env
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=postgres
   POSTGRES_DB=hr_api_development
   DATABASE_URL=postgresql://postgres:postgres@hrdb:5432/hr_api_development
   REDIS_URL=redis://redis:6379/0
  ```
2. Start the stack (app, Postgres, Redis). The dev image runs `db:prepare` on boot and serves on port **3000**:
  ```bash
   docker compose -f docker-compose.dev.yml build

  # before running, you need to generate the source files first for seeding data
  docker compose -f docker-compose.dev.yml exec hr_api bin/rake data:generate_source_files

  docker compose -f docker-compose.dev.yml up # this will run seed initially

  # Comand to run seed script explicitly
  docker compose -f docker-compose.dev.yml exec hr_api bin/rake db:seed
  ```
3. Open **[http://localhost:3000](http://localhost:3000)** — e.g. health: `GET /up`.

### Tests

With Compose (profile `test`):

```bash
# NOTE: Add a .env.test for test similar to .evn.test
docker compose -f docker-compose.dev.yml --profile test run --rm hr_api_test bundle exec rspec
```

## How I approached this

Work started from a **short requirements pass** and a **minimal domain model** centered on **Employee** (and auth around **User** / JWT). I sketched **request flow** (client → API → DB / cache / jobs) before implementation, then captured the fuller picture in **[docs/ARCHITECTURE_AND_REQUIREMENTS.md](docs/ARCHITECTURE_AND_REQUIREMENTS.md)** — that doc is the place for tables, components, and Mermaid-friendly flows

For **endpoints and payloads**, use **[docs/API.md](docs/API.md)** 