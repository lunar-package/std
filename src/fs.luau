local Path = require("./path")
local fs = require("@lune/fs")
local sys = require("./sys")

local Fs = {}

function Fs.ensureDirExists(path: string)
  if not fs.isDir(path) then
    fs.writeDir(path)
  end
end

function Fs.ensureFileExists(path: string, content: string?)
  Fs.ensureDirExists(Path.dirname(path))

  if not fs.isFile(path) then
    fs.writeFile(path, content or "")
  end
end

function Fs.appendFile(path: string, contents: string): ()
  local ok, content = pcall(fs.readFile, path)
  if ok then
    fs.writeFile(path, content .. contents)
  end
end

function Fs.readDirFlat(dir: string, include_directories: boolean?)
  local flat_files = {}

  local function search_dir(next_dir: string)
    local files = fs.readDir(next_dir)
    for _, v in files do
      local name = next_dir .. "/" .. v
      local md = fs.metadata(name)

      if md.kind == "dir" then
        if include_directories then
          table.insert(flat_files, name)
        end
        search_dir(name)
      elseif md.kind == "file" then
        table.insert(flat_files, name)
      end
    end
  end

  search_dir(dir)

  return flat_files
end

function Fs.filterFiles(files: { string }, filter: string): { string }
  local pattern = if filter then sys.globtopattern(filter) else nil
  local new_files = {}

  for _, file in files do
    if file:match(pattern) then
      table.insert(new_files, file)
    end
  end

  return new_files
end

function Fs.remove(path: string): ()
  if fs.isDir(path) then
    fs.readDir(path)
  elseif fs.isFile(path) then
    fs.removeFile(path)
  end
end

return (setmetatable(Fs, {
  __index = fs,
}) :: any) :: typeof(Fs) & typeof(fs)
