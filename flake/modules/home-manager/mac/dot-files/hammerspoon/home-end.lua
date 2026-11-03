local homeEnd = {}
local eventTags = require("keyboard-event-tags")
local eventTypes = hs.eventtap.event.types
local properties = hs.eventtap.event.properties
local targets = { [hs.keycodes.map.home] = hs.keycodes.map.left, [hs.keycodes.map["end"]] = hs.keycodes.map.right }
local heldKeys = {}

-- Lua-pattern translations of Karabiner's frontmost_application_unless bundle regexes.
local excludedBundles = {
	"^org%.virtualbox%.app%.VirtualBoxVM$",
	"^com%.parallels%.desktop%.console$",
	"^org%.vmware%.fusion$",
	"^com%.utmapp%.UTM$",
	"^org%.gnu%.emacs$",
	"^org%.gnu%.Emacs$",
	"^com%.jetbrains",
	"^com%.microsoft%.VSCode$",
	"^com%.vscodium$",
	"^com%.todesktop.*",
	"^com%.sublimetext%.3$",
	"^net%.kovidgoyal%.kitty$",
	"^com%.citrix%.XenAppViewer$",
	"^com%.microsoft%.rdc%.macos$",
	"^co%.zeit%.hyper$",
	"^com%.googlecode%.iterm2$",
	"^com%.apple%.Terminal$",
	"^com%.github%.wez%.wezterm$",
	"^com%.mitchellh%.ghostty$",
	"^com%.overmux%.desktop$",
}

local function excludedApplication()
	local app = hs.application.frontmostApplication()
	if not app then
		return false
	end

	local bundleID = app:bundleID() or ""
	local path = app:path() or ""
	-- The original file-path regex is unanchored and ORed with the bundle exclusions.
	if path:find("Chrome Remote Desktop%.app") then
		return true
	end
	for _, pattern in ipairs(excludedBundles) do
		if bundleID:find(pattern) then
			return true
		end
	end
	return false
end

local function routeForPress(event, target)
	-- A repeat already held when the tap starts has no matching remapped key-down.
	if event:getProperty(properties.keyboardEventAutorepeat) ~= 0 or excludedApplication() then
		return {}
	end

	local flags = event:getFlags()
	flags.cmd = true
	return { keyCode = target, flags = flags }
end

local function handleEvent(event)
	if event:getProperty(properties.eventSourceUserData) == eventTags.homeEnd then
		return false
	end

	local keyCode = event:getKeyCode()
	local target = targets[keyCode]
	if not target then
		return false
	end

	local isDown = event:getType() == eventTypes.keyDown
	local route = heldKeys[keyCode]
	if isDown and not route then
		route = routeForPress(event, target)
		heldKeys[keyCode] = route
	elseif not isDown then
		heldKeys[keyCode] = nil
	end
	if not route or not route.keyCode then
		return false
	end

	-- Freeze the chord until release; copying retains autorepeat and keyboard metadata.
	local forwarded = event:copy():setKeyCode(route.keyCode):setFlags(route.flags)
	return true, { forwarded:setProperty(properties.eventSourceUserData, eventTags.homeEnd) }
end

function homeEnd.start()
	homeEnd.eventTap = hs.eventtap.new({ eventTypes.keyDown, eventTypes.keyUp }, handleEvent):start()
end

function homeEnd.stop()
	for _, route in pairs(heldKeys) do
		if route.keyCode then
			hs.eventtap.event
				.newKeyEvent({}, route.keyCode, false)
				:setFlags(route.flags)
				:setProperty(properties.eventSourceUserData, eventTags.homeEnd)
				:post()
		end
	end
	if homeEnd.eventTap then
		homeEnd.eventTap:stop()
	end
	heldKeys = {}
end

return homeEnd
