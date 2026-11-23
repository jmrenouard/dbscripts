# ADR-001: Diátaxis and Versioned MkDocs Publishing

| Attribute | Value |
|---|---|
| Status | Accepted |
| Date | `2026-11-23` |
| Deciders | Maintainers, Platform Engineering |
| Supersedes | Flat `documentation/` browsing |

## Context

`dbscripts` stores guides in `documentation/`, registers in `docs/`, and READMEs in root, `ansible/`, and `docker/mariadb/`. Tests require root `*.md` equals `{"README.md", "AGENTS.md"}`. Publishing must keep repo paths intact while organizing reader workflows.

## Options and Trade-Offs

| Option | UX | Compatibility | Hosting | Verdict |
|---|---|---|---|---|
| Diátaxis `docs/` + hooks + `git archive` + IONOS SFTP | High (4 quadrants + `guides/`) | High (`*.md` intact; `v1.0.0` + `main`) | `.htaccess` + `versions.json` | **Selected** |
| Move `documentation/` & READMEs to `docs/` | Medium | Low (breaks paths/tests) | Medium | Rejected |
| `mike deploy` HTML branches | High | Medium (pollutes history) | GitHub Pages lock-in | Rejected |

## Decision

1. Put new docs in `docs/` (`01-tutorials/`, `02-how-to-guides/`, `03-reference/`, `04-explanation/`).
2. Map `README.md`, `Changelog`, `ansible/README.md`, `docker/mariadb/README.md`, `documentation/` via `scripts/mkdocs_hooks.py`.
3. Build multi-version bundles via `scripts/build_versioned_docs.py` and deploy via SFTP to IONOS.

## Consequences

- **Positive**: Keeps legacy paths/tests intact; publishes tagged releases beside `main` (`dev`).
- **Risks**: Broken links or mixed genres fail `--strict` builds unless gated by CI.

[Scripts & CLI](../../03-reference/cli-and-scripts/scripts-and-cli-reference.md) | [How-To Guides](../../02-how-to-guides/index.md)
