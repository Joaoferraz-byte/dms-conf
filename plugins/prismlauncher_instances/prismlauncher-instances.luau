--!nonstrict

local function getConfiguredLauncherPath()
    local configured = noctalia.getConfig("prism_path")
    return noctalia.expandPath(configured)
end

local function getLauncherCommand()
    local launcherCommand = noctalia.getConfig("launcher_exec_command")
    return noctalia.expandPath(launcherCommand)
end

local launcherConfigNames = {
    "freesmlauncher.cfg",
    "prismlauncher.cfg",
    "polymc.cfg",
    "multimc.cfg",
}

local function findLauncherConfig(root)
    if not root or root == "" then return nil end
    for _, name in ipairs(launcherConfigNames) do
        local candidate = root .. "/" .. name
        if noctalia.fileExists(candidate) then
            return candidate
        end
    end

    -- Forks retain the Prism INI format but may use a custom filename. Globs
    -- are not supported by readFile, so enumerate deterministic top-level cfgs.
    local candidates = {}
    local entries = noctalia.listDir(root)
    if entries then
        for _, name in ipairs(entries) do
            if name:match("%.[cC][fF][gG]$") or name:match("%.[iI][nN][iI]$") then
                table.insert(candidates, name)
            end
        end
    end
    table.sort(candidates)
    for _, name in ipairs(candidates) do
        local candidate = root .. "/" .. name
        if getCfgValue(candidate, "InstanceDir") ~= nil then
            return candidate
        end
    end
    return nil
end

local function resolveInstanceDir(root, launcherConfig)
    local configured = launcherConfig and getCfgValue(launcherConfig, "InstanceDir") or nil
    if not configured or configured == "" then
        return root .. "/instances"
    end
    configured = noctalia.expandPath(configured)
    if configured:sub(1, 1) == "/" then
        return configured
    end
    return root .. "/" .. configured
end

local resolvedRoot
local resolvedConfig
local resolvedInstances
local function resolveLauncher()
    if resolvedInstances then
        return resolvedRoot, resolvedConfig, resolvedInstances
    end

    local configured = getConfiguredLauncherPath()
    local roots = {
        configured,
        "~/.local/share/FreesmLauncher",
        "~/.local/share/PrismLauncher",
        "~/.var/app/org.freesmlauncher.FreesmLauncher/data/FreesmLauncher",
        "~/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher",
    }
    local seen = {}
    for _, candidateRoot in ipairs(roots) do
        if candidateRoot and candidateRoot ~= "" then
            local root = noctalia.expandPath(candidateRoot)
            if not seen[root] then
                seen[root] = true
                local config = findLauncherConfig(root)
                local instances = config and resolveInstanceDir(root, config) or nil
                if instances and noctalia.listDir(instances) ~= nil then
                    resolvedRoot = root
                    resolvedConfig = config
                    resolvedInstances = instances
                    noctalia.log("Launcher instances root selected: " .. root .. " (" .. (config or "no config") .. ")")
                    return resolvedRoot, resolvedConfig, resolvedInstances
                end
            end
        end
    end

    resolvedRoot = noctalia.expandPath(configured)
    resolvedInstances = resolvedRoot .. "/instances"
    noctalia.log("Launcher instances root unavailable; using configured fallback: " .. resolvedInstances)
    return resolvedRoot, nil, resolvedInstances
end

local function getLauncherRoot()
    local root = resolveLauncher()
    return root
end

local function getInstancesDir()
    local _, _, instances = resolveLauncher()
    return instances
end

local function loadInstances()
    local instances = {}
    local instancesDir = getInstancesDir()
    local list = noctalia.listDir(instancesDir)
    if list ~= nil then
        for _, name in ipairs(list) do
            local instanceDir = instancesDir .. "/" .. name
            if name ~= "" and noctalia.fileExists(instanceDir .. "/instance.cfg") then
                table.insert(instances, name)
            end
        end
    end
    table.sort(instances)
    return instances
end

local function instanceName(path)
  local instanceCfg = getInstancesDir() .. "/" .. path .. "/instance.cfg"
  local configuredName = getCfgValue(instanceCfg, "name")
  if configuredName ~= nil then
      return configuredName
  end
  return path:match("([^/]+)$") or path
end

local function filterInstances(instances, query)
  if query == "" then return instances end
  local results = {}
  for _, path in instances do
    local insName = instanceName(path)
    if insName:lower():find(query:lower(), 1, true) then
      table.insert(results, path)
    end
  end
  return results
end

local function makeRows(instances)
  local rows = {}
  for _, path in instances do
    table.insert(rows, {
      id = path,
      title = instanceName(path),
      subtitle = path,
      icon = getIcon(path),
      glyph = "nut",
    })
  end
  return rows
end

local function showResults(query, instances, filter)
  local filtered = filterInstances(instances, filter)
  if #filtered == 0 then
    launcher.setResults(query, {
        { id = "", title = noctalia.tr("no_instances.title"), subtitle = filter ~= "" and noctalia.tr("no_instances.subtitle") .. filter, glyph = "folder-x" }
    })
  else
    launcher.setResults(query, makeRows(filtered))
  end
end

function onQuery(query)
  local filter = noctalia.string.trim(query)
  showResults(query,  loadInstances(), filter)
end

local function splitCommand(command)
  local argv = {}
  for token in command:gmatch("%S+") do
    table.insert(argv, token)
  end
  return argv
end

function onActivate(id)
  if id == "" then return end

  local argv = splitCommand(getLauncherCommand())
  if #argv == 0 then
    noctalia.notify("FreeSM Launcher", "No launcher command is configured.")
    return
  end
  table.insert(argv, "--launch")
  table.insert(argv, id)

  local accepted = noctalia.runAsync(argv, function(result)
    if result.exitCode ~= 0 then
      noctalia.log("FreeSM Launcher failed: " .. (result.stderr or "unknown error"))
      noctalia.notify("FreeSM Launcher", "Unable to launch instance " .. id .. ".")
    end
  end)
  if not accepted then
    noctalia.notify("FreeSM Launcher", "The launch request was not accepted.")
  end
end

-- doesn't handle icons that were changed to different default icon, rest is fine
-- never change icons since creating instance => OK
-- change icon to manually provided icon or to icon from mod provider => OK
-- change icon to different default icon baked into prism binary => NOK, old icon will be shown because <instance>/minecraft/icon.png isn't updated
function getIcon(instancePath)
    local instanceFullPath = getInstancesDir() .. "/" .. instancePath
    local defaultIcon =  instanceFullPath .. "/minecraft/icon.png"
    local cfgPath = instanceFullPath .. "/instance.cfg"
    local iconVal = getCfgValue(cfgPath, "iconKey")
    if (iconVal == nil) then
        return defaultIcon
    end

    local iconDir = getLauncherRoot() .. "/icons/"
    local bestIcon = findBestIconIn(iconDir, iconVal)

    if (bestIcon == nil) then
        return defaultIcon
    end
    return bestIcon
end



-- https://github.com/PrismLauncher/PrismLauncher/blob/d2fa7cf7f7aa8fa5e3d4f5f7b474621c732cd525/launcher/icons/IconUtils.cpp
local validIconExtensions = { "svg", "png", "ico", "gif", "jpg", "jpeg", "webp" }

local function isIconSuffix(suffix)
    for _, ext in ipairs(validIconExtensions) do
        if ext == suffix then
            return true
        end
    end
    return false
end

local function splitNameAndSuffix(filename)
    local dotIndex = filename:find("%.[^.]*$")
    if not dotIndex then
        return filename, ""
    end
    local base = filename:sub(1, dotIndex - 1)
    local suffix = filename:sub(dotIndex + 1)
    return base, suffix
end

function findBestIconIn(folder, iconKey)
    local entries = noctalia.listDir(folder)
    if not entries then
        return nil
    end

    for _, filename in ipairs(entries) do
        local baseName, suffix = splitNameAndSuffix(filename)
        if (baseName == iconKey or filename == iconKey) and isIconSuffix(suffix) then
            local sep = folder:sub(-1) == "/" and "" or "/"
            return folder .. sep .. filename
        end
    end

    return nil
end



function getCfgValue(cfgPath, key) -- naive INI value fetcher, doesn't handle sections, it's enough for this usecase
    local content, err = noctalia.readFile(cfgPath)
    if not content then
        noctalia.log("Failed to read file ".. cfgPath .. " : " .. tostring(err))
        return nil
    end

    for line in content:gmatch("[^\r\n]+") do
        if line:sub(1, #key + 1) == key .. "=" then
            return line:sub(#key + 2)
        end
    end

    return nil
end
