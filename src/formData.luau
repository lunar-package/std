--!strict

export type Name = string
export type Value = string

export type Entry = {
  name: Name,
  value: Value,
  filename: string?,
}

export type FormDataImpl = {
  __index: FormDataImpl,
  new: () -> FormData,
  append: (self: FormData, name: Name, value: Value, fileName: string?) -> (),
  delete: (self: FormData, name: Name) -> (),
  entries: (self: FormData) -> { { Name | Value } },
  get: (self: FormData, name: Name) -> string?,
  getAll: (self: FormData, name: Name) -> { Value },
  has: (self: FormData, name: Name) -> boolean,
  keys: (self: FormData) -> { Name },
  set: (self: FormData, name: Name, value: Value, fileName: string?) -> (),
  values: (self: FormData) -> { Value },
  toString: (self: FormData) -> string,
  toJSON: (self: FormData) -> string,
  decode: (self: FormData) -> string,
}

export type FormData = typeof(setmetatable({} :: { entries: { Entry }, uuid: string }, {} :: FormDataImpl))

local FILE_FORMATS = {
  jpg = "image/jpg",
  jpeg = "image/jpeg",
  png = "image/png",
  webp = "image/webp",
  gif = "image/gif",

  csv = "text/csv",
  txt = "text/plain",
  css = "text/css",
  js = "text/javascript",
  html = "text/html",

  mp4 = "video/mp4",
}

local FormData = {} :: FormDataImpl
FormData.__index = FormData

function FormData.new(): FormData
  local uuid = `DiscordLuau.{math.random()}`
  local self = setmetatable({
    entries = {},
    uuid = uuid,
  }, FormData)

  return (self :: unknown) :: FormData
end

function FormData.append(self: FormData, name: Name, value: Value, fileName: string?)
  local entry: Entry = { name = name, value = value, filename = fileName }

  table.insert(self.entries, entry)
end

function FormData.delete(self: FormData, name: string)
  for i, entry in self.entries do
    if entry.name == name then
      table.remove(self.entries, i)
    end
  end
end

function FormData.entries(self: FormData): { { Name | Value } }
  local entries = {}
  for _, entry in self.entries do
    table.insert(entries, { entry.name, entry.value })
  end

  return entries
end

function FormData.get(self: FormData, name: Name): Value?
  for _, entry in self.entries do
    if entry.name == name then
      return entry.value
    end
  end

  return nil
end

function FormData.getAll(self: FormData, name: Name): { Value }
  local values: { Value } = {}
  for _, entry in self.entries do
    if entry.name == name then
      table.insert(values, entry.value)
    end
  end

  return values
end

function FormData.has(self: FormData, name: Name): boolean
  for _, entry in self.entries do
    if entry.name == name then
      return true
    end
  end

  return false
end

function FormData.keys(self: FormData): { Name }
  local keys = {}
  for _, entry in self.entries do
    table.insert(keys, entry.name)
  end

  return keys
end

function FormData.set(self: FormData, name: Name, value: Value, fileName: string?)
  for _, entry in self.entries do
    if entry.name == name then
      entry.value = value
      entry.filename = fileName
      return
    end
  end
  self:append(name, value, fileName)
end

function FormData.values(self: FormData): { Value }
  local values: { Value } = {}
  for _, entry in self.entries do
    table.insert(values, entry.value)
  end

  return values
end

function FormData.toString(self: FormData)
  local boundary = `{self.uuid}`

  local lines = {}

  for index, entry in self.entries do
    local fileName = entry.filename or ""
    local contentName: string = entry.name

    local fileFormat: string

    if entry.name == "payload_json" then
      fileFormat = "application/json"
    else
      local fileType = string.match(fileName :: string, ".+%.(%S+)")
      fileFormat = FILE_FORMATS[fileType] or "text/plain"
    end

    local disposition = `Content-Disposition: form-data; name="{contentName}"`

    if fileName ~= "" then
      disposition ..= `; filename="{fileName}"`
    end

    table.insert(lines, `--{boundary}`)
    table.insert(lines, disposition)
    table.insert(lines, `Content-Type: {fileFormat}`)
    table.insert(lines, "")
    table.insert(lines, entry.value)
  end

  table.insert(lines, "--" .. boundary .. "--")

  return table.concat(lines, "\r\n")
end

FormData.toJSON = FormData.toString
FormData.decode = FormData.toString

return FormData
