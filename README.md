```
   ██████╗██╗      █████╗ ██╗    ██╗██████╗ ██████╗  ██████╗ ███████╗███████╗
  ██╔════╝██║     ██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝
  ██║     ██║     ███████║██║ █╗ ██║██║  ██║██████╔╝██║   ██║███████╗███████╗
  ██║     ██║     ██╔══██║██║███╗██║██║  ██║██╔══██╗██║   ██║╚════██║╚════██║
  ╚██████╗███████╗██║  ██║╚███╔███╔╝██████╔╝██████╔╝╚██████╔╝███████║███████║
   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
```

# 🦞 Clawdboss Docker

**Run a hardened, multi-agent OpenClaw setup in a container. Zero host dependencies.**

This is [Clawdboss](https://github.com/NanoFlow-io/clawdboss) packaged as a Docker image. Same security-first multi-agent setup, same interactive wizard — just `docker compose up` instead of SSH-ing into a VPS.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) 20.10+
- [Docker Compose](https://docs.docker.com/compose/install/) v2+
- An LLM provider API key (Copilot, OpenAI, or Anthropic)
- A Discord bot token, Telegram bot token, or both

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/NanoFlow-io/clawdboss-docker.git
cd clawdboss-docker
cp .env.example .env
```

Edit `.env` with your API keys and bot tokens.

### 2. Run the setup wizard

```bash
docker compose run --rm clawdboss
```

This launches the interactive Clawdboss setup wizard inside the container. It will walk you through:

- Your identity and preferences
- Agent name, personality, and mission
- LLM provider selection
- Discord/Telegram configuration
- Optional tools (Graphthulhu, ApiTap, Scrapling, OCTAVE, and more)
- OpenClaw skills setup

Your configuration is persisted in a Docker volume, so it survives container recreation.

### 3. Start the gateway

Once setup is complete, start the gateway as a background service:

```bash
docker compose up -d
```

That's it. Your agent is running.

## Interface Options

| Interface | Token Needed | How It Works |
|-----------|-------------|--------------|
| **Discord only** | `DISCORD_BOT_TOKEN` | Bot joins your server, responds in channels |
| **Telegram only** | `TELEGRAM_BOT_TOKEN` | Chat with your bot via DM or groups |
| **Both** | Both tokens | Same agent, two interfaces simultaneously |
| **Console only** | Neither | Interactive terminal session inside container |

## How It Works

The container runs three phases:

1. **Build** — Installs Node.js 22, Python, system tools, OpenClaw, and clones Clawdboss
2. **Setup** (first run) — Interactive wizard creates your config, agents, and workspace
3. **Run** (subsequent starts) — Starts the OpenClaw gateway on port 18789

All state lives in the `openclaw-config` Docker volume mounted at `/home/openclaw/.openclaw`.

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
# LLM Provider (pick at least one)
COPILOT_API_KEY=
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Interface (pick at least one)
DISCORD_BOT_TOKEN=
TELEGRAM_BOT_TOKEN=

# Gateway
GATEWAY_AUTH_TOKEN=

# Optional
BRAVE_API_KEY=
ELEVENLABS_API_KEY=
```

### Container Mode

Control the entrypoint behavior with `CLAWDBOSS_MODE`:

| Mode | Behavior |
|------|----------|
| `auto` (default) | Run setup if no config exists, otherwise start gateway |
| `setup` | Always launch the setup wizard |
| `run` | Always start the gateway (fails if no config) |

## Persistence

The Docker volume `clawdboss-openclaw-config` stores:

- `openclaw.json` — Main configuration
- `.env` — API keys and secrets (inside the container)
- Agent workspaces and memory files
- Gateway state and logs

Your configuration survives `docker compose down` and `docker compose up` cycles. To start completely fresh, remove the volume:

```bash
docker volume rm clawdboss-openclaw-config
```

## Common Operations

### Re-run the setup wizard

```bash
# Option 1: Force setup mode
CLAWDBOSS_MODE=setup docker compose run --rm clawdboss

# Option 2: Remove config and restart
docker compose exec clawdboss rm ~/.openclaw/openclaw.json
docker compose restart clawdboss
```

### Update to the latest version

```bash
# Pull latest Clawdboss and OpenClaw
docker compose build --no-cache
docker compose up -d
```

### View gateway logs

```bash
docker compose logs -f clawdboss
```

### Open a shell inside the container

```bash
docker compose exec clawdboss bash
```

### Use the console interface

```bash
docker compose run --rm clawdboss openclaw console
```

## Optional: ClawSuite Web Console

Uncomment the `clawsuite` service in `docker-compose.yml` to enable the browser-based management UI:

```yaml
clawsuite:
  image: ghcr.io/nanoflow-io/clawsuite:latest
  container_name: clawsuite
  restart: unless-stopped
  ports:
    - "3000:3000"
  environment:
    - GATEWAY_URL=http://clawdboss:18789
    - GATEWAY_AUTH_TOKEN=${GATEWAY_AUTH_TOKEN:-}
  depends_on:
    - clawdboss
```

Then access it at `http://localhost:3000`.

## Architecture

```
┌─────────────────────────────────────────────┐
│  Docker Container                           │
│                                             │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │  OpenClaw    │  │  Clawdboss Config    │  │
│  │  Gateway     │  │  (/opt/clawdboss)    │  │
│  │  :18789      │  │                      │  │
│  └──────┬───────┘  └──────────────────────┘  │
│         │                                    │
│  ┌──────┴───────────────────────────────┐   │
│  │  ~/.openclaw (Docker Volume)          │   │
│  │  ├── openclaw.json                    │   │
│  │  ├── .env                             │   │
│  │  ├── workspace/                       │   │
│  │  └── agents/                          │   │
│  └───────────────────────────────────────┘   │
└──────────────────┬──────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
    Discord API       Telegram API
```

## Troubleshooting

**Setup wizard doesn't appear:**
Make sure you're using `docker compose run` (not `up`) for first-time setup, so stdin is attached.

**Gateway won't start:**
Check that `openclaw.json` exists in the volume: `docker compose exec clawdboss ls ~/.openclaw/openclaw.json`

**Permission errors:**
The container runs as user `openclaw` (uid 1000). If mounting host directories, ensure they're owned by uid 1000.

**Port already in use:**
Change the host port mapping in `docker-compose.yml`: `"8080:18789"` instead of `"18789:18789"`.

## Links

- [Clawdboss](https://github.com/NanoFlow-io/clawdboss) — The main setup wizard (non-Docker)
- [OpenClaw](https://openclaw.io) — The AI agent platform
- [NanoFlow](https://github.com/NanoFlow-io) — More tools and extensions

## License

MIT — see [LICENSE](LICENSE)
