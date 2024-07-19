--!strict

local path = require("./path")
local process = require("./process")
local sys = require("./sys")

local IS_WIN = process.os == "windows"
local SEP = IS_WIN and "\\" or "/"

local Os = {}

function Os.homedir(): string
  local home = process.env[IS_WIN and "USERPROFILE" or "HOME"]

  if string.sub(home, -1) == SEP then
    home = string.sub(home, 1, #home - 1)
  end

  home = sys.removeTrailingSlash(home)

  return home
end

function Os.tempdir(): string
  local temp = process.env["TEMP"] or process.env["TMP"] or process.env["TMPDIR"] or "/tmp/"

  if string.sub(temp, -1) == SEP then
    temp = string.sub(temp, 1, #temp - 1)
  end

  temp = sys.removeTrailingSlash(temp)

  return temp
end

function Os.userInfo(): UserInfo
  local username = process.env["USERNAME"] or process.env["USER"] or ""
  local homedir = Os.homedir()

  if username == "" then
    username = path.basename(homedir)
  end

  return {
    username = username,
    homedir = homedir,
  }
end

export type UserInfo = {
  username: string,
  homedir: string,
}

export type Os = {
  homedir: () -> string,
  tempdir: () -> string,
  userInfo: () -> UserInfo,
} & typeof(os)

return (setmetatable(Os, {
  __index = os,
}) :: any) :: Os
