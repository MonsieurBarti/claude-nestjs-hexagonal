# lefthook.yml

File: `lefthook.yml` (project root)

Defines git hooks enforced automatically on every commit and push.

```yaml
pre-commit:
  commands:
    lint:
      glob: "*.{ts,json}"
      run: pnpm biome check --write --no-errors-on-unmatched {staged_files}
      stage_fixed: true

pre-push:
  parallel: true
  commands:
    test:
      run: pnpm test:unit
    build:
      run: pnpm build
```

## Hook behaviour

### pre-commit

Runs Biome on staged `.ts` and `.json` files only — fast, targeted, no full-project scan.

| Feature | Detail |
|---------|--------|
| `{staged_files}` | lefthook placeholder — expands to the list of staged files matching the glob |
| `stage_fixed: true` | lefthook automatically re-stages any files Biome modified — no manual `git add` needed |
| `--write` | Auto-fixes lint and format issues; the commit proceeds only if all issues are resolved |
| `--no-errors-on-unmatched` | Suppresses the error when no staged files match the glob (e.g. only `.md` files staged) |

### pre-push

Runs unit tests and a production build in parallel before pushing to the remote.

| Feature | Detail |
|---------|--------|
| `parallel: true` | `test:unit` and `build` run concurrently — saves time |
| `pnpm test:unit` | Unit tests only (`*.spec.ts`) — fast, no database required |
| `pnpm build` | Full TypeScript compilation — catches type errors not caught by the editor |

> **Why unit tests only?** Integration and e2e tests require a running database and belong in CI.
> They are not run on pre-push to keep the developer loop fast.

## Skipping hooks

```bash
git commit --no-verify   # skip pre-commit
git push --no-verify     # skip pre-push
```

Use sparingly — e.g. for WIP commits on a personal branch. Do not use on shared branches.

## Automatic installation

`lefthook install` is called via the `postinstall` script in `package.json`, so hooks are
installed automatically whenever a teammate runs `pnpm install` after cloning the project.

To install manually (e.g. after first scaffold):
```bash
pnpm lefthook install
```
