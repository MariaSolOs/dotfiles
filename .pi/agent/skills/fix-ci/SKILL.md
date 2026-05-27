---
name: fix-ci
description: Fetches failed and errored test details from CircleCI job test URLs using the CircleCI API v2. Use when the user provides a CircleCI tests URL and asks for errors, failures, test results, or help fixing CI.
---

# Fix CI

Use this skill to turn a CircleCI web tests URL like:

```text
https://app.circle.example.com/pipelines/github/example-org/example-repo/19060/workflows/887679f9-1f30-43a6-a600-7292d29b3edc/jobs/215974/tests
```

into API calls to CircleCI v2 and summarize failing/erroring tests.

## Requirements

Make sure that the following environment variables are set in your environment. If not, raise an error.

- `CIRCLECI_TOKEN`
- `CIRCLECI_API_BASE`

For such test run `[ -n "${CIRCLECI_TOKEN}" ]  && echo "ENV OK" || echo "ERROR: MISSING ENV VAR"`

## Usage

From this skill directory:

```bash
python3 scripts/circleci_errors.py '<circleci-tests-url>'
```

Useful options:

```bash
python3 scripts/circleci_errors.py '<url>' --all        # print all tests, not just failed/error tests
python3 scripts/circleci_errors.py '<url>' --json       # emit normalized JSON
python3 scripts/circleci_errors.py '<url>' --base-url https://circle.example.com/api/v2
```

## Workflow

1. Parse the CircleCI web URL.
2. Derive the project slug (`github/org/repo` from app URLs, accepted by CircleCI Server; public cloud also accepts `gh/org/repo` for cloud URLs).
3. Call `GET /api/v2/project/{project-slug}/{job-number}/tests`, following pagination.
4. Report tests whose result is `failure`, `failed`, `error`, or `errored`, including class/name/file/message/source where available.

If authentication fails, ask the user to provide/export a valid CircleCI token with permission to read the project/job.
