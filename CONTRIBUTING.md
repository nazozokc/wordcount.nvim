# Contributing to wordcount.nvim

Thank you for your interest in contributing to wordcount.nvim! This project is a small Neovim plugin written in Lua for displaying character counts and detailed text statistics.

## Getting Started

1. Fork the repository on GitHub.
2. Clone your fork and create a focused feature branch.
3. Make your changes in the branch.
4. Test the plugin manually with Neovim 0.9 or later.
5. Open a pull request against the `main` branch.

There are currently no external build steps or test framework requirements. Keep changes self-contained and avoid adding dependencies unless they are necessary for the feature.

## Development Guidelines

- Follow the existing Lua style and keep the implementation simple and readable.
- Preserve compatibility with Neovim 0.9 and later.
- Preserve existing public commands, Lua APIs, and configuration options unless the change explicitly updates them.
- Keep user-facing behavior and messages consistent with the existing plugin.
- Pay particular attention to UTF-8 text, including Japanese characters, whitespace, symbols, and emoji.
- Keep each change focused on a single purpose.

## Manual Testing

Load the local plugin in Neovim and verify the affected behavior. At a minimum, check the following when relevant:

- The real-time counter updates while editing a buffer.
- `:WordCount` opens the detailed statistics window and `q` or `Esc` closes it.
- `:WordCountToggle` enables and disables the counter.
- `:WordCountRefresh` refreshes the counter.
- Japanese text, English letters, digits, whitespace, symbols, punctuation, and emoji are handled as expected.
- The counter remains correctly positioned after resizing the editor or changing windows.
- Configuration options such as `position`, `debounce_ms`, and `format` continue to work.

If the change affects the user interface, include a screenshot or a short description of the observed result in the pull request.

## Pull Requests

Please include the following in your pull request:

- A concise summary of the change.
- The motivation or problem it addresses.
- The manual testing performed, including the Neovim version used.
- Screenshots for visual changes, when applicable.
- Notes about compatibility or behavior changes.

Please keep pull requests focused and make sure the documentation is updated when public behavior, commands, or configuration options change.

## License

By contributing to wordcount.nvim, you agree that your contributions will be licensed under the MIT License used by this project.
