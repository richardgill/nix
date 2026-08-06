local emojiMode = {}

local emojis = {
	[hs.keycodes.map.w] = "👋",
	[hs.keycodes.map.c] = "✅",
	[hs.keycodes.map.t] = "🧵",
	[hs.keycodes.map.f] = "🔥",
	[hs.keycodes.map.space] = "👍",
}
local bridgeKeyCode = hs.keycodes.map.f18
local fnCompanionKeyCode = 179
local keyDown = hs.eventtap.event.types.keyDown
local keyUp = hs.eventtap.event.types.keyUp
local armSeconds = 1
local doubleTapSeconds = 0.35
local cooldownSeconds = 0.3

local armedUntil = 0
local cooldownUntil = 0
local lastFnTapAt
local suppressedKeys = {}

local function disarm()
	armedUntil = 0
	lastFnTapAt = nil
end

local function arm(now)
	lastFnTapAt = now
	armedUntil = now + armSeconds
end

local function startCooldown(now)
	disarm()
	cooldownUntil = now + cooldownSeconds
end

local function fireDictationShortcut()
	hs.eventtap.keyStroke({ "ctrl", "alt", "cmd" }, "d", 0)
end

local function startDictation(now)
	startCooldown(now)
	hs.timer.doAfter(0.05, fireDictationShortcut)
end

local function handleFnTap(now)
	if now < cooldownUntil then
		return
	end

	if armedUntil >= now and lastFnTapAt and now - lastFnTapAt <= doubleTapSeconds then
		startDictation(now)
	else
		arm(now)
	end
end

local function emitEmoji(keyCode, now)
	suppressedKeys[keyCode] = true
	startCooldown(now)
	hs.eventtap.keyStrokes(emojis[keyCode])
end

local function handleEvent(event)
	local eventType = event:getType()
	local keyCode = event:getKeyCode()

	if keyCode == fnCompanionKeyCode then
		return false
	end

	if keyCode == bridgeKeyCode then
		if eventType == keyDown then
			handleFnTap(hs.timer.secondsSinceEpoch())
		end
		return true
	end

	if suppressedKeys[keyCode] then
		if eventType == keyUp then
			suppressedKeys[keyCode] = nil
		end
		return true
	end

	local now = hs.timer.secondsSinceEpoch()
	if eventType ~= keyDown or armedUntil < now then
		return false
	end

	if emojis[keyCode] then
		emitEmoji(keyCode, now)
	else
		disarm()
	end
	return emojis[keyCode] ~= nil
end

function emojiMode.start()
	emojiMode.eventTap = hs.eventtap.new({ keyDown, keyUp }, handleEvent):start()
end

return emojiMode
