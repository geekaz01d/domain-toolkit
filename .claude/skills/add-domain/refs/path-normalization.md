# Path Normalization

## Writing paths to REGISTRY.yaml

- Replace `$HOME` prefix with `~` for readability and portability across machines with different usernames
- Use absolute paths for anything not under `$HOME`

## Reading paths from REGISTRY.yaml

- Expand `~` to `$HOME` before filesystem operations

## Input normalization

- Normalize all input paths to absolute before proceeding
- Expand `~` to the user's home directory
