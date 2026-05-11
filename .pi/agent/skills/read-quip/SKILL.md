---
name: read-quip
description: Read Quip document contents from a quip.com URL using the Quip API. Use when the user provides a Quip document URL/id and asks to read, summarize, extract, or analyze the document.
---

# Read Quip

Use this skill to fetch a Quip document via the Quip API and extract readable plain text.

## Requirements

A Quip API token must be available in the `QUIP_API_TOKEN` environment variable.

## Usage

From this skill directory:

```bash
python3 scripts/quip_read.py 'https://example.quip.com/abc123Example'
```

Useful options:

```bash
python3 scripts/quip_read.py '<url-or-thread-id>' --output /tmp/quip.txt
python3 scripts/quip_read.py '<url-or-thread-id>' --html
python3 scripts/quip_read.py '<url-or-thread-id>' --json
```

## Workflow

1. Accept a Quip URL or thread/document id from the user.
2. Load the Quip token from the environment.
3. Call `GET https://platform.quip.com/1/threads/{id}` with `Authorization: Bearer <token>`.
4. Extract `thread.title` and convert the returned `html` field to plain text unless HTML or JSON output is requested.
5. Summarize or analyze the extracted content according to the user's request.

If authentication fails, ask the user to provide/export a valid Quip token with permission to read the document.
