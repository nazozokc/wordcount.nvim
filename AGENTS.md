# Repository Guidelines

## Project Structure & Module Organization

This repository is a small Neovim plugin implemented in Lua:

- `lua/wordcount/init.lua` contains setup, user commands, autocommands, and the public API.
- `lua/wordcount/count.lua` contains UTF-8 classification, counting, word counting, and Markdown frontmatter handling.
- `lua/wordcount/display.lua` manages counter floating windows and their positioning.
- `README.md` documents installation, configuration, commands, and counting rules.
- `CONTRIBUTING.md` describes the contributor workflow and manual checks.

There are currently no automated test or asset directories. Keep new modules under `lua/wordcount/` and update the README when public behavior changes.

## Build, Test, and Development Commands

There is no build step, package manager, or generated output. Validate changes by loading the repository as a local Neovim plugin (Neovim 0.9 or later), for example:

```sh
nvim --clean -u NONE
# In Neovim, add the repository to 'runtimepath', then run:
:lua require("wordcount").setup()
```

Exercise `:WordCount`, `:WordCountToggle`, and `:WordCountRefresh`. Check updates while editing, window resizing, floating-window placement, and both enabled/disabled configurations.

## Coding Style & Naming Conventions

Use four-space indentation, lowercase snake_case for local variables and functions, and lowercase module names. Follow the existing compact Lua style, but favor readable line breaks for new or substantially changed code. Keep the public API (`setup`, `enable`, `disable`, `toggle`, `refresh`, and `details`) stable. Preserve UTF-8 behavior and Neovim 0.9 compatibility; do not add dependencies without a clear need.

## Testing Guidelines

No test framework or coverage threshold is configured. Manually test ASCII letters/digits, Japanese text, whitespace, punctuation, symbols, emoji, empty buffers, Markdown frontmatter, and multi-window layouts. Report the Neovim version and exact scenarios checked in changes that affect counting or display behavior.

## Commit & Pull Request Guidelines

Existing history uses short, generic subjects (for example, `edit`), but new commits should use concise imperative subjects that explain the change, such as `fix frontmatter exclusion`. Keep commits focused. Pull requests should summarize the change and motivation, list manual tests and Neovim versions, note compatibility or behavior changes, and include a screenshot for UI changes. Update documentation alongside public commands, options, or behavior.

## License

Contributions are released under this repository's MIT License.
