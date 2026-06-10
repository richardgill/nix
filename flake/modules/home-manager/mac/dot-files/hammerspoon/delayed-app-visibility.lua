local M = {}

local entries = {}
local watcher = nil

local function log(entry, message)
	local file = io.open(os.getenv("HOME") .. "/.hammerspoon/" .. entry.id .. "-delay.log", "a")
	if file then
		file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
		file:close()
	end
	print(entry.id .. "-delay: " .. message)
end

local function appFor(entry)
	return hs.application.get(entry.bundleID) or hs.application.get(entry.appName)
end

local function isEntryApp(entry, app)
	if not app then
		return false
	end

	return (entry.bundleID and app:bundleID() == entry.bundleID) or app:name() == entry.appName
end

local function graceActive(state)
	return state.graceUntil and os.time() <= state.graceUntil
end

local function hideApp(entry)
	local app = appFor(entry)
	if app then
		app:hide()
	end
end

local function hideAppSoon(entry)
	for _, delay in ipairs({ 0, 0.1, 0.3, 0.6, 1, 2 }) do
		hs.timer.doAfter(delay, function()
			hideApp(entry)
		end)
	end
end

local function launchHidden(entry)
	local app = appFor(entry)
	if app then
		hideApp(entry)
		return
	end

	local args = { "-gj" }
	if entry.bundleID then
		table.insert(args, "-b")
		table.insert(args, entry.bundleID)
	else
		table.insert(args, "-a")
		table.insert(args, entry.appName)
	end

	hs.task.new("/usr/bin/open", function()
		return true
	end, args):start()
	hideAppSoon(entry)
end

local function showApp(entry)
	local app = appFor(entry)
	entry.state.visible = true
	entry.state.graceUntil = nil

	if app then
		app:unhide()
		app:activate()
		return
	end

	hs.application.launchOrFocus(entry.appName)
end

local function cancelGate(entry, reason)
	if not entry.state.gateTimer then
		return
	end

	entry.state.gateTimer:stop()
	entry.state.gateTimer = nil
	entry.state.gateFrontBundleID = nil
	log(entry, "gate cancelled: " .. reason)
	hideApp(entry)
end

local function currentFrontBundleID()
	local app = hs.application.frontmostApplication()
	if not app then
		return nil
	end

	return app:bundleID()
end

local function finishGate(entry)
	entry.state.gateTimer = nil
	entry.state.gateFrontBundleID = nil
	log(entry, "gate finished, showing")
	showApp(entry)
end

local function startGate(entry)
	entry.state.gateFrontBundleID = currentFrontBundleID()
	launchHidden(entry)
	log(entry, "gate started")

	entry.state.gateTimer = hs.timer.doAfter(entry.gateSeconds, function()
		finishGate(entry)
	end)
end

local function handleTargetActivated(entry)
	if entry.state.visible then
		return
	end

	if graceActive(entry.state) then
		log(entry, "activated during grace, allowing")
		showApp(entry)
		return
	end

	log(entry, "activated while blocked, hiding")
	hideAppSoon(entry)
end

local function handleTargetDeactivated(entry)
	if not entry.state.visible then
		return
	end

	entry.state.visible = false
	entry.state.graceUntil = os.time() + entry.graceSeconds
	log(entry, "left visible app, hiding and starting grace")
	hideApp(entry)
end

local function cancelOtherPendingGates(bundleID)
	for _, entry in pairs(entries) do
		if entry.state.gateTimer and bundleID ~= entry.bundleID and bundleID ~= entry.state.gateFrontBundleID then
			cancelGate(entry, "front app changed")
		end
	end
end

local function handleAppEvent(appName, eventType, app)
	local bundleID = app and app:bundleID()
	if eventType == hs.application.watcher.activated and bundleID then
		cancelOtherPendingGates(bundleID)
	end

	for _, entry in pairs(entries) do
		if isEntryApp(entry, app) then
			if eventType == hs.application.watcher.activated then
				handleTargetActivated(entry)
			elseif eventType == hs.application.watcher.deactivated then
				handleTargetDeactivated(entry)
			elseif eventType == hs.application.watcher.launched and not entry.state.visible then
				hideAppSoon(entry)
			elseif eventType == hs.application.watcher.terminated then
				entry.state.visible = false
				entry.state.graceUntil = nil
				cancelGate(entry, "terminated")
			end
		end
	end
end

local function ensureWatcher()
	if watcher then
		return
	end

	watcher = hs.application.watcher.new(handleAppEvent)
	watcher:start()
	M.watcher = watcher
end

function M.register(id, config)
	entries[id] = {
		id = id,
		appName = config.appName,
		bundleID = config.bundleID,
		gateSeconds = config.gateSeconds or 8,
		graceSeconds = config.graceSeconds or 180,
		state = entries[id] and entries[id].state or {},
	}

	ensureWatcher()
	hideAppSoon(entries[id])
end

function M.open(id)
	local entry = entries[id]
	if not entry then
		error("unknown delayed app: " .. id)
	end

	log(entry, "shortcut pressed")

	if entry.state.visible or graceActive(entry.state) then
		log(entry, "showing immediately")
		showApp(entry)
		return
	end

	if entry.state.gateTimer then
		log(entry, "gate already pending, ignoring")
		return
	end

	startGate(entry)
end

return M
