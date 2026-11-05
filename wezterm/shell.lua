local wezterm = require('wezterm')

local shell_module = {}

-------------------------------------------------------------------------------
-- Platform detection
-------------------------------------------------------------------------------

-- Returns true if `text` contains `substring` (plain text, not a Lua pattern)
local function contains(text, substring)
  return text:find(substring, 1, true) ~= nil -- search from the start, plain text
end

local IS_WINDOWS = contains(wezterm.target_triple, 'windows')
local IS_MAC = contains(wezterm.target_triple, 'darwin')

-------------------------------------------------------------------------------
-- Settings (edit these to customize)
-------------------------------------------------------------------------------

-- Linux/macOS shells to try, in order of preference
local UNIX_SHELLS = { 'zsh', 'bash', 'ash', 'sh' }

-- Arguments passed to whichever Unix shell is found. Every flag here must
-- work in all of the shells in UNIX_SHELLS.
--   -l  start as a login shell, so profile files load
local UNIX_SHELL_ARGS = { '-l' }

-- Arguments passed to PowerShell. These are separate lists because some
-- PowerShell 7 flags don't exist in 5.1.
--   -NoLogo  hide the startup banner
local PWSH_ARGS = { '-NoLogo' }
local WINDOWS_POWERSHELL_ARGS = { '-NoLogo' }

-- Package manager folders, searched before PATH so a shell installed with
-- Homebrew or Nix wins over the system one. (Apps opened from the macOS
-- Dock don't have these folders on their PATH.)
-- In these lists, "~/" is your home folder and "$NAME" is an environment
-- variable. A folder that uses an unset or empty variable is skipped.
local MAC_HOMEBREW_FOLDERS = {
  '/opt/homebrew/bin', -- Apple Silicon
  '/usr/local/bin',    -- Intel
}

local LINUX_HOMEBREW_FOLDERS = {
  '/home/linuxbrew/.linuxbrew/bin',
}

-- Used on both macOS and Linux
local NIX_FOLDERS = {
  '~/.nix-profile/bin',                -- your packages (nix profile, nix-env)
  '~/.local/state/nix/profile/bin',    -- same, when Nix uses XDG folders
  '/etc/profiles/per-user/$USER/bin',  -- Home Manager and nix-darwin user packages
  '/nix/var/nix/profiles/default/bin', -- packages installed for all users
  '/run/current-system/sw/bin',        -- NixOS and nix-darwin system packages
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

-- Joins path parts with the platform's folder separator
local function join_path(...)
  local separator = IS_WINDOWS and '\\' or '/'
  return table.concat({ ... }, separator)
end

-- Returns the last part of a path, e.g. "pwsh.exe" from "C:\Apps\pwsh.exe"
local function get_file_name(path)
  return path:match('[^\\/]+$')
end

-- Adds every item from `source` to the end of `target`
local function append_all(target, source)
  for _, item in ipairs(source) do
    table.insert(target, item)
  end
end

-- Replaces a leading "~/" with the home folder and each "$NAME" with that
-- environment variable. Returns nil if a variable is unset or empty.
local function expand_folder(folder)
  local has_missing_variable = false

  local expanded = folder:gsub('^~/', function()
    return wezterm.home_dir .. '/'
  end)

  expanded = expanded:gsub('%$([%a_][%w_]*)', function(variable_name)
    local value = os.getenv(variable_name)
    if value == nil or value == '' then
      has_missing_variable = true
      return ''
    end
    return value
  end)

  if has_missing_variable then
    return nil
  end
  return expanded
end

-- Adds each folder to the end of `target` after expanding it, skipping any
-- folder that can't be expanded
local function append_expanded_folders(target, folders)
  for _, folder in ipairs(folders) do
    local expanded_folder = expand_folder(folder)
    if expanded_folder then
      table.insert(target, expanded_folder)
    end
  end
end

-- Returns a command list: the program followed by its arguments
local function build_command(program_path, args)
  local command = { program_path }
  append_all(command, args)
  return command
end

-- Returns true if a file exists at the given path. On Linux/macOS a folder
-- with that name also counts; plain Lua can't tell the two apart.
local function file_exists(path)
  local file_handle = io.open(path, 'r')
  if file_handle then
    file_handle:close()
    return true
  end
  return false
end

-- Returns the full path to the program in the first folder that has it,
-- otherwise nil
local function find_in_folders(program_name, folders)
  for _, folder in ipairs(folders) do
    local full_path = join_path(folder, program_name)
    if file_exists(full_path) then
      return full_path
    end
  end

  return nil
end

-- Returns the folders listed in the PATH environment variable
local function get_path_folders()
  local folders = {}
  local path_env = os.getenv('PATH') or ''

  -- PATH separates folders with ';' on Windows and ':' everywhere else.
  -- Each run of characters that isn't the separator is one folder.
  local separator = IS_WINDOWS and ';' or ':'
  local folder_pattern = '[^' .. separator .. ']+'

  for folder in path_env:gmatch(folder_pattern) do
    table.insert(folders, folder)
  end

  return folders
end

-- Returns the full path to the program if it's on PATH, otherwise nil
local function find_on_path(program_name)
  return find_in_folders(program_name, get_path_folders())
end

-------------------------------------------------------------------------------
-- PowerShell 7 lookups
-------------------------------------------------------------------------------

-- Used in three places, so it's named once here
local PWSH_EXE = 'pwsh.exe'

-- Location used by the PowerShell 7 installer and winget
local function find_installer_pwsh()
  local program_files = os.getenv('ProgramFiles') or 'C:\\Program Files'
  local pwsh_path = join_path(program_files, 'PowerShell', '7', PWSH_EXE)

  if file_exists(pwsh_path) then
    return pwsh_path
  end
  return nil
end

-- The Microsoft Store version of PowerShell 7 is an "app execution alias",
-- which io.open can't open. Look for it in the folder listing instead.
local function find_store_pwsh()
  local local_app_data = os.getenv('LOCALAPPDATA')
  if not local_app_data then
    return nil
  end

  local store_apps_folder = join_path(local_app_data, 'Microsoft', 'WindowsApps')
  local read_succeeded, entry_paths = pcall(wezterm.read_dir, store_apps_folder)
  if not read_succeeded then
    return nil
  end

  for _, entry_path in ipairs(entry_paths) do
    local file_name = get_file_name(entry_path)
    if file_name and file_name:lower() == PWSH_EXE then
      return entry_path
    end
  end

  return nil
end

-------------------------------------------------------------------------------
-- Shell selection
-------------------------------------------------------------------------------

-- PowerShell 7 if installed, otherwise Windows PowerShell 5.1
local function get_windows_shell_command()
  local pwsh_path = find_on_path(PWSH_EXE)
    or find_installer_pwsh()
    or find_store_pwsh()

  if pwsh_path then
    return build_command(pwsh_path, PWSH_ARGS)
  end

  wezterm.log_warn('PowerShell 7 not found, falling back to Windows PowerShell 5.1')
  return build_command('powershell.exe', WINDOWS_POWERSHELL_ARGS)
end

-- Folders to search on Linux/macOS, in order: Homebrew, Nix, then PATH
local function get_unix_search_folders()
  local homebrew_folders = IS_MAC and MAC_HOMEBREW_FOLDERS or LINUX_HOMEBREW_FOLDERS
  local search_folders = {}

  append_expanded_folders(search_folders, homebrew_folders)
  append_expanded_folders(search_folders, NIX_FOLDERS)
  append_all(search_folders, get_path_folders())

  return search_folders
end

-- First shell from UNIX_SHELLS that's installed. For each shell, a
-- package manager's copy is preferred over the system one.
local function get_unix_shell_command()
  local search_folders = get_unix_search_folders()

  for _, shell_name in ipairs(UNIX_SHELLS) do
    local shell_path = find_in_folders(shell_name, search_folders)
    if shell_path then
      return build_command(shell_path, UNIX_SHELL_ARGS)
    end
  end

  local tried_shells = table.concat(UNIX_SHELLS, ', ')
  wezterm.log_warn('No shell found (tried ' .. tried_shells .. '); using WezTerm default shell')
  return nil
end

-------------------------------------------------------------------------------
-- Public
-------------------------------------------------------------------------------

function shell_module.apply_to_config(config)
  local shell_command

  if IS_WINDOWS then
    shell_command = get_windows_shell_command()
  else
    shell_command = get_unix_shell_command()
  end

  if shell_command then
    config.default_prog = shell_command
  end
end

return shell_module