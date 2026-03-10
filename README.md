# Sparkdeck

Sparkdeck takes a startup idea and generates a structured validation brief — ICP critique, value proposition, landing page copy, interview questions, GTM plan, fundraising guidance, and next steps. It pressure-tests assumptions before you write product code.

Built with Elixir, Phoenix LiveView, and Postgres. Runs locally via Docker Compose.

## What it does

1. You describe your idea, target customer, and the problem you're solving.
2. Sparkdeck calls an LLM and generates a full validation brief.
3. You review the brief and save it if it's useful.
4. From the saved workspace you can edit inputs, regenerate individual sections, or duplicate the project.

## Prerequisites

- Docker Desktop (or Docker Engine with Compose)
- An API key for an Ollama-compatible endpoint

Verify Docker:

```sh
docker compose version
```

## Setup

### 1. Create environment file

```sh
cp .env.example .env
```

Edit `.env` and set:

- `LLM_API_KEY` — your API key (required)

Defaults you can leave as-is for local dev:

| Variable | Default | Description |
|---|---|---|
| `LLM_HOST` | `https://ollama.com` | Base URL for any OpenAI-compatible API |
| `LLM_MODEL` | `gpt-oss:120b` | Model identifier |
| `LLM_PROMPT_VERSION` | `v1` | Prompt version tag |
| `PORT` | `4010` | App port |

### 2. Start the stack

```sh
make up
```

This starts Postgres and the Phoenix app. The app waits for Postgres, runs migrations, and starts on the configured port.

### 3. Open the app

```
http://localhost:4010
```

## Usage

### Generate a brief

1. Fill in the idea, target customer, and problem on the home page.
2. Click **Generate brief**.
3. Review the generated validation brief.
4. Click **Save project** to persist it, or **Discard** to start over.

### Work with saved projects

From a saved project workspace you can:

- **Edit inputs** and save changes
- **Regenerate all** to rebuild the entire brief
- **Regenerate individual sections** using the section chips
- **Duplicate** a project to explore variations

### View saved projects

Click **Projects** in the nav to see all saved projects.

## Commands

```sh
make up        # start the stack
make down      # stop containers
make rebuild   # wipe database and rebuild from scratch
make logs      # tail container logs
make shell     # open a shell in the web container
make test      # run tests
make format    # run formatter
```

## Stack

- **App**: Elixir, Phoenix, LiveView
- **Database**: PostgreSQL
- **LLM**: Instructor (Elixir) with a custom adapter for Ollama-compatible APIs
- **Runtime**: Docker Compose

## Troubleshooting

**App doesn't start**: Check Docker is running and `.env` exists with `OLLAMA_API_KEY` set. Run `make rebuild` to start fresh.

**Generation fails**: Check `make logs` for errors. Verify your API key and that the configured model is available on your endpoint.

**Port conflict**: Change `PORT` in `.env` and update the port mapping in `docker-compose.yml`.
