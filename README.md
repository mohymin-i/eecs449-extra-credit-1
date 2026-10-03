# Campus Planner

**Mohymin Islam** — UMID: 88068007 (uniqname: `mohymini`)
EECS 449 — Assignment 1: Personal Planning App in Jac

A personal planning tool for coursework, schedules, and habits, built end-to-end in [Jac](https://www.jaseci.org/). One shared backend; a web dashboard, a terminal CLI, and a mobile app all read and write the same data.

---

## What it does

- **Coursework & deadlines** — add courses, attach tasks to a course, see each course's open/total task counts.
- **Daily/weekly schedule** — tasks carry an optional due date, time, and priority (low/medium/high); the Today view buckets them into Overdue / Due today / Upcoming (next 7 days).
- **Habits** — recurring habits with a weekly target, a running streak, and a best-streak record, toggled complete per day.
- **AI task breakdown** *(optional)* — "AI breakdown" on any task asks an LLM for 3–5 concrete subtasks. Degrades gracefully with a clear message if no model key is configured — nothing else in the app depends on it.

No accounts/login: this is a personal, single-user tool, so every component reads and writes one shared planner graph on the server.

---

## Architecture — how the four pieces fit together

```
jac.toml            workspace: declares all four apps below
server/planner.jac   the SERVER — Course/Task/Habit data model + all planning logic,
                      exposed as def:pub functions (list_tasks, add_task, today, ...)
web/                  the WEB FRONTEND — a full-stack Jac app whose pages
                      (Today/Tasks/Courses/Habits) call server/planner.jac directly;
                      `jac run` serves this app AND colocates the server in one process
mobile/               the MOBILE APP — @jac/mobui screens (Today/Tasks/Habits) that
                      bridge to the exact same server/planner.jac functions over HTTP
cli/                  the CLI — argparse commands that bridge to the same functions too
```

`server` is declared as its own `service` app in `jac.toml` (not folded into `web`) specifically so it has a real, addressable bridge surface — `web`, `cli`, and `mobile` are all equally just *consumers* of it, calling the same `def:pub` functions (`list_tasks`, `add_task`, `toggle_habit_today`, `today`, ...). `jac run` serves `web` and colocates `server` in the same process for a zero-config default; the CLI and mobile app, which have no server of their own, reach that exact running instance over HTTP via two environment variables (see below) — so an action taken in any one of the three UIs is immediately visible in the other two.

---

## Setup

**Prerequisite:** the `jac` toolchain (self-contained binary, no Python/pip/uv needed):

```bash
curl -fsSL https://jaclang.org/install.sh | bash
jac --version   # should print 0.37.23 or compatible
```

From the repo root:

```bash
jac install   # pulls npm deps for the web and mobile clients (first run only)
```

## Running the web app + server

```bash
jac run
```

That's it — this serves the web dashboard and colocates the backend in one process. By default:

- **Web app:** http://localhost:8000
- **Backend API** (used by the CLI/mobile below): http://localhost:8001

If port 8000/8001 is busy, `jac run` falls back to the next free port — check the terminal output for the actual `App:` / `API:` URLs, and use the real API URL in the commands below if it differs.

Use `jac run --dev` instead for hot-reload while editing.

## Using the CLI

Open a **second terminal** (leave `jac run` running in the first) and point the CLI at the live backend's API port, using the `server` app's gateway route:

```bash
export JAC_APP_SERVER_URL="http://localhost:8001"
export JAC_APP_SERVER_ROUTE="/api/server"

jac run cli -- today
jac run cli -- add "Finish lab report" --date 2026-10-05 --priority high --course "EECS 449"
jac run cli -- list                      # open tasks (add --all to include completed)
jac run cli -- done <id-prefix>          # toggle complete; ids/prefixes come from `list`/`today`
jac run cli -- rm <id-prefix>            # delete a task
jac run cli -- breakdown <id-prefix>     # AI subtask suggestions

jac run cli -- courses
jac run cli -- course add "EECS 449" --color "#00aaff"
jac run cli -- course rm <id-prefix>

jac run cli -- habits
jac run cli -- habit add "Stretch" --target 7
jac run cli -- habit done <id-prefix>    # toggle today's completion
jac run cli -- habit rm <id-prefix>
```

IDs only need to be typed as an unambiguous prefix (shown in `list`/`today`/`habits` output) — no need to copy the full id.

Without the two `JAC_APP_SERVER_*` variables set, the CLI correctly refuses with a clear "server is not reachable" error rather than silently using its own disconnected copy of the data.

## Using the mobile app

Mobile needs the same two environment variables, for the same reason (it has no server of its own — it's a pure frontend that bridges to the running backend):

```bash
export JAC_APP_SERVER_URL="http://localhost:8001"
export JAC_APP_SERVER_ROUTE="/api/server"

# Browser preview (fastest — no SDK required):
jac run --dev --platform web mobile
# then open the printed localhost URL (typically http://localhost:8003)

# Real device / Expo Go (needs Android SDK or Xcode, provisioned automatically on first run):
jac run --dev mobile
```

The app has three tabs — Today, Tasks, Habits — covering quick-add, toggling tasks/habits complete, deleting tasks, and AI breakdown, mirroring the web app's core actions in a phone-friendly layout.

## Running tests

```bash
JAC_TEST_JOBS=0 jac test server/planner.jac
```

## Optional: AI task breakdown

Set `ANTHROPIC_API_KEY` in the environment **before** running `jac run` (the server process needs it, not the client) to enable the "AI breakdown" button/command. Without a key, it fails gracefully with a message telling you to set one — the rest of the app is unaffected.

---

## What makes this project work well together

The same four `def:pub` functions in `server/planner.jac` (`today`, `list_tasks`, `toggle_habit_today`, etc.) are called, unmodified, from a React web UI, a React Native mobile UI, and a plain-Python-flavored CLI — demonstrating Jac's cross-app bridge rather than three separate hand-wired API clients. Streak math, task sorting, and course linking all live in exactly one place and are exercised by both unit tests (`server/planner.test.jac`) and live end-to-end testing across all three interfaces during development (add a task from the CLI, see it instantly in the browser and on the mobile preview).
