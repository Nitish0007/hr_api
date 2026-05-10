# HR API — HTTP reference (v1)

Base path for all endpoints below: **`/api/v1`**.

Use **`Content-Type: application/json`** for requests with a body.

For hosting and Railway/Docker env vars, see **[DEPLOYMENT.md](DEPLOYMENT.md)**.

---

## Authentication

Most endpoints require a logged-in user. After **sign up** or **login**, read the JWT from the response header:

- **`Authorization: Bearer <token>`**

Send that same header on every protected request. The API is **JWT-first**; a session cookie may also be set for server-side flows—your SPA should rely on the **`Authorization`** header.

| Situation | HTTP status | Body shape |
|-----------|-------------|------------|
| Missing or invalid token | `401 Unauthorized` | `{ "errors": ["…"] }` (Devise/Warden message) |

---

## Response envelopes

### Success (most resources)

```json
{
  "data": { },
  "meta": { },
  "message": "optional string"
}
```

- **`data`** — always present (may be `null` for some deletes).
- **`meta`** — only when present (e.g. pagination on employee index).
- **`message`** — only when present (e.g. create/update/delete employee).

### Errors (validation / bad input)

```json
{
  "errors": ["Human-readable message", "…"]
}
```

Typical status: **`422 Unprocessable Content`** (validation), **`400 Bad Request`** (missing/invalid params), **`404 Not Found`**.

---

## Auth — public

### POST `/api/v1/auth/sign_up`

Creates a user. JWT is returned in the **`Authorization`** response header.

**Request body**

```json
{
  "user": {
    "email": "user@example.com",
    "password": "your-secure-password",
    "password_confirmation": "your-secure-password"
  }
}
```

**Responses**

| Status | Notes |
|--------|--------|
| `201 Created` | User created; body includes user stub; **`Authorization: Bearer …`** |
| `422 Unprocessable Content` | Validation failed |

**201 body**

```json
{
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com"
    }
  }
}
```

**422 body**

```json
{
  "errors": ["Email has already been taken"]
}
```

---

### POST `/api/v1/auth/login`

**Request body**

```json
{
  "user": {
    "email": "user@example.com",
    "password": "your-secure-password"
  }
}
```

**Responses**

| Status | Notes |
|--------|--------|
| `200 OK` | Success; **`Authorization: Bearer …`** |
| `401 Unauthorized` | Bad credentials |

**200 body**

```json
{
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com"
    }
  }
}
```

**401 body**

```json
{
  "errors": ["Invalid Email or password."]
}
```

---

### DELETE `/api/v1/auth/logout`

Revokes the current JWT (denylist). Send the same **`Authorization: Bearer …`** you used for authenticated calls.

**Request body**

None.

**Responses**

| Status | Notes |
|--------|--------|
| `204 No Content` | Success; empty body |
| `401 Unauthorized` | Missing/invalid token |

---

## Public resources (no auth)

### GET `/api/v1/public_resources/allowed_resource_list`

**Query parameters**

| Name | Required | Value |
|------|----------|--------|
| `resource` | Yes | `countries` \| `job_titles` \| `departments` |

**Example:** `GET /api/v1/public_resources/allowed_resource_list?resource=countries`

**200 body** (array of `{ id, name }` from YAML config)

```json
{
  "data": [
    { "id": "US", "name": "United States" }
  ]
}
```

**422 body** (invalid or missing resource name)

```json
{
  "errors": ["Invalid 'resource' name"]
}
```

---

## Employees (auth required)

Nested key for writes: **`employee`**.

Permitted attributes: **`first_name`**, **`last_name`**, **`email`**, **`job_title`**, **`country`** (2-letter code), **`salary`** (number), **`department`**, **`hire_date`** (ISO date string, e.g. `"2024-01-15"`).

`employee_code` is server-assigned; do not rely on sending it on create (ignored for mass assignment patterns in app behavior).

### GET `/api/v1/employees`

**Query parameters (optional)**

| Name | Default |
|------|---------|
| `page` | `1` |
| `per_page` | `10` |

**200 body**

```json
{
  "data": [
    {
      "id": 1,
      "first_name": "Jane",
      "last_name": "Doe",
      "email": "jane@example.com",
      "job_title": "Engineer",
      "country": "US",
      "salary": "95000.0",
      "department": "Engineering",
      "hire_date": "2022-06-01",
      "employee_code": "EMP-…",
      "created_at": "2026-05-09T12:00:00.000Z",
      "updated_at": "2026-05-09T12:00:00.000Z"
    }
  ],
  "meta": {
    "total": 42,
    "page": 1,
    "per_page": 10,
    "total_pages": 5
  }
}
```

Decimal fields may arrive as **strings** in JSON.

---

### GET `/api/v1/employees/:id`

**200 body**

```json
{
  "data": {
    "id": 1,
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane@example.com",
    "job_title": "Engineer",
    "country": "US",
    "salary": "95000.0",
    "department": "Engineering",
    "hire_date": "2022-06-01",
    "employee_code": "EMP-…",
    "created_at": "…",
    "updated_at": "…"
  }
}
```

**404 body**

```json
{
  "errors": ["Resource Not Found"]
}
```

---

### POST `/api/v1/employees`

**Request body**

```json
{
  "employee": {
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane@example.com",
    "job_title": "Engineer",
    "country": "US",
    "salary": 95000,
    "department": "Engineering",
    "hire_date": "2024-01-15"
  }
}
```

**201 body**

```json
{
  "data": {
    "id": 1,
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane@example.com",
    "job_title": "Engineer",
    "country": "US",
    "salary": "95000.0",
    "department": "Engineering",
    "hire_date": "2024-01-15",
    "employee_code": "EMP-…",
    "created_at": "…",
    "updated_at": "…"
  },
  "message": "Employee created successfully"
}
```

**422 body**

```json
{
  "errors": ["Email can't be blank", "…"]
}
```

---

### PATCH `/api/v1/employees/:id`

**Request body** (partial update allowed)

```json
{
  "employee": {
    "first_name": "Janet",
    "email": "janet@example.com"
  }
}
```

**200 body**

```json
{
  "data": { },
  "message": "Updated successfully"
}
```

(`data` is the full employee record as JSON.)

**404 / 422** — same error envelope as above.

---

### DELETE `/api/v1/employees/:id`

**200 body**

```json
{
  "data": null,
  "message": "Employee deleted successfully"
}
```

**404** — `errors: ["Resource Not Found"]`.

---

## Analytics (auth required)

Analytics responses are **cached server-side** for **24 hours** (`Rails.cache`, `expires_in: 24.hours`). When an **employee is created, updated, or destroyed**, the API **deletes** the related cache entries (that employee’s country, and the country + job title pair used for job-title averages—including the previous country or job title after an update) so the next request recomputes from the database. There is no separate `ETag` contract for clients yet; treat JSON as authoritative after writes.

### GET `/api/v1/analytics/country_salary_statistics`

**Query parameters**

| Name | Required | Description |
|------|----------|-------------|
| `country` | Yes | ISO 3166-1 alpha-2, case-insensitive (stored uppercase) |

**200 body** (when there are employees in that country)

```json
{
  "data": {
    "country": "US",
    "employee_count": 3,
    "minimum_salary": "50000.0",
    "maximum_salary": "110000.0",
    "average_salary": "80000.0"
  }
}
```

**200 body** (no employees — aggregates null)

```json
{
  "data": {
    "country": "US",
    "employee_count": 0,
    "minimum_salary": null,
    "maximum_salary": null,
    "average_salary": null
  }
}
```

**400 body** — missing `country`, not 2 letters, etc.

```json
{
  "errors": ["param is missing or the value is empty: country"]
}
```

or

```json
{
  "errors": ["Country must be a 2-letter code"]
}
```

---

### GET `/api/v1/analytics/job_title_average_salary`

**Query parameters**

| Name | Required | Description |
|------|----------|-------------|
| `country` | Yes | 2-letter country code |
| `job_title` | Yes | Exact match to stored `employees.job_title` |

**200 body**

```json
{
  "data": {
    "country": "US",
    "job_title": "Engineer",
    "employee_count": 2,
    "average_salary": "100000.0"
  }
}
```

**200 body** (no rows)

```json
{
  "data": {
    "country": "US",
    "job_title": "Engineer",
    "employee_count": 0,
    "average_salary": null
  }
}
```

**400** — missing params, blank `job_title`, or invalid country code (same style as country stats).

---

## Health (no API prefix)

### GET `/up`

Rails health check for load balancers — not under `/api/v1`.

---

## CORS (frontend)

`Authorization` is included in **exposed** response headers so browser clients can read the JWT from sign-in/sign-up responses. Ensure your origin is allowed via `ALLOWED_ORIGINS` (see `config/initializers/cors.rb`).

---

## Quick checklist for a new frontend

1. **Sign up** or **login** → store token from **`Authorization`** (strip `Bearer ` prefix if you store only the token).
2. Attach **`Authorization: Bearer <token>`** to **`/api/v1/employees`**, **`/api/v1/analytics/*`**, etc.
3. Use **`GET …/public_resources/allowed_resource_list`** for dropdowns (countries, job titles, departments) without auth.
4. Parse **`data` / `errors` / `meta` / `message`** consistently; treat numeric decimals as strings if needed.
