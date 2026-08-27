# wordcount.nvim

A Lua plugin for displaying the character count of the current Neovim buffer in real time.

It counts Japanese characters, English letters, digits, whitespace, symbols, and other characters. Detailed statistics are available in a floating window.

## Requirements

- Neovim 0.9 or later

## Installation

### lazy.nvim

```lua
{
  "nazozokc/wordcount.nvim",
  config = function()
    require("wordcount").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "nazozokc/wordcount.nvim",
  config = function()
    require("wordcount").setup()
  end,
}
```

## Configuration

```lua
require("wordcount").setup({
  enabled = true,
  position = "top_right", -- top_left / top_right / bottom_left / bottom_right
  debounce_ms = 100,
  format = "Characters: %d",
})
```

When no configuration is provided, the counter is displayed in the top-right corner as `Characters: N`.

## Commands

### `:WordCount`

Displays detailed statistics for the current buffer in a floating window:

- Total characters
- Japanese characters
- English letters
- Digits
- Whitespace
- Symbols and punctuation
- Other characters
- Lines
- Words

Press `q` or `Esc` to close the details window.

### `:WordCountToggle`

Enables or disables the real-time counter.

### `:WordCountRefresh`

Manually refreshes the counter.

## Counting Rules

- Characters are counted as UTF-8 Unicode code points.
- Newlines are excluded from the character and category counts.
- Japanese characters include major Hiragana, Katakana, and Kanji Unicode ranges.
- English letters are ASCII `A-Z` and `a-z`.
- Digits are ASCII `0-9`.
- Unsupported characters and emoji are classified as `Other`.

Combining characters and emoji are counted by Unicode code point rather than by their visual appearance.

## Lua API

```lua
local wordcount = require("wordcount")

wordcount.enable()
wordcount.disable()
wordcount.toggle()
wordcount.refresh()
wordcount.details()
```

## License

MIT License
