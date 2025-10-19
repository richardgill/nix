hs.window.animationDuration = 0 -- Disable animations globally

-- Define hyper key (all modifiers)
local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Requires Hammerspoon to have Privacy -> Screen Recording permissions
hs.hotkey.bind({ "cmd", "shift" }, "4", function()
	hs.task.new("/Applications/flameshot.app/Contents/MacOS/flameshot", function() end, { "gui" }):start()
end)

-- Application bindings

hs.hotkey.bind(hyper, "a", function()
	hs.application.launchOrFocus("Activity Monitor")
end)

hs.hotkey.bind(hyper, "b", function()
	hs.application.launchOrFocus("Finder")
end)

hs.hotkey.bind(hyper, "c", function()
	hs.urlevent.openURL("https://chatgpt.com/new")
end)

hs.hotkey.bind(hyper, "d", function()
	hs.application.launchOrFocus("Discord")
end)

hs.hotkey.bind(hyper, "f", function()
	-- Opening firefox whilst holding hyper is holding shift, which launches firefox in safe mode.
	local app = hs.application.get("org.mozilla.firefox")
	if app then
		app:activate()
	else
		hs.task
			.new("/usr/bin/open", nil, function(exitCode, stdOut, stdErr)
				return true
			end, { "-a", "Firefox" })
			:setEnvironment({ MOZ_DISABLE_SAFE_MODE_KEY = "1" })
			:start()
	end
end)

hs.hotkey.bind(hyper, "g", function()
	hs.application.launchOrFocus("Ghostty")
end)

hs.hotkey.bind(hyper, "h", function()
	hs.application.launchOrFocus("1Password")
end)

hs.hotkey.bind(hyper, "t", function()
	hs.application.launchOrFocus("Todoist")
end)

hs.hotkey.bind(hyper, "s", function()
	hs.application.launchOrFocus("Slack.app")
end)

hs.hotkey.bind(hyper, "w", function()
	hs.application.launchOrFocus("Beeper Desktop")
end)

hs.hotkey.bind(hyper, "z", function()
	hs.application.launchOrFocus("zoom.us.app")
end)

local menu = hs.menubar.new()

function startFocus()
	hs.task.new("/Users/rich/Scripts/coldTurkeyFocusStart", nil):start()
	menu:setTitle("🔒")
end

function stopFocus()
	hs.task.new("/Users/rich/Scripts/coldTurkeyFocusStop", nil):start()
	menu:setTitle("🔓")
end

function stopLinkedIn()
	hs.task.new("/Users/rich/Scripts/coldTurkeyLinkedInStop", nil):start()
end

menu:setMenu({
	{ title = "Start Focus", fn = startFocus },
	{ title = "Stop Focus", fn = stopFocus },
	{
		title = "Stop LinkedIn",
		fn = stopLinkedIn,
	},
})

menu:setTitle("🔓")

local function shouldMaximizeWindow(win)
	return win and win:isStandard() and win:isMaximizable() and win:subrole() ~= "AXSystemDialog"
end

local function maximizeWindow(win)
	if shouldMaximizeWindow(win) then
		win:maximize(0) -- 0ms duration
	end
end

local function maximizeAllWindows()
	local allWindows = hs.window.allWindows()
	for _, win in ipairs(allWindows) do
		maximizeWindow(win)
	end
end

-- Maximize new windows as they are created
hs.window.filter.default:subscribe(hs.window.filter.windowCreated, function(win)
	hs.timer.doAfter(0.1, function()
		maximizeWindow(win)
	end)
end)

-- Watch for screen changes (e.g., connecting an external monitor)
-- This maybe cannot be local because the watcher gets garbage collected
screenWatcher = hs.screen.watcher.new(function()
	hs.timer.doAfter(2, maximizeAllWindows) -- Add slight delay to handle screen updates
end)
screenWatcher:start()

-- This cannot be local because the watcher gets garbage collected
watcher = hs.caffeinate.watcher.new(function(event)
	print(
		event,
		hs.caffeinate.watcher.screensaverDidStop,
		hs.caffeinate.watcher.systemDidWake,
		hs.caffeinate.watcher.screensDidUnlock
	)
	if
		event == hs.caffeinate.watcher.screensaverDidStop
		or event == hs.caffeinate.watcher.systemDidWake
		or event == hs.caffeinate.watcher.screensDidUnlock
	then
		hs.execute("/Users/rich/Scripts/coldTurkeyOn", true)
	end
end)

watcher:start()
