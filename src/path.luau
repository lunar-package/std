local constants = require("./internal/constants")
local process = require("./process")
local string = require("./internal/string")

local CHAR_FORWARD_SLASH = constants.CHAR_FORWARD_SLASH
local CHAR_BACKWARD_SLASH = constants.CHAR_BACKWARD_SLASH
local CHAR_COLON = constants.CHAR_COLON
local CHAR_DOT = constants.CHAR_DOT
local CHAR_UPPERCASE_A = constants.CHAR_UPPERCASE_A
local CHAR_UPPERCASE_Z = constants.CHAR_UPPERCASE_Z
local CHAR_LOWERCASE_A = constants.CHAR_LOWERCASE_A
local CHAR_LOWERCASE_Z = constants.CHAR_LOWERCASE_Z

local IS_WIN = process.os == "windows"

type Array<T> = { T }

local function isPathSeparator(code: number)
  return code == CHAR_FORWARD_SLASH or code == CHAR_BACKWARD_SLASH
end

function isPosixPathSeparator(code: number)
  return code == CHAR_FORWARD_SLASH
end

local function isWindowsDeviceRoot(code: number): boolean
  return (code >= CHAR_UPPERCASE_A and code <= CHAR_UPPERCASE_Z)
    or (code >= CHAR_LOWERCASE_A and code <= CHAR_LOWERCASE_Z)
end

local function normalizeString(
  path: string,
  allowAboveRoot: boolean?,
  separator: string,
  isPathSeparator: (code: number) -> boolean
)
  local res = ""
  local lastSegmentLength = 0
  local lastSlash = -1
  local dots = 0
  local code = 0
  for i = 1, #path + 1 do
    if i <= #path then
      code = string.charCodeAt(path, i)
    elseif isPathSeparator(code) then
      break
    else
      code = CHAR_FORWARD_SLASH
    end

    if isPathSeparator(code) then
      if lastSlash == i - 1 or dots == 1 then
      elseif dots == 2 then
        if
          #res < 2
          or lastSegmentLength ~= 2
          or string.charCodeAt(res, #res) ~= CHAR_DOT
          or string.charCodeAt(res, #res - 1) ~= CHAR_DOT
        then
          if #res > 2 then
            local lastSlashIndex = string.lastIndexOf(res, separator)
            if lastSlashIndex == nil then
              res = ""
              lastSegmentLength = 0
            else
              res = string.slice(res, 1, lastSlashIndex)
              lastSegmentLength = #res - 1 - lastSlashIndex
            end
            lastSlash = i
            dots = 0
            continue
          elseif #res ~= 0 then
            res = ""
            lastSegmentLength = 0
            lastSlash = i
            dots = 0
            continue
          end
        end

        if allowAboveRoot then
          res ..= (#res > 0 and `{separator}..` or "..")
          lastSegmentLength = 2
        end
      else
        if #res > 0 then
          res ..= `{separator}{string.slice(path, lastSlash + 1, i)}`
        else
          res = string.slice(path, lastSlash + 1, i)
        end
        lastSegmentLength = i - lastSlash - 1
      end
      lastSlash = i
      dots = 0
    elseif code == CHAR_DOT and dots ~= -1 then
      dots += 1
    else
      dots = -1
    end
    continue
  end

  return res
end

local function formatExt(ext: string?)
  return ext and `{string.sub(ext, 1, 1) == "." and "" or "."}{ext}` or ""
end

local path = {
  win32 = {},
  posix = {},
}

function path.win32.parse(path: string)
  assert(typeof(path) == "string")

  local ret = { root = "", dir = "", base = "", ext = "", name = "" }
  if #path == 0 then
    return ret
  end

  local len = #path
  local rootEnd = 0
  local code = string.charCodeAt(path, 1)

  if len == 1 then
    if isPathSeparator(code) then
      ret.root = path
      ret.dir = path

      return ret
    end
    ret.base = path
    ret.name = path
  end

  if isPathSeparator(code) then
    rootEnd = 2
    if isPathSeparator(string.charCodeAt(path, 2)) then
      local j = 3
      local last = j
      while j <= len and not isPathSeparator(string.charCodeAt(path, j)) do
        j += 1
      end
      if j <= len and j ~= last then
        last = j
        while j <= len and isPathSeparator(string.charCodeAt(path, j)) do
          j += 1
        end
        if j <= len and j ~= last then
          last = j
          while j <= len and not isPathSeparator(string.charCodeAt(path, j)) do
            j += 1
          end

          if j == len then
            rootEnd = j
          elseif j ~= last then
            rootEnd = j + 1
          end
        end
      end
    end
  elseif isWindowsDeviceRoot(code) and string.charCodeAt(path, 2) == CHAR_COLON then
    if len <= 2 then
      ret.root = path
      ret.dir = path
      return ret
    end
    rootEnd = 3
    if isPathSeparator(string.charCodeAt(path, 3)) then
      if len == 3 then
        ret.root = path
        ret.dir = path
        return ret
      end
      rootEnd = 4
    end
  end

  if rootEnd > 0 then
    ret.root = string.slice(path, 1, rootEnd)
  end

  local startDot = -1
  local startPart = rootEnd + 1
  local endPart = -1
  local matchedSlash = true
  local i = len
  local preDotState = 0

  for i = i, rootEnd, -1 do
    code = string.charCodeAt(path, i)
    if isPathSeparator(code) then
      if not matchedSlash then
        startPart = i + 1
        break
      end
      continue
    end
    if endPart == -1 then
      matchedSlash = false
      endPart = i + 1
    end

    if code == CHAR_DOT then
      print("Yes")
      print(preDotState, startDot)
      if startDot == -1 then
        startDot = i
      elseif preDotState ~= 1 then
        preDotState = 1
      end
    elseif startDot ~= -1 then
      preDotState = -1
    end
  end

  if endPart ~= -1 then
    if
      startDot == -1
      or preDotState == 0
      or (preDotState == 1 and startDot == endPart - 1 and startDot == startPart)
    then
      ret.base = string.slice(path, startPart, endPart)
      ret.name = ret.base
    else
      ret.name = string.slice(path, startPart, startDot)
      ret.base = string.slice(path, startPart, endPart)
      ret.ext = string.slice(path, startDot, endPart)
    end
  end

  if startPart > 1 and startPart - 1 ~= rootEnd then
    ret.dir = string.slice(path, 1, startPart - 1)
  else
    ret.dir = ret.root
  end

  return ret
end

function path.win32.dirname(path: string)
  assert(typeof(path) == "string")

  local len = #path
  if len == 0 then
    return "."
  end
  local rootEnd = -1
  local offset = 0
  local code = string.charCodeAt(path, 1)

  if len == 1 then
    return isPathSeparator(code) and path or "."
  end

  if isPathSeparator(code) then
    rootEnd = 2
    offset = 2

    if isPathSeparator(string.charCodeAt(path, 2)) then
      -- Matched double path separator at beginning
      local j = 3
      local last = j
      -- Match 1 or more non-path separators
      while j <= len and not isPathSeparator(string.charCodeAt(path, j)) do
        j += 1
      end
      if j <= len and j ~= last then
        -- Matched!
        last = j
        -- Match 1 or more path separators
        while j <= len and isPathSeparator(string.charCodeAt(path, j)) do
          j += 1
        end
        if j <= len and j ~= last then
          -- Matched!
          last = j
          -- Match 1 or more non-path separators
          while j <= len and not isPathSeparator(string.charCodeAt(path, j)) do
            j += 1
          end
          if j == len then
            -- We matched a UNC root only
            return path
          end
          if j ~= last then
            -- We matched a UNC root with leftovers
            -- Offset by 1 to include the separator after the UNC root to
            -- treat it as a "normal root" on top of a (UNC) root
            rootEnd = j + 1
            offset = rootEnd
          end
        end
      end
    end
  elseif isWindowsDeviceRoot(code) and string.charCodeAt(path, 2) == CHAR_COLON then
    rootEnd = (len > 2 and isPathSeparator(string.charCodeAt(path, 3))) and 3 or 2
    offset = rootEnd
  end

  local endPart = -1
  local matchedSlash = true

  for i = len, offset, -1 do
    if isPathSeparator(string.charCodeAt(path, i)) then
      if not matchedSlash then
        endPart = i
        break
      end
    else
      matchedSlash = false
    end
  end

  if endPart == -1 then
    if rootEnd == -1 then
      return "."
    end
    endPart = rootEnd
  end

  return string.slice(path, 1, endPart)
end

function path.win32.resolve(...: string)
  local args = { ... }
  local resolvedDevice = ""
  local resolvedTail = ""
  local resolvedAbsolute = false

  for i = #args, 0, -1 do
    local path
    if i >= 1 then
      path = args[i]
      assert(typeof(path) == "string")
      if #path == 0 then
        continue
      end
    elseif #resolvedDevice == 0 then
      path = process.cwd()
    else
      path = process.env[`={resolvedDevice}`] or process.cwd()

      if
        path == nil
        or string.lower(string.slice(path, 1, 3)) ~= string.lower(resolvedDevice)
          and string.charCodeAt(path, 3) == CHAR_BACKWARD_SLASH
      then
        path = `{resolvedDevice}\\`
      end
    end

    local len = #path
    local rootEnd = 0
    local device = ""
    local isAbsolute = false
    local code = string.charCodeAt(path, 1)

    if len == 1 then
      if isPathSeparator(code) then
        rootEnd = 2
        isAbsolute = true
      end
    elseif isPathSeparator(code) then
      isAbsolute = true
      if isPathSeparator(string.charCodeAt(path, 2)) then
        local j = 3
        local last = j
        while j <= len and not isPathSeparator(string.charCodeAt(path, j)) do
          j += 1
        end
        if j <= len and j ~= last then
          local firstPart = string.slice(path, last, j)
          last = j
          while j <= len and isPathSeparator(string.charCodeAt(path, j)) do
            j += 1
          end
          if j <= len and j ~= last then
            last = j
            while j <= len and not isPathSeparator(string.charCodeAt(path, j)) do
              j += 1
            end

            if j == len or j ~= last then
              device = `\\\\{firstPart}\\{string.slice(path, last, j)}`
              rootEnd = j
            end
          end
        end
      else
        rootEnd = 2
      end
    elseif isWindowsDeviceRoot(code) and string.charCodeAt(path, 2) == CHAR_COLON then
      device = string.slice(path, 1, 3)
      rootEnd = 3
      if len > 2 and isPathSeparator(string.charCodeAt(path, 3)) then
        isAbsolute = true
        rootEnd = 4
      end
    end

    if resolvedAbsolute then
      if #resolvedDevice > 0 then
        break
      end
    else
      resolvedTail = `{string.slice(path, rootEnd)}\\{resolvedTail}`
      resolvedAbsolute = isAbsolute
      if isAbsolute and #resolvedDevice > 0 then
        break
      end
    end
  end

  resolvedTail = normalizeString(resolvedTail, not resolvedAbsolute, "\\", isPathSeparator)

  return resolvedAbsolute and `{resolvedDevice}\\{resolvedTail}` or `{resolvedDevice}{resolvedTail}` or "."
end

function path.win32.extname(path: string)
  assert(typeof(path) == "string")
  local start = 1
  local startDot = 0
  local startPart = 1
  local endPart = 0
  local matchedSlash = true
  local preDotState = 1

  if #path > 2 and string.charCodeAt(path, 2) == CHAR_COLON and isWindowsDeviceRoot(string.charCodeAt(path, 1)) then
    start = 3
    startPart = 3
  end

  for i = #path, start, -1 do
    local code = string.charCodeAt(path, i)
    if isPathSeparator(code) then
      if not matchedSlash then
        start = i + 1
        break
      end
      continue
    end

    if endPart == 0 then
      matchedSlash = false
      endPart = i + 1
    end

    if code == CHAR_DOT then
      if startDot == 0 then
        startDot = i
      elseif preDotState ~= 2 then
        preDotState = 2
      end
    elseif startDot ~= 0 then
      preDotState = 0
    end
  end

  if
    startDot == 0
    or endPart == 0
    or preDotState == 1
    or (preDotState == 2 and startDot == endPart - 1 and startDot == startPart + 1)
  then
    return ""
  end

  return string.slice(path, startDot, endPart)
end

function path.win32.basename(path: string, suffix: string?)
  if suffix ~= nil then
    assert(typeof(suffix) == "sring")
  end
  assert(typeof(path) == "string")

  local start = 1
  local endPart = -1
  local matchedSlash = true

  if #path >= 2 and isWindowsDeviceRoot(string.charCodeAt(path, 1)) and string.charCodeAt(path, 2) == CHAR_COLON then
    start = 3
  end

  if suffix ~= nil and #suffix > 0 and #suffix <= #path then
    if suffix == path then
      return ""
    end
    local extIdx = #suffix
    local firstNonSlashEnd = -1
    for i = #path, start, -1 do
      local code = string.charCodeAt(path, i)
      if isPathSeparator(code) then
        if not matchedSlash then
          start = i + 1
          break
        end
      else
        if firstNonSlashEnd == -1 then
          matchedSlash = false
          firstNonSlashEnd = i + 1
        end

        if extIdx >= 1 then
          if code == string.charCodeAt(suffix, extIdx) then
            extIdx -= 1
            if extIdx == 0 then
              endPart = i
            end
          else
            extIdx = -1
            endPart = firstNonSlashEnd
          end
        end
      end
    end

    if start == endPart then
      endPart = firstNonSlashEnd
    elseif endPart == -1 then
      endPart = #path
    end

    return string.slice(path, start, endPart)
  end

  for i = #path, start, -1 do
    if isPathSeparator(string.charCodeAt(path, i)) then
      if not matchedSlash then
        start = i + 1
        break
      end
    elseif endPart == -1 then
      matchedSlash = false
      endPart = i + 1
    end
  end

  if endPart == -1 then
    return ""
  end

  return string.slice(path, start, endPart)
end

local function posixCwd()
  if process.os == "windows" then
    local cwd = string.gsub(process.cwd(), "\\", "/")
    return string.match(cwd, "/(.*)") or cwd -- Slice to remove drive indicator
  end

  return process.cwd()
end

function path.posix.dirname(path: string)
  assert(typeof(path) == "string")

  if #path == 0 then
    return "."
  end
  local hasRoot = string.charCodeAt(path, 1) == CHAR_FORWARD_SLASH
  local endPart = -1
  local matchedSlash = true
  for i = #path, 2, -1 do
    if string.charCodeAt(path, i) == CHAR_FORWARD_SLASH then
      if not matchedSlash then
        endPart = i
        break
      end
    else
      matchedSlash = false
    end
  end

  if endPart == -1 then
    return hasRoot and "/" or "."
  end
  if hasRoot and endPart == 2 then
    return "/"
  end

  return string.slice(path, 1, endPart)
end

function path.posix.parse(path: string)
  assert(typeof(path) == "string")

  local ret = { root = "", dir = "", base = "", ext = "", name = "" }
  if #path == 0 then
    return ret
  end

  local isAbsolute = string.charCodeAt(path, 1) == CHAR_FORWARD_SLASH
  local start
  if isAbsolute then
    ret.root = "/"
    start = 2 -- Start at index 2 for 1-based indexing
  else
    start = 1
  end

  local startDot = -1
  local startPart = 0
  local endPart = -1
  local matchedSlash = true
  local i = #path

  local preDotState = 0

  for i = #path, start, -1 do
    local code = string.charCodeAt(path, i)
    if code == CHAR_FORWARD_SLASH then
      if not matchedSlash then
        startPart = i + 1
        break
      end
    else
      if endPart == -1 then
        matchedSlash = false
        endPart = i + 1
      end
      if code == CHAR_DOT then
        if startDot == -1 then
          startDot = i
        elseif preDotState ~= 1 then
          preDotState = 1
        end
      elseif startDot ~= -1 then
        preDotState = -1
      end
    end
  end

  if endPart ~= -1 then
    local start = startPart == 0 and isAbsolute and 2 or startPart
    if
      startDot == -1
      or preDotState == 0
      or (preDotState == 1 and startDot == endPart - 1 and startDot == startPart + 1)
    then
      ret.base = string.slice(path, start, endPart)
      ret.name = ret.base
    else
      ret.name = string.slice(path, start, startDot)
      ret.base = string.slice(path, start, endPart)
      ret.ext = string.slice(path, startDot, endPart)
    end
  end

  if startPart > 0 then
    ret.dir = string.slice(path, 1, startPart - 1)
  elseif isAbsolute then
    ret.dir = "/"
  end

  return ret
end

function path.posix.resolve(...: string)
  local resolvedPath = ""
  local resolvedAbsolute = false
  local args = { ... }

  for i = #args, 0, -1 do
    if resolvedAbsolute then
      break
    end
    local path = i >= 1 and args[i] or posixCwd()
    assert(typeof(path) == "string")
    if #path == 0 then
      continue
    end

    resolvedPath = `{path}/{resolvedPath}`
    resolvedAbsolute = string.charCodeAt(path, 1) == CHAR_FORWARD_SLASH
  end

  resolvedPath = normalizeString(resolvedPath, not resolvedAbsolute, "/", isPosixPathSeparator)

  if resolvedAbsolute then
    return `/{resolvedPath}`
  end

  return #resolvedPath > 0 and resolvedPath or "."
end

function path.posix.extname(path: string)
  assert(typeof(path) == "string")
  local startDot = 0
  local startPart = 1
  local endPart = 0
  local matchedSlash = true

  local preDotState = 1
  for i = #path, 1, -1 do
    local code = string.charCodeAt(path, i)
    if code == CHAR_FORWARD_SLASH then
      if not matchedSlash then
        startPart = i + 1
        break
      end
      continue
    end

    if endPart == 0 then
      matchedSlash = false
      endPart = i + 1
    end

    if code == CHAR_DOT then
      if startDot == 0 then
        startDot = i
      elseif preDotState ~= 2 then
        preDotState = 2
      end
    elseif startDot ~= 0 then
      preDotState = 0
    end
  end

  if
    startDot == 0
    or endPart == 0
    or preDotState == 1
    or (preDotState == 2 and startDot == endPart - 1 and startDot == startPart + 1)
  then
    return ""
  end

  return string.slice(path, startDot, endPart)
end

function path.posix.basename(path: string, suffix: string?)
  if suffix ~= nil then
    assert(typeof(suffix) == "string")
  end
  assert(typeof(path) == "string")
  local start = 0
  local endPart = -1
  local matchedSlash = true

  if suffix ~= nil and #suffix > 0 and #suffix <= #path then
    if suffix == path then
      return ""
    end
    local extIdx = #suffix
    local firstNonSlashEnd = -1
    for i = #path, 1, -1 do
      local code = string.charCodeAt(path, i)
      if code == CHAR_FORWARD_SLASH then
        if not matchedSlash then
          start = i + 1
          break
        end
      else
        if firstNonSlashEnd == -1 then
          matchedSlash = false
          firstNonSlashEnd = i + 1
        end

        if extIdx >= 1 then
          if code == string.charCodeAt(suffix, extIdx) then
            extIdx -= 1
            if extIdx == 0 then
              endPart = i
            end
          else
            extIdx = 0
            endPart = firstNonSlashEnd
          end
        end
      end
    end

    if start == endPart then
      endPart = firstNonSlashEnd
    elseif endPart == -1 then
      endPart = #path
    end
    return string.slice(path, start, endPart)
  end

  for i = #path, 1, -1 do
    if string.charCodeAt(path, i) == CHAR_FORWARD_SLASH then
      if not matchedSlash then
        start = i + 1
        break
      end
    elseif endPart == -1 then
      matchedSlash = false
      endPart = i + 1
    end
  end

  if endPart == -1 then
    return ""
  end

  return string.slice(path, start, endPart)
end

export type ParsedPath = {
  root: string,
  dir: string,
  base: string,
  ext: string,
  name: string,
}

export type Path = {
  basename: (path: string, suffix: string?) -> string,
  dirname: (path: string) -> string,
  extname: (path: string) -> string,
  resolve: (...string) -> string,
  parse: (path: string) -> ParsedPath,
}

return table.freeze((IS_WIN and path.win32 or path.posix)) :: Path
