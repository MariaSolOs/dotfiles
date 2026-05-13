# `pi` configuration

This folder contains my configuration for `pi`.

## TypeScript validation

When validating TypeScript changes in this folder, use `tsgo`, not `tsc`.

For extension-specific TypeScript projects, run `tsgo` from the extension directory with its local config, for example:

```sh
cd agent/extensions/gh-summary && tsgo -p tsconfig.json
```

Keep `tsconfig.json` files as small as possible. Do not configure options that are already TypeScript defaults. Only add options that are required for this Pi extension environment or for successful validation.

## Documentation

Extensions should include comments explaining the core logic and design. Don't go overboard: comments shouldn't explain what's obvious from the code.

Don't add `README` files, comments in the implementation code is more than enough.
