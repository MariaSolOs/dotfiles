# `pi` configuration

This folder contains my configuration for `pi`.

## Validation

- **TypeScript compilation**: When validating TypeScript changes in this folder, use `tsgo`, not `tsc`. For the extensions, use the `tsconfig.json` file in that folder (`cd agent/extensions && tsgo -p tsconfig.json`).
- **Prettier formatting**: Use `prettier` to format all files in this folder.
- **Git**: This configuration is tracked via a bare Git repository using a sparse checkout. Because of this special setup don't worry about checking `git` changes.

## Documentation

- Extensions should include comments explaining the core logic and design. Don't go overboard: comments shouldn't explain what's obvious from the code.
- Don't add `README` files, comments in the implementation code is more than enough.
