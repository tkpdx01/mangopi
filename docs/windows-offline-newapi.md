# Windows Offline NewAPI Package

This guide packages Mangopi CLI as an offline/private-network Windows harness for a NewAPI gateway that exposes an OpenAI-compatible `/v1/chat/completions` API.

## What Is Included

- `mangopi_cli.py`: single-file agent runtime.
- `windows-offline/config.env.example`: editable NewAPI/Qwen 16k profile.
- `windows-offline/start-mangopi.ps1`: loads `config.env` and starts the CLI.
- `windows-offline/start-mangopi.cmd`: double-click friendly launcher.
- `windows-offline/test-newapi.ps1`: verifies the NewAPI endpoint.
- `scripts/package-windows-offline.ps1`: builds a zip package under `dist/`.

No Python package dependencies are required at runtime.

## Build The Zip

Run this on a machine that has the repository:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package-windows-offline.ps1
```

The package is written to:

```text
dist\mangopi-cli-windows-offline-0.1.27.zip
```

Copy that zip into the private Windows environment and extract it.

## Configure

In the extracted directory:

```powershell
cd .\windows-offline
copy .\config.env.example .\config.env
notepad .\config.env
```

Edit these values:

```text
MANGO_API_URL=http://newapi-host:3000/v1
MANGO_MODEL=qwen3-32b
MANGO_KEY=your-newapi-token
```

The URL may be either the OpenAI root (`/v1`) or the full chat-completions endpoint (`/v1/chat/completions`). The runtime normalizes both forms.

## 16k Defaults

The package template uses conservative defaults for a 16k context model:

```text
MANGO_MAX_CONTEXT=16000
MANGO_MAX_OUTPUT=2048
MANGO_MAX_ITER=30
MANGO_TEMPERATURE=0.1
MANGO_TOP_P=0.8
MANGO_TOOL_CHOICE=auto
MANGO_READ_DEFAULT_LIMIT=220
MANGO_GREP_MAX_HITS=120
MANGO_BASH_MAX_LINES=220
```

These limits are intentionally lower than the upstream defaults. They keep file reads, grep results, shell output, and model output from consuming the whole context window.

## Offline Defaults

The template sets:

```text
MANGO_OFFLINE=1
MANGO_DISABLE_TOOLS=web_search,view_image
```

`web_search` is disabled because it calls an external Bocha API. `view_image` is disabled because Qwen3-32B is a text model and most NewAPI gateways for it do not accept OpenAI vision content.

If your private network provides an internal search tool or a vision-capable model, remove the corresponding tool from `MANGO_DISABLE_TOOLS` after testing.

## Test NewAPI

Before starting the agent, verify the gateway:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-newapi.ps1
```

Expected result: the script prints a short model response.

If this fails, fix the NewAPI URL, model name, token, or route configuration before starting the agent.

## Start The Harness

From the extracted package:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows-offline\start-mangopi.ps1
```

Or double-click:

```text
windows-offline\start-mangopi.cmd
```

Useful first prompt:

```text
Read README.md and summarize this project in 5 bullets.
```

If tool calling works through NewAPI, the model should call the `read` tool and then answer.

## Troubleshooting

### The model answers in text but never calls tools

NewAPI may expose an OpenAI-shaped response but not pass through tool calling for this model/channel. Confirm that the response contains `choices[0].message.tool_calls` when tools are supplied.

### Context overflows

Lower these values:

```text
MANGO_MAX_OUTPUT=1024
MANGO_READ_DEFAULT_LIMIT=120
MANGO_GREP_MAX_HITS=60
MANGO_BASH_MAX_LINES=120
```

Then start a new session with `/n`.

### Endpoint timeout

Increase:

```text
MANGO_REQUEST_TIMEOUT=600
MANGO_REQUEST_RETRIES=1
```

### Python is missing

Install Python 3.8+ on the Windows host. The harness itself has no third-party runtime dependencies.
