-- SRB2P: Main menu library

rawset(_G, "SYS_systemmenu", {

	running = false,
	runningfor = 0,
	menu = 0,		-- SM_ constants
	menustate = 0,	-- MS_ constants

	textfields = {},-- for CT_TEXTFUNCTION
	choice = 0,		-- the menu's choice table.
	animtimer = 0,	-- animation timer for the menu. Goes down by 1 until it hits 0
	scrollx = 0,	-- menu scrolling, x dir. positive is ->, negative is <-
	scrolly = 0,	-- menu scrolling, y dir. positive is V, negative is ^

	-- prompt
	prompttext = nil,
	prompttype = 0,	--PT_NONE
	promptgoto = 0,
	promptanim = 0,

})

-- choice types CT_
local choicetype_const = {
	"CT_MENUSTATE",		-- special:		MS_ constant of the menustate to go to
	"CT_CVAR",			-- special:		CVar to use. This will display the normal value of the cvar in generic display
	"CT_CVARNUM",		-- special:		{CVar to use, min, max}. Similar to CT_CVAR, but can take a range of options.
	"CT_CVARSLIDER",	-- special:		{CVar to use, min, max}. This will display a slider next to the option in generic display
	"CT_CVARTEXT",		-- special:		CVar to write to. This will display a text field under the option in generic display

	"CT_GAMECONTROL",	-- special:		gc_ constant of the control to overwrite

	"CT_FUNCTION",		-- special: 	function to call (no arguments)
	"CT_TEXTFUNCTION",	-- special:		function to call (the text typed in the field is given as argument)

	"CT_PROMPT",		-- special:		{}table
						--				{text, PT_ type, MS_ to go to when the prompt is confirmed OR function to run)
						--				if text is nil, it's considered to be the quit game texts.
}

for i = 1, #choicetype_const
	rawset(_G, choicetype_const[i], i)
end

-- choice status CS_
local choicestatus_const = {
	"CS_GREYOUT",		-- choice is greyed out and CANNOT be selected.
	"CS_FAKEGREYOUT",	-- fake grey out, greys out but allows using a funciton anyway (used in beta for NEW GAME / LOAD GAME prompt)
	"CS_???",			-- choice if greyed out, and all characters are replaced with ?s
	"CS_HIDDEN",		-- choice isn't displayed and cannot be selected
}

for i = 1, #choicestatus_const
	rawset(_G, choicestatus_const[i], i)
end

-- prompt types PT_
local prompttypes_const = {
	"PT_NOTIFICATION",	-- will proceed regardless of input
	"PT_YESNO",			-- will only proceed if enter is pressed. Or just close if esc is pressed

	"PT_GAMECONTROL",	-- bruhtonium. Hardcoded behavior for menu controls.
}

for i = 1, #prompttypes_const
	rawset(_G, prompttypes_const[i], i)
end


rawset(_G, "SYS_menus", {})
-- menu system
/*

[SM_MENU] = {

	openstate = MS_ constant		state the menu opens in
	openchoice = int				choice the menu defaults to
	opentimer = int					animation timer when first opening

	openfunc = function()			function to run as the menu opens

	[MS_MENUSTATE] = {

		opentimer = 	int
		openfunc =		function()

		runfunc =		function(evt, timer, choices),			runs every frame this menu is on. Timer is the animtimer.
		drawer =		function(v, timer, choices),			drawn every frame this menu is on. Timer is the animtimer.

		choices =		{
							{"choice1name", xpos, ypos, choicetype, special, status}
							{"choice2name", xpos, ypos, choicetype, special, status}	...

							choicetye -> CT_ constants
							special ->	 depends on choicetype.
							status ->	 CS_ constant

							Tells the game what to do with individual choices.
							If SYS_GenericMenuDisplay(v) is used in the drawer, these choices will also have a standardized drawing.

							Scrolling will also be done automatically if the choice's xpos or ypos is off the screen boundaries.
						},

		next = MS_ constant				next menu when "runfunc" returns true by default. runfunc can overwrite this.
		prev = MS_ constant				prev menu when escape is pressed by default. if nil and not overwritten by runfunc, this will close the menu entierely.


				}

	},
*/

-- functions to open / close menus etc.
rawset(_G, "SYS_OpenMenu", function(menu)
	local m = SYS_menus[menu]
	if not m return end	-- bruh

	--dprint("Opening menu "..menu)

	SYS_eatEvents(true)
	SYS_flushEventQueue()	-- flush event buffer for use in menus

	SYS_systemmenu =	{
		running = true,
		runningfor = 1,
		menu = menu,
		menustate = m.openstate or 1,
		textfields = {},
		choice = m.openchoice or 1,
		animtimer = m.opentimer or 0,
		scrollx = 0,
		scrolly = 0,

		-- prompt
		prompttext = nil,
		prompttype = 0,	--PT_NONE
		promptgoto = 0,
		promptanim = 0,

	}

	if m.runfunc
		m.runfunc()
	end
end)

-- function to create prompts:
rawset(_G, "SYS_CreatePrompt", function(text, ptype, state)
	local m = SYS_systemmenu
	if not m return end	-- bruh

	m.prompttype = ptype
	m.promptgoto = state
	m.promptanim = 10
	-- standardize prompt text:

	if text
		local tmptext = {}
		local curindex = 1

		for i = 1, #text do

			if not tmptext[curindex]
				tmptext[curindex] = ""
			end

			local c = text:sub(i, i)
			if c ~= "\n"
				tmptext[curindex] = $..c
			else
				curindex = $+1
			end
		end

		m.prompttext = tmptext
	else
		-- pick from random quotes @TODO
		m.prompttext = {""}
	end
end)

rawset(_G, "SYS_ClosePrompt", function()
	local m = SYS_systemmenu
	if not m return end	-- bruh

	m.prompttext = nil
	m.prompttype = 0
	m.promptgoto = 0
	m.promptanim = 0

end)


-- function to switch menu state
rawset(_G, "SYS_SwitchMenuState", function(menustate)
	local m = SYS_systemmenu

	if not m return end	-- bruh
	if not m.running return end	-- not running

	if (menustate == -1)
		m.switchingstate = SYS_menus[m.menu][m.menustate].opentimer or TICRATE/2
		m.newmenu = -1
		return true
	end

	local stateinfo = SYS_menus[m.menu][menustate]
	if not (stateinfo) return end	--doesn't exist
	-- allow -1 as this closes the menu

	m.switchingstate = SYS_menus[m.menu][m.menustate].opentimer or TICRATE/2
	m.newmenu = menustate

	/*m.menustate = menustate
	if stateinfo.openfunc
		stateinfo.openfunc()
	end
	m.animtimer = stateinfo.opentimer or 0
	m.choice = stateinfo.openchoice or 1
	m.scrollx = 0
	m.scrolly = 0
	m.textfields = {}
	if stateinfo.choices
		for i = 1, #stateinfo.choices
			m.textfields[i] = ""	-- ready textfields
		end
	end*/

	return true
end)

-- function to switch menu state
rawset(_G, "SYS_SwitchSubmenu", function(menustate)
	local m = SYS_systemmenu
	if not m return end	-- bruh
	if not m.menu return end	-- not running

	if menustate == -1
		SYS_closeMenu()
		return true
	end

	local stateinfo = SYS_menus[m.menu][menustate]
	if not stateinfo return end	--doesn't exist

	m.menustate = menustate
	m.switchingstate = 0
	m.newmenu = 0
	if stateinfo.openfunc
		stateinfo.openfunc()
	end
	m.animtimer = stateinfo.opentimer or 0
	m.choice = stateinfo.openchoice or 1
	m.scrollx = 0
	m.scrolly = 0
	m.textfields = {}
	if stateinfo.choices
		for i = 1, #stateinfo.choices
			m.textfields[i] = ""	-- ready textfields

			if stateinfo.choices[i][4] == CT_CVARTEXT	-- ready as cvar default value
			and stateinfo.choices[i][5]
				m.textfields[i] = stateinfo.choices[i][5].string
			end
		end
	end

	return true
end)

local function SYS_setGameControl(m, data)
	SYS_ClosePrompt()

	local qte = "\""
	-- trust me, this works, somehow.

	if not data[1]
		data[1] = ""
	end
	if not data[2]
		data[2] = ""	-- make things easier on ourselves~
	end

	local str = "setcontrol "..qte..data[0]..qte.." "..qte..data[1]..qte.." "..qte..data[2]..qte
	-- set the control:
	COM_ImmedExecute(str)
	-- setcontrol "controlname" "key1" "key2"
	-- yes, this is dogshit.

	data = nil	-- pointer to m.promptextra which will be cleared as well
	m.promptspecial = nil
end

-- handles everything related to menus
rawset(_G, "SYS_handleMenu", function()
	local m = SYS_systemmenu

	if not m or not m.running return end
	local cmenu = SYS_menus[m.menu][m.menustate]

	m.runningfor = $+1

	local eventlist = SYS_getEventQueue()

	-- make sure something is there:
	if not eventlist[1]
		eventlist[1] = 0
	end

	if m.switchingstate
		m.animtimer = $+1
		m.switchingstate = $-1

		if not m.switchingstate
			SYS_SwitchSubmenu(m.newmenu)
		end
		return	-- nomnom gimme your events
	end

	local stoplist = false	-- returns at the end of the loop to fix issue with double inputs for some keyboards?

	for j = 1, #eventlist

		if stoplist
			return	-- previous input asked to be stopped
		end

		local e = SYS_menuInput(eventlist[j])		-- process event to a menu input for controller support
		local fullevent = eventlist[j]	-- for controls

		if m.animtimer
			m.animtimer = $-1
		end

		local basexpos = 0 + m.scrollx
		local baseypos = 0 + m.scrolly

		local maxscrx = 320 + m.scrollx
		local maxscry = 320 + m.scrolly	-- for menu scrolling ...

		-- prompt exists...
		if m.prompttype

			-- oh FUCK.
			if m.prompttype == PT_GAMECONTROL
				local cevt = SYS_ValidControl(fullevent)
				if cevt
					cevt = SYS_KeyNames[cevt] or $

					m.promptdata[m.promptspecial] = cevt
					m.promptspecial = $+1
					m.prompttext = {"Press a key for the", "second alias.", "Press ESC to abort."}	-- a bit hacky but hey it works
					if m.promptspecial > 2
						SYS_setGameControl(m, m.promptdata)
						return
					end
				elseif fullevent == KEY_ESCAPE	-- cancel!
					SYS_setGameControl(m, m.promptdata)
					return
				end
			end

			if m.prompttype == PT_YESNO and e == KEY_ENTER
			or m.prompttype == PT_NOTIFICATION and e

				if type(m.promptgoto) == "number"
					SYS_SwitchMenuState(m.promptgoto)
					SYS_ClosePrompt()
					return
				elseif type(m.promptgoto) == "function"	-- for versatility, just allow it to have both types
					m.promptgoto()
					SYS_ClosePrompt()
					return
				end
				SYS_ClosePrompt()	-- close prompt anyway
			elseif m.prompttype == PT_YESNO and e == KEY_ESCAPE	-- Just close it and do nothing
				SYS_ClosePrompt()
			end
			m.promptanim = max(0, $-1)
			continue	-- omnomnom your inputs are delicious <3
		end

		if cmenu.runfunc
		and cmenu.runfunc(m, cmenu.choices, m.choice, e)
			continue -- returned true? Sure, overwrite previous behaviour!
		end

		-- return to previous menu
		if e == KEY_ESCAPE
		and cmenu.prev
		and m.runningfor > 2
		and SYS_SwitchMenuState(cmenu.prev)
			S_StartSound(nil, sfx_cancel)
			return
		end

		-- handle choices:
		local c = cmenu.choices
		if c and #c
			local maxchoice = #c

			-- up/down to select
			if maxchoice > 1
				if e == KEY_ARROWU
					m.choice = $-1
					if m.choice < 1
						m.choice = maxchoice
					end
					S_StartSound(nil, sfx_hover)
					stoplist = true
				elseif e == KEY_ARROWD
					m.choice = $+1
					if m.choice > maxchoice
						m.choice = 1
					end
					S_StartSound(nil, sfx_hover)
					stoplist = true
				end
			end

			local c = cmenu.choices[m.choice]

			-- scrolling:

			if c[2] - m.scrollx > 320	--xpos
				m.scrollx = (c[2]+64) - 320
			elseif c[2] - m.scrollx < 0
				m.scrollx = (c[2]-64)
			end

			if c[3] - m.scrolly > 175	--ypos
				m.scrolly = (c[3]+12) - 180
			elseif c[3] - m.scrolly < 8
				m.scrolly = (c[3]-8)
			end

			-- cvars:
			-- funny story: possiblevalue_t isn't in lua, so we only handle cv_onoff here. other specials are required to give a table of possiblevalues
			if c[4] == CT_CVAR
				local cv = c[5]

				if e == KEY_ARROWL or e == KEY_ARROWR
					-- switch the cvar's status I suppose!
					COM_ImmedExecute(cv.name.." "..(cv.value and "0" or "1"))
					S_StartSound(nil, sfx_hover)
				end
			elseif c[4] == CT_CVARSLIDER or c[4] == CT_CVARNUM
				-- functionally speaking, the sliders and numbers are the same thing, the only different thing is the display
				local cv = c[5][1]
				local cv_min = c[5][2]
				local cv_max = c[5][3]	-- for sliders, retrieve the min and max values specified

				if e == KEY_ARROWL
					local newval = max(cv_min, cv.value - 1)
					if c[4] == CT_CVARNUM	-- allow loop around
						if cv.value-1 < cv_min
							newval = cv_max
						end
					end

					stoplist = true
					S_StartSound(nil, sfx_hover)

					COM_ImmedExecute(cv.name.." "..newval)
				elseif e == KEY_ARROWR
					local newval = min(cv_max, cv.value + 1)
					if c[4] == CT_CVARNUM	-- allow loop around
						if cv.value+1 > cv_max
							newval = cv_min
						end
					end
					S_StartSound(nil, sfx_hover)
					stoplist = true
					COM_ImmedExecute(cv.name.." "..newval)
				end
			end

			-- text fields:
			if c[4] == CT_TEXTFUNCTION or c[4] == CT_CVARTEXT
				local kb = SYS_TextInput(e)
				local paste

				if ctrldown and (kb == string.byte("v") or kb == string.byte("V"))
					paste = SRB2P_clipboardPaste()
				end

				-- write in m.textfields[m.choice]

				if paste
				and #paste + #m.textfields[m.choice] < 32
					m.textfields[m.choice] = $..paste
					return
				end

				if kb ~= -1 and kb
				and m.textfields[m.choice]:len() < 32
					m.textfields[m.choice] = $..(string.char(kb))
				elseif kb == -1
				and m.textfields[m.choice]:len()
					-- delete 1 character:
					m.textfields[m.choice] = string.sub($, 1, m.textfields[m.choice]:len() -1)
				end

				if c[4] == CT_CVARTEXT and e == KEY_ENTER	-- input the text in the console
					local cv = c[5]
					local qte = "\""

					if cv
						COM_ImmedExecute(cv.name.." "..qte..m.textfields[m.choice]..qte)	-- set the cvar
						S_StartSound(nil, sfx_confir)
					end
				end
			end

			-- selecting:
			if e == KEY_ENTER
				stoplist = true
				-- we selected something, let's see if we can do something with it.
				if not c[6]	-- if the status is different from nil, then something's definitely up and we can't select it.
				or c[6] == CS_FAKEGREYOUT

					if c[4] == CT_MENUSTATE	-- to a new menu state
						if SYS_SwitchMenuState(c[5])
							S_StartSound(nil, sfx_confir)

						end
					elseif c[4] == CT_FUNCTION	-- run the function in special
						if c[5]
							c[5]()
							S_StartSound(nil, sfx_confir)
						end
					elseif c[4] == CT_TEXTFUNCTION	-- exec the function and pass textfield as an argument
						if c[5]
							c[5](m.textfields[m.choice])
							S_StartSound(nil, sfx_confir)
						end
					elseif c[4] == CT_PROMPT		-- create a prompt from the table in c[5]
						if c[5] and type(c[5]) == "table"
							SYS_CreatePrompt(c[5][1], c[5][2], c[5][3])
							S_StartSound(nil, sfx_select)
						end
					elseif c[4] == CT_GAMECONTROL
						-- actually pain
						m.promptspecial = 1		-- what key index we're setting
						m.promptdata = {}		-- this will be pased to SYS_setGameControl
						m.promptdata[0] = SYS_ControlNames[c[5]]	-- save the name of the control to write to in the first field
						SYS_CreatePrompt("Press a key for the\nfirst alias.\nPress ESC to abort.", PT_GAMECONTROL, SYS_setGameControl)
					end

					if c[6] == CS_FAKEGREYOUT
						S_StartSound(nil, sfx_not)
					end
				else
					S_StartSound(nil, sfx_not)
				end
				return
			end
		end
	end
end)

local function keyname(k)
	if SYS_KeyNames[k]
		return SYS_KeyNames[k]
	else
		return tostring(k)
	end
end

rawset(_G, "SYS_drawGenericMenu", function(v, t, choices, curchoice)

	local m = SYS_systemmenu
	local flags = SYS_menus[m.menu][m.menustate].displayflags or 0

	local basexpos = 0 - m.scrollx
	local baseypos = 0 - m.scrolly

	local maxscrx = 320 + m.scrollx
	local maxscry = 200 + m.scrolly	-- for menu scrolling ...

	for i = 1, #choices do

		local choice = choices[i]
		local x = basexpos + min(choice[2], choice[2] - ((t-(i-1))*40))
		local y = baseypos + choice[3]

		if y > 175 or y < -10 continue end	-- don't display anything off the lower screen in this mode

		local addtext = ""

		if i == curchoice
			local scale = FRACUNIT/2 + (sin(leveltime*ANG1*20)) / 32
			v.drawScaled(x*FRACUNIT, (y+4)*FRACUNIT, scale, v.cachePatch("SS_ENTER"), flags)

			if leveltime%10 < 5	-- for text fields
				addtext = "_"
			end

		end

		local text = choices[i][1]:upper()
		local color = 0

		if choice[6] == CS_GREYOUT
		or choice[6] == CS_FAKEGREYOUT
			color = 16
		end

		V_drawString(v, x, y, text, "FPIMP", flags, "center", color, 31)
		if choice[6] continue end

		-- cvar options:
		if choice[4] == CT_CVAR or choice[4] == CT_CVARNUM
			local cv = choice[5]

			if choice[4] == CT_CVARNUM	-- in that case, cvar is choice[5][1]
				cv = choice[5][1]
			end

			local cvtext = cv.string

			if i == curchoice
				cvtext = "\x82".."<"..cv.string..">"
				if leveltime%20 < 10
					cvtext = "\x82".."< "..cv.string.." >"
				end
			end
			V_drawString(v, x+155, y+2, cvtext, "NFNT", flags, "center", 0, 31)

		elseif choice[4] == CT_CVARSLIDER	-- sliders
			local cv = choice[5][1]
			local cv_min = choice[5][2]
			local cv_max = choice[5][3]	-- for sliders, retrieve the min and max values specified

			-- x + 155 is the center of our slider
			v.drawFill(x + 60, y+1, 120, 8, 31|flags)

			-- relative to cv.defaultvlaue, cv_min and cv_max, place a cursor
			local dv = tonumber(cv.defaultvalue)
			local slider_r = 14	-- arbitrary 15-1
			local xrange = ((dv - cv_min) * 100 / (cv_max - cv_min))
			local xslide = (slider_r*8*xrange)/100

			v.drawFill(x + 62 + xslide, y+1, 6, 8, 138|flags)

			-- relative to cv.value, cv_min and cv_max, place our cursor!
			slider_r = 14	-- arbitrary 15-1
			xrange = ((cv.value - cv_min) * 100 / (cv_max - cv_min))
			xslide = (slider_r*8*xrange)/100

			v.drawFill(x + 62 + xslide, y+1, 6, 8, 135|flags)

		elseif choice[4] == CT_GAMECONTROL	-- game control

			local ctrl = SYS_getControls(choice[5])
			local ctext = ""

			if curchoice == i
				ctext = "\x82"
			end

			if ctrl[1] and ctrl[2]
				ctext = $1..keyname(ctrl[1]):upper().."\x80".." or "..($1)..keyname(ctrl[2]):upper()
			elseif ctrl[1]
				ctext = $..keyname(ctrl[1]):upper()
			elseif ctrl[2]
				ctext = $..keyname(ctrl[2]):upper()
			else
				ctext = "NOT SET"
			end
			V_drawString(v, x+125, y+2, ctext, "NFNT", flags, "center", 0, 31)

		elseif choice[4] == CT_CVARTEXT or choice[4] == CT_TEXTFUNCTION	-- text fields
			-- draw text background:
			v.drawFill(x-66, y+12, 128, 12, 135|flags)
			local text = ""
			if m.textfields
				text = m.textfields[i]
			end

			V_drawString(v, x-60, y+14, (text..addtext), "NFNT", flags, nil, 31, nil)
		end
	end
	local choice = choices[curchoice]
	v.drawFill(0, 180, 500 - (t*64), 10, 31|V_SNAPTOBOTTOM|V_SNAPTOLEFT)
	if choice[7]
		V_drawString(v, 10 - (t*64), 181, choice[7], "NFNT", V_SNAPTOBOTTOM|V_SNAPTOLEFT, nil, 0, 31)
	end
end)

-- handles everything related to displaying the menu
rawset(_G, "SYS_drawMenu", function(v)
	local m = SYS_systemmenu

	if not m or not m.running return end
	local cmenu = SYS_menus[m.menu]

	if cmenu.drawfunc
		cmenu.drawfunc(v)
	end	-- general drawing func for that menu

	if cmenu[m.menustate].drawfunc
		cmenu[m.menustate].drawfunc(v, m.animtimer, cmenu[m.menustate].choices, m.choice)
	end	-- sub menu drawing function goes above

	if m.prompttype
		v.draw(0, 0, v.cachePatch("H_RIP4"), V_50TRANS|V_SNAPTOTOP|V_SNAPTOLEFT)	-- blacken background

		local tgty = 100 - (10*(#m.prompttext+1))/2 -2
		local height = 10*(#m.prompttext+1) +4

		local ypos = tgty + m.promptanim*20

		v.drawFill(64, ypos + 10, 192, height, 135)	-- box
		-- text
		local text = m.prompttext
		text[#text+1] = m.prompttype == PT_YESNO and "\x82".."ENTER: YES     ESC: NO" or "\x82".."OK"
		if m.prompttype == PT_GAMECONTROL
			text[#text] = "\x82".."PRESS A KEY"
		end

		for i = 1, #text
			V_drawString(v, 160, ypos+2 +(i*10), m.prompttext[i], "NFNT", 0, "center", 0, 31)
		end
		table.remove(text, #text)
	end
end)

rawset(_G, "SYS_closeMenu", function()
	--dprint("Closing menu")

	SYS_eatEvents(false)
	SYS_flushEventQueue()	-- flush event buffer for use in menus

	SYS_systemmenu = {
		running = false,
		runningfor = 0,
		menu = 0,		-- SM_ constants
		menustate = 0,	-- MS_ constants

		textfields = {},-- for CT_TEXTFUNCTION
		choice = 0,		-- the menu's choice table.
		animtimer = 0,	-- animation timer for the menu. Goes down by 1 until it hits 0
		scrollx = 0,	-- menu scrolling, x dir. positive is ->, negative is <-
		scrolly = 0,	-- menu scrolling, y dir. positive is V, negative is ^

		-- prompt
		prompttext = nil,
		prompttype = 0,	--PT_NONE
		promptgoto = 0,
		promptanim = 0,
	}
end)


