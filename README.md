# Smart Recommendation System — CI/CD Final Project

A simple full-stack recommendation web app built to demonstrate a complete
**CI/CD pipeline**: code is pushed to GitHub via a bash script, Jenkins
automatically pulls and builds it, and Docker Compose deploys the running
application.

The user types a keyword (e.g. `hot`) and the app replies with the matching
season (e.g. `Summer`).

---

## Stack

| Layer       | Technology                                  |
| ----------- | ------------------------------------------- |
| Frontend    | HTML + CSS (rendered by PHP)                |
| Backend     | PHP 8.2 on Apache                           |
| Database    | MySQL 8.0                                   |
| Container   | Docker + Docker Compose                     |
| CI/CD       | Jenkins Pipeline (`Jenkinsfile`)            |
| Source      | GitHub (push automated by `push.sh`)        |

---

## Project structure

```
.
├── site/
│   └── index.php          # PHP frontend + backend (form + recommendation)
├── dumps/
│   └── dump.sql           # Initial schema and seed data for the `items` table
├── Dockerfile             # PHP + Apache + mysqli
├── docker-compose.yml     # web + db services
├── Jenkinsfile            # CI/CD pipeline (to be revised)
├── push.sh                # automate `git add/commit/push`
├── .gitignore
└── README.md
```

---

## How to run locally

```bash
docker compose up -d --build
```

Then open: **http://localhost:8081**

To stop:

```bash
docker compose down
```

To wipe the database and start fresh:

```bash
docker compose down -v
```

The first time the `db` container starts, MySQL automatically loads
`dumps/dump.sql` from the `docker-entrypoint-initdb.d` mount, which creates
the `items` table and inserts the seed keywords.

---

## How the recommendation works

1. The user types a keyword (e.g. `hot`) or picks one from the dropdown.
2. PHP queries the `items` table:
   `SELECT season FROM items WHERE keyword='hot' LIMIT 1`.
3. The matching season (e.g. `Summer`) is rendered in the result section.

---

## CI/CD flow

```
Developer  ──► push.sh ──► GitHub ──► Jenkins ──► Docker ──► Live App
                                       (auto)     (compose)  :8081
```

1. Developer edits code on the VM (via VSCode Remote-SSH).
2. Runs `./push.sh "message"` → pushes to GitHub from their account.
3. GitHub webhook (or Jenkins SCM polling) triggers the pipeline.
4. Jenkins:
   - Checks out the latest code
   - Runs `docker compose build`
   - Brings the stack up
   - Leaves the new container running
5. App is live again at `http://<vm-ip>:8081`.

---

## Team

UNIX Environment & Tools — Final Project, Spring 2026.
