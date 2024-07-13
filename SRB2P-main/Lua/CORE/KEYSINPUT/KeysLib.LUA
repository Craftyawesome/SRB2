-- libraries for SRB2P's menu system

-- SRB2P: Keys library

-- constants for special keys:

-- as a general reminder, keys from 0 thru 32 are used by the system.
-- keys from 33 to 127 can be used for input
-- keys from 128 to 255 are also for the system


rawset(_G, "KEY_NULL", 0)
rawset(_G, "KEY_SPACE", 32)
rawset(_G, "KEY_BACKSPACE", 8)
rawset(_G, "KEY_TAB", 9)
rawset(_G, "KEY_ENTER", 13)
rawset(_G, "KEY_ESCAPE", 27)
rawset(_G, "KEY_MINUS", 45)
rawset(_G, "KEY_EQUALS", 61)
rawset(_G, "KEY_CONSOLE", 96)

rawset(_G, "KEY_NUMLOCK", 128+ 69)
rawset(_G, "KEY_SCROLLOCK", 128 +70)

rawset(_G, "KEY_F1", 128+59)
rawset(_G, "KEY_F2", 128+60)
rawset(_G, "KEY_F3", 128+61)
rawset(_G, "KEY_F4", 128+62)
rawset(_G, "KEY_F5", 128+63)
rawset(_G, "KEY_F6", 128+64)
rawset(_G, "KEY_F7", 128+65)
rawset(_G, "KEY_F8", 128+66)
rawset(_G, "KEY_F9", 128+67)
rawset(_G, "KEY_F10", 128+68)
rawset(_G, "KEY_F11", 128+69)
rawset(_G, "KEY_F12", 128+70)

rawset(_G, "KEY_KEYPAD7", 128+71)
rawset(_G, "KEY_KEYPAD8", 128+72)
rawset(_G, "KEY_KEYPAD9", 128+73)
rawset(_G, "KEY_MINUSPAD", 128+74)
rawset(_G, "KEY_KEYPAD4", 128+75)
rawset(_G, "KEY_KEYPAD5", 128+76)
rawset(_G, "KEY_KEYPAD6", 128+77)
rawset(_G, "KEY_PLUSPAD", 128+78)
rawset(_G, "KEY_KEYPAD1", 128+79)
rawset(_G, "KEY_KEYPAD2", 128+80)
rawset(_G, "KEY_KEYPAD3", 128+81)
rawset(_G, "KEY_KEYPAD0", 128+82)
rawset(_G, "KEY_KPADDEL", 128+83)

rawset(_G, "KEY_LSHIFT", 128+54)
rawset(_G, "KEY_RSHIFT", 128+55)
rawset(_G, "KEY_LCTRL", 128+29)
rawset(_G, "KEY_RCTRL", 128+30)
rawset(_G, "KEY_LALT", 128+56)
rawset(_G, "KEY_RALT", 128+57)

rawset(_G, "KEY_CAPSLOCK", 128+58)

rawset(_G, "KEY_ARROWU", 230)	--0x80 + 102
rawset(_G, "KEY_ARROWL", 233)	--0x80 + 105
rawset(_G, "KEY_ARROWR", 235)	--0x80 + 107
rawset(_G, "KEY_ARROWD", 238)	--0x80 + 110
-- why these are not right next to each other in keycodes is beyond me

local JOYBUTTONS = 32
local MOUSEBUTTONS = 8
local JOYHATS = 4

-- NUMKEYS is 256 in source
-- KEY_MOUSE1 is NUMKEYS
rawset(_G, "KEY_MOUSE1", 256)

-- MOUSEBUTTONS IS 8
-- KEY_JOY1 is KEY_MOUSE1 + MOUSEBUTTONS	(?????)
-- in short, KEY_JOY1 is 256+8 = 264
-- joy goes from joy1 to joy32, so we'll use KEY_JOY1 + (number)
rawset(_G, "KEY_JOY1", 264)
-- dbljoy sucks and you should never use it.

-- with that logic, hat1 is KEY_JOY1 + JOYBUTTONS
-- or 264+32 = 296
rawset(_G, "KEY_HAT1", 296)

rawset(_G, "KEY_DBLMOUSE1", KEY_HAT1 + JOYHATS*4)
rawset(_G, "KEY_DBLJOY1", KEY_DBLMOUSE1 + MOUSEBUTTONS)
rawset(_G, "KEY_DBLHAT1", KEY_DBLJOY1 + JOYBUTTONS)

rawset(_G, "KEY_2MOUSE1", KEY_DBLHAT1 + JOYHATS*4)
rawset(_G, "KEY_2JOY1", KEY_2MOUSE1 + MOUSEBUTTONS)
rawset(_G, "KEY_2DBLHAT1", KEY_2JOY1 + JOYBUTTONS)

rawset(_G, "KEY_DBL2MOUSE1", KEY_2DBLHAT1 + JOYHATS*4)
rawset(_G, "KEY_DBL2JOY1", KEY_DBL2MOUSE1 + MOUSEBUTTONS)
rawset(_G, "KEY_DBL2HAT1", KEY_DBL2JOY1 + JOYBUTTONS)

rawset(_G, "KEY_MOUSEWHEELUP", KEY_DBL2HAT1 + JOYHATS*4)
rawset(_G, "KEY_MOUSEWHEELDOWN", KEY_MOUSEWHEELUP +1)
rawset(_G, "KEY_2MOUSEWHEELUP", KEY_MOUSEWHEELUP +2)
rawset(_G, "KEY_2MOUSEWHEELDOWN", KEY_MOUSEWHEELUP +3)

rawset(_G, "KEY_NUMINPUTS", KEY_MOUSEWHEELUP +4)	-- 256

/*local keyheldfor = 0
local prevevent = 0*/
-- no longer necessary

-- IMPORTANT REMINDER:
-- This function picks up inputs in a CLIENTSIDED FASHION. These are in NO WAY SYNCHED.
-- This should, ABSOLUTELY NOT, be used in the context of NETGAMES.

local G_InputList = {}
local eat = false
local shiftdown = false
local capslock = false
local pauseflush

-- flush event queue
rawset(_G, "SYS_flushEventQueue", function()
	G_InputList = {}
end)

-- returns the event at the top of the list
rawset(_G, "SYS_getEvent", function()
	return G_InputList[#G_InputList]
end)

-- returns the whole event queue.
rawset(_G, "SYS_getEventQueue", function()
	local t = {}
	for i = 1, #G_InputList
		t[i] = G_InputList[i]
	end
	return t
end)

-- set whether or not to continue allowing events to slide through or if we're eating cookies today
rawset(_G, "SYS_eatEvents", function(val)
	eat = val
end)

local function shift_if_possible(key)
	local ashift = capslock != shiftdown
	--print("shift: "..tostring(ashift))
	return ashift and input.shiftKeyNum(key.num) or key.num
end

-- Builds event queue, this is ran before the frame is rendered.
addHook("KeyDown", function(key)
	--print(key.name.."->"..key.num)
	if (not key.repeated) or key.num >= KEY_JOY1
		local k = shift_if_possible(key)

		-- toggle capslock
		if k == KEY_CAPSLOCK
			capslock = (capslock == false) and true or false
		elseif (k == KEY_RSHIFT or k == KEY_LSHIFT)
			shiftdown = true
		end

		G_InputList[#G_InputList+1] = shift_if_possible(key)
		pauseflush = paused and 2 or 0
	end
	-- NEVER EAT THE CONSOLE KEY, NEVER.
	-- OR THE PAUSE KEY, FOR THAT MATTER!
	local pausek = SYS_getControls(gc_pause)

	if key.num ~= KEY_CONSOLE
	or key.num == pausek[1]
	or (pausek[2] and key.num == pausek[2])
		return eat
	end
end)

-- keyup to undo shift presses
addHook("KeyUp", function(key)

	if not key.repeated
		if key.num == KEY_RSHIFT or key.num == KEY_LSHIFT
			shiftdown = false
		end
	end
end)

-- flushes event queue after the frame.
addHook("PostThinkFrame", function()
	SYS_flushEventQueue()
end)

-- for pausing...
addHook("PrePreThinkFrameAndPause", function()
	if pauseflush
		pauseflush = $-1
		if not pauseflush
			SYS_flushEventQueue()
		end
	end
end)

-- SYS_ProcessEvent: returns the key that has just been pressed / been held for a while if 'allowhold' is true.
rawset(_G, "SYS_ProcessEvent", function()
	local event = SYS_getEvent()
	-- mitigate the need for complex checks

	-- NOTE: This only returns the event at the end of the event list and is not suited for text input.
	-- perfectly acceptable for menus or just quick input detection in general however
	return event
end)

-- returns the character to add to a given text field.
-- or -1 if backspace is pressed
rawset(_G, "SYS_TextInput", function(event)
	if event == KEY_BACKSPACE
		return -1
	end

	if event >= KEY_SPACE and event <= 128
		return event
	end
end)

-- returns a control input. (different from certain special keys)
rawset(_G, "SYS_ValidControl", function(event)
	if event == KEY_ESCAPE
	or event == KEY_ENTER
		return 0
	end

	return event
end)

-- remaps joypad / mouse events to keyboard events for the menu to understand
rawset(_G, "SYS_menuInput", function(event)

	if event == KEY_HAT1
		return KEY_ARROWU
	elseif event == KEY_HAT1+1	--HAT2
		return KEY_ARROWD
	elseif event == KEY_HAT1+2 -- HAT3
		return KEY_ARROWL
	elseif event == KEY_HAT1+3 -- HAT4
		return KEY_ARROWR
	elseif event == KEY_JOY1
	or event == KEY_MOUSE1	-- mouse buttons are swapped, somehow
		return KEY_ENTER
	elseif event == KEY_JOY1+1	-- JOY2
	or event == KEY_MOUSE1+1	-- mouse buttons are swapped, somehow
		return KEY_ESCAPE
	end

	return event
end)

-- returns TRUE if 'mo' is in a state where input normalization can take place.
rawset(_G, "SYS_shouldNormalize", function(mo)

	if SYS_systemmenu and SYS_systemmenu.running return true end
	if chat_buf return end
	if not server return end
	if not mo or not mo.valid or not mo.player or not mo.player.valid return end

	local p = mo.player
	if p.P_party and server.P_BattleStatus and server.P_BattleStatus[p.P_party].running return true end
	if p.P_party and server.P_DialogueStatus and server.P_DialogueStatus[p.P_party].running return true end
	if mo.shop and mo.shop.shopping return true end
	if mo.equiplab and mo.equiplab.using return true end
	if mo.fusion return true end
	if mo.m_menu return true end
	if NET_running() return true end
end)

-- game controls:
local gamecontrols = {
	"gc_null",
	"gc_forward",
	"gc_backward",
	"gc_strafeleft",
	"gc_straferight",
	"gc_turnleft",
	"gc_turnright",
	"gc_weaponnext",
	"gc_weaponprev",
	"gc_wepslot1",
	"gc_wepslot2",
	"gc_wepslot3",
	"gc_wepslot4",
	"gc_wepslot5",
	"gc_wepslot6",
	"gc_wepslot7",
	"gc_wepslot8",
	"gc_wepslot9",
	"gc_wepslot10",
	"gc_fire",
	"gc_firenormal",
	"gc_tossflag",
	"gc_use",
	"gc_camtoggle",
	"gc_camreset",
	"gc_lookup",
	"gc_lookdown",
	"gc_centerview",
	"gc_mouseaiming",
	"gc_talkkey",
	"gc_teamkey",
	"gc_scores",
	"gc_jump",
	"gc_console",
	"gc_pause",
	"gc_systemmenu",
	"gc_screenshot",
	"gc_recordgif",
	"gc_viewpoint",
	"gc_custom1",
	"gc_custom2",
	"gc_custom3",
	"gc_numcontrols"
}

rawset(_G, "SYS_ControlNames", {})	-- names without gc_

for i = 1, #gamecontrols do
	rawset(_G, gamecontrols[i], i-1)	-- C is 0 indexed.
	SYS_ControlNames[i-1] = gamecontrols[i]:sub(4, 99)
end

-- returns the event codes of the keys for each action
rawset(_G, "SYS_getControls", function(gc)
	if not gc return {0, 0} end
	return {select(1, SRB2P_getControl(gc)), select(2, SRB2P_getControl(gc))}
end)

rawset(_G, "cv_stdinput", CV_RegisterVar({
  name = "stdinput",
  defaultvalue = 1,
  flags = CV_SAVE,
  PossibleValue = CV_OnOff,
})
)