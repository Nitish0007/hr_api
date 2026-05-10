# HR API — System Requirements & Architecture

**Scope:** production-oriented view of the **hr_api** Rails backend and how it fits a full-stack HR analytics product  
**Last aligned to repo:** Rails 8.1, API v1, JWT (Devise), PostgreSQL, Redis, Solid Queue  

---

## 1. Product intent

A **human-resources style API** that stores **employees**, exposes **CRUD** and **aggregated salary analytics** (by country and by country + job title), with **authenticated** access, **cache-backed** analytics for latency, and **background maintenance** for JWT revocation housekeeping at scale.

---

## 2. Functional requirements


| ID       | Requirement                             | Notes (backend today)                                                                                                                                                          |
| -------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **F-1**  | **Create employee**                     | `POST /api/v1/employees` — validated attributes, unique email & generated `employee_code`                                                                                      |
| **F-2**  | **View employee**                       | `GET /api/v1/employees/:id` — JWT required                                                                                                                                     |
| **F-3**  | **List employees**                      | `GET /api/v1/employees` — **Kaminari** pagination (`page`, `per_page`, meta in response)                                                                                       |
| **F-4**  | **Update employee**                     | `PATCH/PUT /api/v1/employees/:id`                                                                                                                                              |
| **F-5**  | **Delete employee**                     | `DELETE /api/v1/employees/:id`                                                                                                                                                 |
| **F-6**  | **Sign up / login / logout**            | `POST …/auth/sign_up`, `POST …/auth/login`, `DELETE …/auth/logout` — JWT in `Authorization` header                                                                             |
| **F-7**  | **Country salary metrics**              | `GET …/analytics/country_salary_statistics?country=XX` — min / max / avg salary, count                                                                                         |
| **F-8**  | **Job-title average (country + title)** | `GET …/analytics/job_title_average_salary?country=XX&job_title=…` — combined dimension                                                                                         |
| **F-9**  | **Reference data**                      | `GET …/public_resources/allowed_resource_list` — curated lists (e.g. departments, titles) for UI                                                                               |
| **F-10** | **UI: readable metrics (charts)**       | *Frontend responsibility* — consume analytics JSON; suggest bar/line for distributions, cards for KPIs                                                                         |
| **F-11** | **UI: filters**                         | *Product* — filter employees by country, title, department, salary range, hire date, etc.; **list API may be extended** with query params beyond current pagination-only index |
| **F-12** | **Health**                              | `GET /up` - healthcheck                                                                                                                                                        |


**Authentication model:** JSON API + **Bearer JWT**; protected controllers inherit API base auth.

---

## 3. Non-functional requirements


| ID      | Requirement                       | Target / approach                                                                                                                                                              |
| ------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **N-1** | **Scale** — large employee corpus | Design for **~100k+** rows: indexed dimensions (`country`, `job_title`, composite index), aggregation via SQL (`MIN`/`MAX`/`AVG`), avoid N+1 on list                           |
| **N-2** | **Analytics latency**             | **~500 ms** p95 budget — **Redis** cache (`Rails.cache` / `RedisCacheStore`) with keyed invalidation on employee writes; monitor cache hit ratio and DB query time             |
| **N-3** | **Availability**                  | Stateless app behind reverse proxy(Thruster) / PaaS; DB & Redis managed or clustered per provider                                                                              |
| **N-4** | **Test coverage**                 | **RSpec** — request specs, model specs, job specs; CI runs lint + security scans + tests                                                                                       |
| **N-5** | **Security & abuse**              | JWT expiry & denylist, CORS allowlist, TLS in prod, Brakeman + bundler-audit in CI; **Pending but thought about** - **rate limiting**(CDN/API gateway) — *for spam prevention* |


---

## 4. Core data entities


| Entity                           | Purpose                             | Key fields / constraints                                                                                                                                                         |
| -------------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **User**                         | Application login identity (Devise) | `email`, encrypted password; JWT issuance on sign-up/login                                                                                                                       |
| **JwtDenylist**                  | Revoked JWT **jti** + **exp**       | Unique `jti`; rows purged after expiry by scheduled job                                                                                                                          |
| **Employee**                     | HR record                           | `employee_code` (unique), `email` (unique), `first_name`, `last_name`, `job_title`, `country` (2-letter), `department`, `salary`, `hire_date`; indexes support analytics filters |
| **Solid Queue** *(infra tables)* | Job queue & **recurring tasks**     | `solid_queue_jobs`, `solid_queue_recurring_tasks`, etc. — **not business domain** but operational entity on same Postgres DB in this deployment                                  |


**Relationships (logical):**

- `User` — standalone auth entity.  
- `Employee` — standalone domain entity (no `User` FK in typical HR listing; auth is API-wide).  
- `JwtDenylist` — tied to **User** sessions via JWT **jti** at runtime.

---

## 5. Building blocks for architecture diagrams

Use these **named components** on diagrams so labels stay consistent.

### 5.1 Client & edge


| Component                         | Role                                                                                     |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| **Web browser / SPA**             | HR UI: tables, forms, charts; stores JWT; calls HTTPS API                                |
| **Vercel (or other static host)** | Serves frontend assets; **must** call API with **absolute** backend URL + CORS allowlist |


### 5.2 Application process (single container / one dyno)


| Component                           | Role                                                                                                     |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **Thruster**                        | Reverse proxy in front of Puma — HTTP/2, compression, X-Sendfile-style acceleration (`Dockerfile` `CMD`) |
| **Puma**                            | HTTP worker threads — Rack → Rails                                                                       |
| **Rails 8 API**                     | Routing, controllers, serializers/JSON, Devise JWT, policies                                             |
| **Rack::CORS**                      | Cross-origin rules (`ALLOWED_ORIGINS`)                                                                   |
| **Solid Queue plugin** *(optional)* | When `SOLID_QUEUE_IN_PUMA=1`, supervisor runs **inside Puma** alongside web                              |


### 5.3 Domain services (in-process)


| Component            | Role                                                                        |
| -------------------- | --------------------------------------------------------------------------- |
| **AnalyticsService** | Computes aggregates; **read-through cache**                                 |
| **AnalyticsCache**   | Key naming + **targeted invalidation** after employee create/update/destroy |
| **ResourceService**  | Serves allowed pick-lists for UI                                            |


### 5.4 Data & async


| Component                 | Role                                                                          |
| ------------------------- | ----------------------------------------------------------------------------- |
| **PostgreSQL**            | System of record: users, employees, jwt_denylist, solid_queue_*               |
| **Redis**                 | `Rails.cache` — analytics response cache; fault-tolerant misses if Redis down |
| **Solid Queue**           | Active Job adapter; **recurring schedule** loads from `config/recurring.yml`  |
| **JwtDenylistCleanupJob** | Deletes **expired** denylist rows (scheduled); keeps table bounded            |


### 5.5 External / operational


| Component                     | Role                                                                            |
| ----------------------------- | ------------------------------------------------------------------------------- |
| **CI (GitHub Actions)**       | Brakeman, bundler-audit, RuboCop, RSpec + service containers for Postgres/Redis |
| **Container registry / PaaS** | Railway — runs `Dockerfile`, injects secrets, healthcheck `GET /up`             |


---

## 6. Architecture flow created in very start

screenshot of design diagam: https://prnt.sc/dp6rxg4TudYQ
---
