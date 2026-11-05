local M = {}

local function frontmatter_end(lines, delimiter)
  for index = 2, #lines do
    if lines[index] == delimiter or (delimiter == "---" and lines[index] == "...") then
      return index
    end
  end
end

function M.remove_frontmatter(lines)
  local delimiter = lines[1] == "---" and "---" or lines[1] == "+++" and "+++"
  if not delimiter then return lines end

  local ending = frontmatter_end(lines, delimiter)
  if not ending then return lines end

  local content = {}
  for index = ending + 1, #lines do
    content[#content + 1] = lines[index]
  end
  return content
end

local function in_range(cp, first, last) return cp >= first and cp <= last end

local function is_japanese(cp)
  return in_range(cp, 0x3040, 0x309f) -- Hiragana
    or in_range(cp, 0x30a0, 0x30ff) -- Katakana
    or in_range(cp, 0x31f0, 0x31ff) -- Katakana phonetic extensions
    or in_range(cp, 0xff66, 0xff9f) -- Halfwidth Katakana
    or in_range(cp, 0x1b000, 0x1b16f) -- Kana Supplement / Extended-A
    or in_range(cp, 0x3400, 0x4dbf) -- CJK Unified Ideographs Extension A
    or in_range(cp, 0x4e00, 0x9fff) -- CJK Unified Ideographs
    or in_range(cp, 0x20000, 0x2fa1f) -- CJK Unified Ideographs Extension B-F
    or in_range(cp, 0xf900, 0xfaff) -- CJK Compatibility Ideographs
    or cp == 0x3005 -- 々
    or cp == 0x3006 -- 〆
    or cp == 0x3007 -- 〇
    or cp == 0x303b -- 〻
end

local function is_whitespace(cp)
  return cp == 9 or cp == 11 or cp == 12 or cp == 13 or cp == 32 or cp == 160
    or cp == 0x1680
    or in_range(cp, 0x2000, 0x200a)
    or cp == 0x2028 or cp == 0x2029 or cp == 0x202f or cp == 0x205f
    or cp == 0x3000 -- ideographic space
end

local function classify(cp)
  if (cp >= 65 and cp <= 90) or (cp >= 97 and cp <= 122)
    or in_range(cp, 0xff21, 0xff3a) or in_range(cp, 0xff41, 0xff5a) then
    return "english"
  elseif (cp >= 48 and cp <= 57) or in_range(cp, 0xff10, 0xff19) then
    return "digits"
  elseif is_whitespace(cp) then
    return "whitespace"
  elseif is_japanese(cp) then
    return "japanese"
  elseif (cp >= 33 and cp <= 47) or (cp >= 58 and cp <= 64) or (cp >= 91 and cp <= 96) or (cp >= 123 and cp <= 126)
    or in_range(cp, 0x2000, 0x206f) or in_range(cp, 0x3000, 0x303f) or in_range(cp, 0xff00, 0xff65) then
    return "symbols"
  end
  return "other"
end

function M.count(lines)
  local result = { total = 0, japanese = 0, english = 0, digits = 0, whitespace = 0, symbols = 0, other = 0, lines = #lines, words = 0 }
  for _, line in ipairs(lines) do
    local in_word = false
    for _, cp in ipairs(vim.fn.str2list(line)) do
      result.total = result.total + 1
      local category = classify(cp)
      result[category] = result[category] + 1
      if category == "whitespace" then
        in_word = false
      elseif not in_word then
        result.words = result.words + 1
        in_word = true
      end
    end
  end
  return result
end

return M
