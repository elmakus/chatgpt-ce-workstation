# Codex-LB integration

Codex-LB is an optional native Codex upstream for `codex-chatgpt-web`. It is independent of Muse Code.

## Configuration

The upstream URL is not secret. Put it in the workstation `.env`:

```text
CODEX_CHATGPT_WEB_NATIVE_UPSTREAM=http://127.0.0.1:2455/backend-api/codex
```

Leave the variable empty to keep native Codex traffic on the official ChatGPT Codex backend.

The API key is stored separately in the persistent workstation home and is never placed in `.env` or the Compose environment:

```text
host:      /mnt/user/appdata/chatgpt-ce-workstation/home/.config/workstation/codex-lb-api-key
container: /home/codex/.config/workstation/codex-lb-api-key
```

Set it from an Unraid root shell:

```bash
cd /mnt/user/projects/chatgpt-ce-workstation
bash scripts/set-codex-lb-key.sh
```

The helper prompts twice without echoing the key and writes the file as the configured Codex UID/GID with mode `0600`.

To remove the key:

```bash
bash scripts/set-codex-lb-key.sh --clear
```

`/usr/local/bin/codex-web-gpt` reads this file when the launcher starts and exports `CODEX_LB_API_KEY` only to the launcher process tree. The key therefore does not appear in the tracked repository or normal `docker inspect` Compose environment output.

After changing the key or upstream URL, quit and relaunch Codex Web GPT. A container rebuild is not required for a key change once a workstation image containing this integration is installed.

## Routing behavior

When `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` is unset/empty, the fork preserves the normal official native Codex path and incoming ChatGPT authentication.

When a custom native upstream is configured, the fork requires a dedicated upstream API key and replaces the incoming ChatGPT bearer before sending the native request to that custom upstream. Missing dedicated authentication fails closed.

ChatGPT Web models remain on the browser-backed ChatGPT Web route; the custom native upstream applies only to native Codex passthrough traffic.
