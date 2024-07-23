--!nocheck
--
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local sys = {}

function sys.globtopattern(g: string)
  local p = "^" -- pattern being built
  local i = 0 -- index in g
  local c -- char at index i in g.

  -- unescape glob char
  local function unescape()
    if c == "\\" then
      i = i + 1
      c = g:sub(i, i)
      if c == "" then
        p = "[^]"
        return false
      end
    end
    return true
  end

  -- escape pattern char
  local function escape(c)
    return c:match("^%w$") and c or "%" .. c
  end

  -- Convert tokens at end of charset.
  local function charset_end()
    while 1 do
      if c == "" then
        p = "[^]"
        return false
      elseif c == "]" then
        p = p .. "]"
        break
      else
        if not unescape() then
          break
        end
        local c1 = c
        i = i + 1
        c = g:sub(i, i)
        if c == "" then
          p = "[^]"
          return false
        elseif c == "-" then
          i = i + 1
          c = g:sub(i, i)
          if c == "" then
            p = "[^]"
            return false
          elseif c == "]" then
            p = p .. escape(c1) .. "%-]"
            break
          else
            if not unescape() then
              break
            end
            p = p .. escape(c1) .. "-" .. escape(c)
          end
        elseif c == "]" then
          p = p .. escape(c1) .. "]"
          break
        else
          p = p .. escape(c1)
          i = i - 1 -- put back
        end
      end
      i = i + 1
      c = g:sub(i, i)
    end
    return true
  end

  -- Convert tokens in charset.
  local function charset()
    i = i + 1
    c = g:sub(i, i)
    if c == "" or c == "]" then
      p = "[^]"
      return false
    elseif c == "^" or c == "!" then
      i = i + 1
      c = g:sub(i, i)
      if c == "]" then
        -- ignored
      else
        p = p .. "[^"
        if not charset_end() then
          return false
        end
      end
    else
      p = p .. "["
      if not charset_end() then
        return false
      end
    end
    return true
  end

  -- Convert tokens.
  while 1 do
    i = i + 1
    c = g:sub(i, i)
    if c == "" then
      p = p .. "$"
      break
    elseif c == "?" then
      p = p .. "."
    elseif c == "*" then
      p = p .. ".*"
    elseif c == "[" then
      if not charset() then
        break
      end
    elseif c == "\\" then
      i = i + 1
      c = g:sub(i, i)
      if c == "" then
        p = p .. "\\$"
        break
      end
      p = p .. escape(c)
    else
      p = p .. escape(c)
    end
  end
  return p
end

function sys.escapeGsub(str: string): string
  return str
    :gsub("%%", "%%%%")
    :gsub("%.", "%%.")
    :gsub("%(", "%%(")
    :gsub("%)", "%%)")
    :gsub("%+", "%%+")
    :gsub("%-", "%%-")
    :gsub("%^", "%%^")
    :gsub("%$", "%%$")
end

function sys.removeTrailingSlash(str: string): string
  local res = string.gsub(string.gsub(str, "/$", ""), "\\$", "")
  return res
end

function sys.lineCount(str: string): number
  return #str:split("\n")
end

function sys.luaurc(): {}
  return (fs.isFile("./.luaurc") and serde.decode("json", fs.readFile("./.luaurc"))) or {}
end

function sys.normalisePath(str: string): string
  local res = string.gsub(string.gsub(str, "\\", "/"), "/%./", "/")
  return res
end

function sys.normaliseEol(str: string): string
  local res = string.gsub(str, "\x0D\x0A", "\n")
  return res
end

return table.freeze(sys)
