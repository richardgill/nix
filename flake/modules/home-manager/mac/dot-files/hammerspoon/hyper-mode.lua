local hyperMode = {}

-- F19 routes actions directly, inspired by https://evantravers.com/articles/2020/06/08/hammerspoon-a-better-better-hyper-key/
-- Use an eventtap for this held-key modal so key-up tracking outlives F19 release.
-- Define hyper key (all modifiers)
local hyper = { "cmd", "alt", "ctrl", "shift" }
local bridgeKeyCode = hs.keycodes.map.f19
local eventTypes = hs.eventtap.event.types
local properties = hs.eventtap.event.properties
local eventTags = require("keyboard-event-tags")
local eventTag = eventTags.hyper
local actions = {}
local heldKeys = {}
local active = false

local function tagged(event)
	return event:setProperty(properties.eventSourceUserData, eventTag)
end

local function releaseForwardedKeys()
	local releases = {}
	for keyCode, route in pairs(heldKeys) do
		if route == "forward" then
			table.insert(releases, tagged(hs.eventtap.event.newKeyEvent(hyper, keyCode, false)))
			heldKeys[keyCode] = "suppressed"
		end
	end
	return releases
end

local function handleBridge(event)
	if event:getType() == eventTypes.keyDown then
		active = true
		return true
	end

	active = false
	-- Finish synthetic chords now; swallow their remaining physical repeats and releases.
	return true, releaseForwardedKeys()
end

local function handleEvent(event)
	local tag = event:getProperty(properties.eventSourceUserData)
	if tag == eventTag or tag == eventTags.homeEnd then
		return false
	end

	local keyCode = event:getKeyCode()
	if keyCode == bridgeKeyCode then
		return handleBridge(event)
	end

	local isDown = event:getType() == eventTypes.keyDown
	local route = heldKeys[keyCode]
	if isDown and not route then
		route = "pass"
		if active and event:getProperty(properties.keyboardEventAutorepeat) == 0 then
			route = actions[keyCode] and "action" or "forward"
		end
		heldKeys[keyCode] = route
		if route == "action" then
			actions[keyCode]()
		end
	elseif not isDown then
		heldKeys[keyCode] = nil
	end

	if route == "forward" then
		-- Copy preserves autorepeat and keyboard metadata; never synthesize held modifiers.
		return true, { tagged(event:copy():setFlags({ cmd = true, alt = true, ctrl = true, shift = true })) }
	end
	return route ~= nil and route ~= "pass"
end

function hyperMode.bind(key, action)
	actions[hs.keycodes.map[key]] = action
	-- Physical four-modifier shortcuts and the modal share callbacks, not reposted hotkeys.
	hs.hotkey.bind(hyper, key, action)
end

function hyperMode.start()
	hyperMode.eventTap = hs.eventtap.new({ eventTypes.keyDown, eventTypes.keyUp }, handleEvent):start()
end

function hyperMode.stop()
	active = false
	for _, event in ipairs(releaseForwardedKeys()) do
		event:post()
	end
	if hyperMode.eventTap then
		hyperMode.eventTap:stop()
	end
	heldKeys = {}
end

return hyperMode
