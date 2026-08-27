local M = {}

local function in_range(cp, first, last) return cp >= first and cp <= last end

local function classify(cp)
  if (cp >= 65 and cp <= 90) or (cp >= 97 and cp <= 122) then return "english"
  elseif cp >= 48 and cp <= 57 then return "digits"
  elseif cp == 9 or cp == 11 or cp == 12 or cp == 13 or cp == 32 or cp == 160 then return "whitespace"
  elseif in_range(cp, 0x3040, 0x309f) or in_range(cp, 0x30a0, 0x30ff) or in_range(cp, 0x3400, 0x4dbf) or in_range(cp, 0x4e00, 0x9fff) or in_range(cp, 0xf900, 0xfaff) then return "japanese"
  elseif (cp >= 33 and cp <= 47) or (cp >= 58 and cp <= 64) or (cp >= 91 and cp <= 96) or (cp >= 123 and cp <= 126) or in_range(cp, 0x2000, 0x206f) or in_range(cp, 0x3000, 0x303f) or in_range(cp, 0xff00, 0xff65) then return "symbols" end
  return "other"
end

function M.count(lines)
  local result = { total = 0, japanese = 0, english = 0, digits = 0, whitespace = 0, symbols = 0, other = 0, lines = #lines, words = 0 }
  for _, line in ipairs(lines) do
    local in_word = false
    for _, byte_pos in ipairs(vim.str_utf_pos(line)) do
      local cp = vim.fn.char2nr(line:sub(byte_pos))
      result.total = result.total + 1
      local category = classify(cp); result[category] = result[category] + 1
      if category == "whitespace" then in_word = false elseif not in_word then result.words = result.words + 1; in_word = true end
    end
  end
  return result
end

return M
