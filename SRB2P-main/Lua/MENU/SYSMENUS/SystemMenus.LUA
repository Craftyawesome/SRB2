-- SRB2P Title screen menu code

rawset(_G, "cv_personatest", CV_RegisterVar({
  name = "__&personatest",
  defaultvalue = "1",
  PossibleValue = {MIN = 1, MAX = #sorted_personaList}
}))

rawset(_G, "cv_leveltest", CV_RegisterVar({
  name = "__&leveltest",
  defaultvalue = "10",
  PossibleValue = {MIN = 10, MAX = 99}
}))

rawset(_G, "cv_musicedit", CV_RegisterVar({
  name = "__&musedit",
  defaultvalue = "Battle",

  PossibleValue = {Battle = 0, PlayerAdvantage = 1, EnemyAdvantage = 2, StrongEnemy = 3, MiniBoss = 4, PVP = 5, Results = 6},
}))

rawset(_G, "cv_musiceditindex", CV_RegisterVar({
  name = "__&musedit2",
  defaultvalue = 1,

  PossibleValue = CV_Natural,
}))

-- quick check for tutorial:


local function mm_startTutorial()
	SYS_closeMenu()

	-- ready save localtable loading:
	SAVE_localtable.party = {"sonic", "amy"}
	SAVE_localtable.tutorial = true

	COM_ImmedExecute("map map"..string.format("%02d", srb2p.tutorial_map).." -force")
	-- @TODO: D_MapChange to bypass the need for -force
end

-- check if the tutorial message was displayed
-- also checks for data clear message
local function mm_checkTutorial()

	if srb2p.cleared_xdata
		P_unlock(UNLOCK_TUTORIAL)
		srb2p.cleared_xdata = nil
		-- Re-"Unlock" the tutorial by default
		SYS_CreatePrompt("Hello and welcome back to SRB2P!\nYour \x82".."unlockables save data".."\x80".."\nhas been erased due to the changes\nbrought by this update.\nHave fun with the new content!", PT_NOTIFICATION)

	elseif not srb2p.local_conds[UNLOCK_TUTORIAL]
		-- bring up the thing:
		SYS_CreatePrompt("Hello and welcome to SRB2P!\nIt seems this is your first time.\nWould you like to play a tutorial?\n\n(You will be able to play it regardless\nfrom the Singleplayer menu)", PT_YESNO, mm_startTutorial)

		-- regardless of what's going on, "unlock" the condition so that this doesn't show up anymore.
		P_unlock(UNLOCK_TUTORIAL)
	end
end

local editmusic_tables = {
	[0] = "mus_battle",
	[1] = "mus_battle_pa",
	[2] = "mus_battle_ea",
	[3] = "mus_battle_s",
	[4] = "mus_battle_mb",
	[5] = "mus_battle_pvp",
	[6] = "mus_battle_results"
}


local function mm_textSelectMusic(text)
	-- trim spaces:
	text = string.gsub(text, " ", ""):upper()
	if not #text
	or #text > 6
		SYS_CreatePrompt("No, this isn't how you're\nsupposed to add music!", PT_NOTIFICATION, nil)
		return
	end

	local t = SAVE_localmusictable[editmusic_tables[cv_musicedit.value]]
	S_ChangeMusic(text, true)

	if SRB2P_getMusicDef(text:lower())
		SYS_CreatePrompt("Now playing: \'"..text.."\'\nAdd this music to the table?", PT_YESNO,
		function()
			t[cv_musiceditindex.value] = text
			SYS_SwitchMenuState(MS_CUSTOMMUSIC)
		end)
	else
		SYS_CreatePrompt("\x82".."WARNING\x80:\nLump "..text.." has no MUSICDEF entry.\nIf you don't hear any music right now,\nyou probably got the lump name wrong.\nAdd this music to the table?", PT_YESNO,
		function()
			t[cv_musiceditindex.value] = text
			SYS_SwitchMenuState(MS_CUSTOMMUSIC)
		end)
	end
end
local cache_musics = {}

local function mm_selectMusic()
	local t = SAVE_localmusictable[editmusic_tables[cv_musicedit.value]]
	-- add the last choice to the table

	local m = SYS_systemmenu

	if not m or not m.running return end
	local cmenu = SYS_menus[m.menu][m.menustate]

	local lump = cmenu.choices[m.choice][8]
	S_ChangeMusic(lump:upper(), true)

	SYS_CreatePrompt("Now playing: \'"..lump:upper().."\'\nAdd this music to the table?", PT_YESNO,
	function()
		t[cv_musiceditindex.value] = lump:upper()
		SYS_SwitchMenuState(MS_CUSTOMMUSIC)
	end)
end

local function mm_handlecustomMusic(m, choices, curchoice, e)

	if not #cache_musics
		cache_musicdefs()
		SYS_menus[m.menu][MS_CHANGEMUSIC].choices = cache_musics
	end

	local t = SAVE_localmusictable[editmusic_tables[cv_musicedit.value]]
	COM_ImmedExecute(cv_musiceditindex.name.." "..curchoice-1)

	if e == KEY_ARROWD
		if curchoice-1 > #t
			m.choice = 1
			S_StartSound(nil, sfx_hover)
			return true
		end

	elseif e == KEY_ARROWU
		if curchoice-2 > #t
		or curchoice == 1
			m.choice = min(11, #t+2)
			S_StartSound(nil, sfx_hover)
			return true
		end

	elseif e == KEY_ESCAPE
		if curchoice > 1
			if #t > 1 and t[curchoice-1]
				table.remove(t, curchoice-1)
			else
				S_StartSound(nil, sfx_not)
			end
			return true
		else
			SAVE_put_musicdata()	-- save music data
			print("Saved music data succesfully.")
		end
	end
end

local function mm_drawChangeMusic(v, anim, choices, curchoice)
	local t = TICRATE/4 - anim
	local scale = max(1, t*FRACUNIT /3)
	if scale/FRACUNIT < 2
		v.drawScaled(160<<FRACBITS, 100<<FRACBITS, scale, v.cachePatch("H_1M_B"), V_40TRANS)
	else
		v.fadeScreen(135, 6)
	end

	local width = max(0, 70 - anim*12)

	v.drawFill(100 - width/2, 0, width, 300, 31|V_SNAPTOTOP)

	SYS_drawGenericMenu(v, anim, choices, curchoice)
	local baseypos = 0 - SYS_systemmenu.scrolly

	for i = 2, #choices

		if baseypos + choices[i][3] < 176
			V_drawString(v, 100, baseypos + choices[i][3], choices[i][9], "NFNT", 0, "center", 0, 31)
		end
	end
end

rawset(_G, "cache_musicdefs", function()
	cache_musics = {	{"Custom Lump", 100, 24, CT_TEXTFUNCTION, mm_textSelectMusic, nil, "Specify Lump name to add. (Without the 'O_')"}}
	local musiclist = {SRB2P_getMusicList()}

	for i = 2, #musiclist
		local title, author = SRB2P_getMusicDef(musiclist[i])
		cache_musics[i] = {"", 100, 54 +(i-2)*12, CT_FUNCTION, mm_selectMusic, nil, author, musiclist[i], title}
	end
end)

local menus = {
	"SM_TITLE",
	"SM_PAUSE",
	"SM_PAUSE_SP",
}
-- define system menus
for i = 1, #menus do
	rawset(_G, menus[i], i)
end

local menustates_main = {
	"MS_TITLE",	-- Main title screen, PRESS ENTER

	"MS_MAIN",	--	Story, QP, Settings, Quit

	"MS_STORY",
	"MS_QUICKPLAY",
	"MS_SETTINGS",

	"MS_1PLAYER",
	"MS_SAVESELECT",

	"MS_SETUPPLAYER",

	"MS_SETCONTROLS",
	"MS_DISPLAYOPTIONS",
	"MS_SOUNDOPTIONS",
	"MS_NETOPTIONS",

	"MS_DEBUG",
	"MS_SKILLIST",
	"MS_ITEMLIST",
	"MS_PERSONALIST",

	"MS_MOUSEOPTIONS",
	"MS_CONTROLLEROPTIONS",

	"MS_COLOURPROFILES",
	"MS_CHATOPTIONS",
	"MS_OPENGL",

	"MS_NETGAMEPLAYOPTIONS",

	"MS_CUSTOMMUSIC",
	"MS_CHANGEMUSIC",
}

-- define menustates
for i = 1, #menustates_main do
	rawset(_G, menustates_main[i], i)
end

local function mm_drawMainScreen(v, t)

	local scale = FRACUNIT/2 + (sin(leveltime*ANG1*20)) / 32
	v.drawScaled(64*FRACUNIT, 132*FRACUNIT, scale, v.cachePatch("SS_ENTER"), V_SNAPTOBOTTOM|V_SNAPTOLEFT)

	local cond = (leveltime%30 < 15)
	if SYS_systemmenu.switchingstate
		cond = (leveltime%4 < 2)
	end

	if cond
		V_drawString(v, 64, 128, "PRESS ENTER", "NFNT", V_SNAPTOBOTTOM|V_SNAPTOLEFT, "center", 0, 31)
	end

	V_drawString(v, 0, 182, "SRB2PERSONA\n"..srb2p.version, "NFNT", V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_TRANSLUCENT, nil, 0, 31)
end

local function mm_hostNetGame()
	print("Starting up server...")
	SYS_closeMenu()
	SRB2P_startServer()	-- this is atrocious. don't do this. seriously.
	COM_ImmedExecute("map map"..string.format("%02d", srb2p.tartarus_map))
end

local function mm_joinNetGame(text)
	-- trim spaces:
	text = string.gsub(text, " ", "")
	if not #text
		SYS_CreatePrompt("Please enter an address", PT_NOTIFICATION, nil)
		return
	end

	SYS_closeMenu()
	print("Joining netgame at "..text.."...")
	COM_ImmedExecute("connect "..text)
end

local function mm_quitSRB2()
	COM_ImmedExecute("quit")
end

local function mm_drawSettings(v, anim, choices, curchoice)

	choices[4][6] = nil	-- netplay options

	if server and consoleplayer
	and server ~= consoleplayer
		choices[4][6] = CS_GREYOUT	-- can't access netplay options if you're not the server !!!
	end

	local t = TICRATE/4 - anim
	local scale = max(1, t*FRACUNIT /3)
	if scale/FRACUNIT < 2
		v.drawScaled(160<<FRACBITS, 100<<FRACBITS, scale, v.cachePatch("H_1M_B"), V_40TRANS)
	else
		v.fadeScreen(135, 6)
	end

	PDraw(v, min(0, -anim*24), 0, v.cachePatch("SS_OPT1"), V_SNAPTOLEFT)
	PDraw(v, 320+anim*24, 0, v.cachePatch("SS_OPT2"), V_SNAPTORIGHT)

	SYS_drawGenericMenu(v, anim, choices, curchoice)
end

local function mm_genericOptions(v, anim, choices, curchoice)
	local t = TICRATE/4 - anim
	local scale = max(1, t*FRACUNIT /3)
	if scale/FRACUNIT < 2
		v.drawScaled(160<<FRACBITS, 100<<FRACBITS, scale, v.cachePatch("H_1M_B"), V_40TRANS)
	else
		v.fadeScreen(135, 6)
	end

	local width = max(0, 70 - anim*12)

	v.drawFill(100 - width/2, 0, width, 300, 31|V_SNAPTOTOP)

	SYS_drawGenericMenu(v, anim, choices, curchoice)
end

local function mm_customMusic(v, anim, choices, curchoice)
	local t = TICRATE/4 - anim
	local scale = max(1, t*FRACUNIT /3)
	if scale/FRACUNIT < 2
		v.drawScaled(160<<FRACBITS, 100<<FRACBITS, scale, v.cachePatch("H_1M_B"), V_40TRANS)
	else
		v.fadeScreen(135, 6)
	end

	local width = max(0, 70 - anim*12)

	v.drawFill(100 - width/2, 0, width, 300, 31|V_SNAPTOTOP)

	SYS_drawGenericMenu(v, anim, choices, curchoice)

	local y = 48
	local t = SAVE_localmusictable[editmusic_tables[cv_musicedit.value]]

	if not t return end	-- bruh?

	for i = 1, 10
		local str = t[i] or "\x86".."----"
		if SRB2P_getMusicDef(str:lower())
			str = SRB2P_getMusicDef(str:lower())
		end

		V_drawString(v, 100, y + (i-1)*10, str, "NFNT", 0, "center", 0, 31)
	end
end

local v_modes = {
	"1920x1080",
	"1680x945",
	"1600x900",
	"1366x768",
	"1440x810",
	"1280x720",
	"1152x864",
	"1152x648",
	"1024x768",
	"1024x576",
	"800x600",
	"800x450", --12
	"640x480",
	"640x400",
	"640x360",
	"320x240",
	"320x200",
}
-- no, 320x200 is not supported, fuck OFF.
local setres = 12	--800x450 is default

-- sets the video mode
local function mm_setVidMode()
	COM_ImmedExecute("vid_mode "..(setres -1))

	-- get w/h
	local wh = {"", ""}
	local index = 1
	local str = v_modes[setres]

	for i = 1, #str
		local cur = str:sub(i, i)
		if tonumber(cur) ~= nil
			wh[index] = $..tostring(cur)		-- get width / height char by char
		else	-- that's the "x"
			index = $+1
		end
	end

	COM_ImmedExecute("scr_width "..wh[1])
	COM_ImmedExecute("scr_height "..wh[2])	-- overwrite defaults
end

local function mm_drawOpenGLOptions(v, anim, choices, curchoice)
	mm_genericOptions(v, anim, choices, curchoice)

	V_drawString(v, 160, 32, "\x82The options below only apply to OpenGL mode", "NFNT", 0, "center", 0, 31)
end

local function mm_handleVideoSettings(m, choices, curchoice, e)
	if curchoice ~= 1 return end	-- not on the resolution setting

	if e == KEY_ARROWR
		setres = $-1
		if setres < 1
			setres = #v_modes
		end
		S_StartSound(nil, sfx_hover)
	elseif e == KEY_ARROWL
		setres = $+1
		if setres > #v_modes
			setres = 1
		end
		S_StartSound(nil, sfx_hover)
	end
end

local function mm_drawVideoSettings(v, anim, choices, curchoice)

	mm_genericOptions(v, anim, choices, curchoice)

	local c = choices[1]
	local cur = (curchoice == 1)	-- first choice is the video resolution thing

	local resy = c[3] +2
	local text = v_modes[setres]
	if cur
		text = "\x82".."<"..v_modes[setres]..">"
		if leveltime%20 < 10
			text = "\x82".."< "..v_modes[setres].." >"
		end
	end

	V_drawString(v, c[2] + 155, resy, text, "NFNT", 0, "center", 0, 31)
end

local loc_skin
local loc_colour
local maxskin = 0
local loc_scroll = 0	-- will +1 or -1
local loc_scroll_colour = 0	-- ditto

local function mm_drawPlayerSetup(v, anim, choices, curchoice)

	if loc_skin == nil
		local skincv = CV_FindVar("defaultskin")
		if skincv
			for i = 0, 254 do
				if skins[i] and skins[i].valid and skins[i].name == skincv.string

					if not P_unlockedCharacter(skins[i].name)	-- yikes!
						loc_skin = 0
						COM_ImmedExecute("skin 0")
						COM_ImmedExecute("defaultskin 0")
						break
					end

					loc_skin = i
					break
				end
			end
		end
		if loc_skin == nil	-- failed still?
			loc_skin = 0
		end
		loc_colour = CV_FindVar("defaultcolor").value
	end

	mm_genericOptions(v, anim, choices, curchoice)

	for i = 0, 254
		if skins[i] and skins[i].valid
			maxskin = i
		else
			break	-- no reason to keep going, all skins from there will be invalid as well
		end
	end

	-- now for the not-so generic stuff:
	loc_colour = CV_FindVar("color").value	-- this should always be up-to date from now on

	if not ((anim < 5 and anim%2) or not anim) return end	-- cba

	local skin_y = choices[2][3] + 54
	local skin_x = choices[2][2]	--xpos

	-- start at "selected skin -1"
	local backskin = 2	-- go 2 skins back
	local curskin = loc_skin

	while backskin
		curskin = $-1
		if curskin < 0
			curskin = maxskin
		end
		backskin = $-1
	end

	if loc_scroll
		loc_scroll = $/2
	end

	local charcount = 1
	for i = 1, 5	-- 2 to the back, cur skin, 2 to the front

		local newskin

		if not P_unlockedCharacter(skins[curskin].name)
			if i < 3	-- rather weird hack but it works.
				newskin = curskin-1
				if newskin < 0
					newskin = maxskin
				end
			elseif i > 3
				curskin = $+1
				if curskin > maxskin
					curskin = 0
				end
			end
			--continue	-- ommit this skin
		end

		local xpos = (skin_x) -128  +(64*(charcount-1)) + loc_scroll
		local transflag = abs(skin_x - xpos) / 9	-- @ 64 dist: 70% translucency

		if transflag >= 0 and transflag < 10
			local sprite2 = v.getSprite2Patch(skins[newskin or curskin].name, SPR2_STND, false, A, 2)

			v.drawScaled(xpos*FRACUNIT, skin_y*FRACUNIT, FRACUNIT/2, sprite2, transflag << V_ALPHASHIFT, v.getColormap(TC_DEFAULT, loc_colour))
		end

		curskin = $+1
		charcount = $+1
		if curskin > maxskin
			curskin = 0
		end
	end

	-- draw the skin text, ala generic menu fashion
	local text = skins[loc_skin].realname
	if curchoice == 2	-- on skin option
	and not (server)
		text = "\x82".."<"..$..">"
		if leveltime%20 < 10
			text = "\x82".."< "..skins[loc_skin].realname.." >"
		end
	end
	V_drawString(v, choices[2][2] + 155, choices[2][3]+2, text, "NFNT", 0, "center", 0, 31)

	-- and now we go and have fun with colours

	local dispcolour = min(MAXSKINCOLORS-1, loc_colour)
	local back = 5	-- how many indexes we'll go back by
	local xpos = choices[3][2]

	while back
		dispcolour = $-1
		if dispcolour < 1
			dispcolour = MAXSKINCOLORS-1
		end

		xpos = $ - 8
		back = $-1
	end
	-- and now we begin the displayening

	if loc_scroll_colour
		loc_scroll_colour = $/2
	end

	for i = 1, 11	-- 10 colours in advance sounds like plenty!

		local tflag = abs(choices[3][2] - xpos) / 3
		if tflag >= 0 and tflag < 10
			v.drawScaled((xpos + loc_scroll_colour)*FRACUNIT, (choices[3][3] + 16)*FRACUNIT, FRACUNIT/2, v.cachePatch("SS_CBAL"), tflag << V_ALPHASHIFT, v.getColormap(TC_DEFAULT, dispcolour))
		end
		dispcolour = $+1
		if dispcolour > MAXSKINCOLORS-1
			dispcolour = 1
		end
		xpos = $+8
	end
end

local function mm_handlePlayerSetup(m, choices, curchoice, e)

	local canselectskin = true
	if server
		canselectskin = false
	end

	if curchoice == 2	-- skin
	and maxskin			-- maxskin defined
		if e == KEY_ARROWR	-- skin++

			if not canselectskin
				S_StartSound(nil, sfx_not)
				return
			end

			loc_skin = $+1
			if loc_skin > maxskin
				loc_skin = 0
			end

			while (not P_unlockedCharacter(skins[loc_skin].name))
				loc_skin = $+1
				if loc_skin > maxskin
					loc_skin = 0
				end
			end

			loc_scroll = 64

			S_StartSound(nil, sfx_hover)
			COM_ImmedExecute("skin "..skins[loc_skin].name)
		elseif e == KEY_ARROWL

			if not canselectskin
				S_StartSound(nil, sfx_not)
				return
			end

			loc_skin = $-1
			if loc_skin < 0
				loc_skin = maxskin
			end

			while (not P_unlockedCharacter(skins[loc_skin].name))
				loc_skin = $-1
				if loc_skin < 0
					loc_skin = maxskin
				end
			end

			loc_scroll = -64

			S_StartSound(nil, sfx_hover)
			COM_ImmedExecute("skin "..skins[loc_skin].name)	-- update these
		end
	elseif curchoice == 3	-- colour

		if e == KEY_ARROWR
			loc_scroll_colour = 8
		elseif e == KEY_ARROWL
			loc_scroll_colour = -8
		end
		-- do the same bs to a lesser extent
	end
end

-- saves our current local data into defaults:
local function mm_saveDefaultSkin()

	if CV_FindVar("skin").string == CV_FindVar("defaultskin").string
	and loc_colour == CV_FindVar("defaultcolor").value
		SYS_CreatePrompt("Those are already\nyour defaults.", PT_NOTIFICATION, nil)
		return
	end

	COM_ImmedExecute("defaultskin "..skins[loc_skin].name)
	COM_ImmedExecute("defaultcolor "..loc_colour)
	SYS_CreatePrompt("Default saved succesfully!", PT_NOTIFICATION, nil)
end

-- colour profile accessibility
local function mm_colourProfile(v, anim, choices, curchoice)
	mm_genericOptions(v, anim, choices, curchoice)

	if (anim < 5 and anim%2) or not anim

		local colours = {35, 73, 112, 255, 152, 181}
		local xpos = 1
		for i = 1, #colours do
			v.drawFill(xpos, 181, 52, 8, colours[i])
			xpos = $+53
		end
	end
end

local function mm_resetColourProfile()
	local cmd = {"hue", "saturation", "gamma"}
	local prefixes = {"r", "y", "g", "c", "m", "b"}

	local cmdn
	for i = 1, #prefixes do
		for j = 1, #cmd do
			cmdn = prefixes[i]..cmd[j]	-- command name built
			--print(cmdn)
			local cvar = CV_FindVar(cmdn)
			if cvar
				COM_ImmedExecute(cvar.name.." "..cvar.defaultvalue)	-- magic!
			end
		end
	end
end

local function mm_pickUpController()
	-- won't do anything if no controller is plugged anyway
	COM_ImmedExecute("use_gamepad 1")

	-- @TODO: push lua hcks to allow controller selection, local coop for campaign could be cool!
end

local main_hints = {
	"Play through the campaign",
	"Tackle Tartarus and its challenges alone or with friends online!",
	"Change game settings and controls",
	"Add mods into the game",
	"Return to desktop",
}

-- pause menus:

local function pm_pauseMain(v, anim, choices, curchoice)
	local t = TICRATE/4 - anim
	local scale = max(1, t*FRACUNIT /3)
	if scale/FRACUNIT < 2
		v.drawScaled(160<<FRACBITS, 100<<FRACBITS, scale, v.cachePatch("H_1M_B"), V_40TRANS)
	else
		v.fadeScreen(135, 6)
	end

	local width = max(0, 70 - anim*12)

	v.drawFill(160 - width/2, 0, width, 300, 31|V_SNAPTOTOP)

	SYS_drawGenericMenu(v, anim, choices, curchoice)
end

local function mp_checkMPPause(m, choices, curchoice, e)

	choices[4][6] = CS_GREYOUT
	if consoleplayer and consoleplayer.valid
	and consoleplayer == server
		choices[4][6] = 0
	end
end

-- force the close animation
local function mp_closePauseMenu()
	-- quick hack
	local m = SYS_systemmenu
	m.switchingstate = TICRATE/2
	m.newmenu = -1
end

-- quit the netgame
local function mp_quitNetGame()
	SRB2P_killHUD()	-- fuck warnings
	SYS_closeMenu()	--ASAP
	COM_ImmedExecute("exitgame")
end

-- return to lobby
local function mp_returnToLobby()
	SRB2P_killHUD()
	SYS_closeMenu()
	COM_ImmedExecute("map "..G_BuildMapName(srb2p.tartarus_map))
end

	--	drawfunc = mm_drawPersonalist,
	--	func = mm_dummyPersona,

-- used to spawn a fake persona to use the frames of in mm_drawPersonaList~

local dummyPersona

local function mm_dummyPersona()

	if not dummyPersona or not dummyPersona.valid
		dummyPersona = P_SpawnMobj(0, 0, 0, MT_DUMMY)
		print("Spawning dummy")
		dummyPersona.tics = -1

		local persona = personaList[sorted_personaList[cv_personatest.value]]
		ANIM_set(dummyPersona, persona.anim_idle, true)
		dummyPersona.lastp = cv_personatest.value
	else
		ANIM_handle(dummyPersona)
		dummyPersona.fuse = 2

		local persona = personaList[sorted_personaList[cv_personatest.value]]

		if cv_personatest.value ~= dummyPersona.lastp
		or ANIM_done(dummyPersona, persona.anim_atk)
			ANIM_set(dummyPersona, persona.anim_idle, true)
			dummyPersona.lastp = cv_personatest.value
		end
	end
end

local function mm_personaAttackAnim()
	if dummyPersona and dummyPersona.valid
		local persona = personaList[sorted_personaList[cv_personatest.value]]
		ANIM_set(dummyPersona, persona.anim_atk)
	end
end

local function mm_drawPersonalist(v, anim, choices, curchoice)
	local t = TICRATE/4 - anim
	local scale = max(1, t*FRACUNIT /3)
	if scale/FRACUNIT < 2
		v.drawScaled(160<<FRACBITS, 100<<FRACBITS, scale, v.cachePatch("H_1M_B"), V_40TRANS)
	else
		v.fadeScreen(135, 6)
	end

	local width = max(0, 70 - anim*10)

	v.drawFill(100 - width/2, 0, width, 300, 31|V_SNAPTOTOP)

	SYS_drawGenericMenu(v, anim, choices, curchoice)

	if dummyPersona and dummyPersona.valid

		local pp = v.getSpritePatch(dummyPersona.sprite, dummyPersona.frame, 2)
		v.drawScaled(100<<FRACBITS, 160<<FRACBITS, FRACUNIT/2, pp, V_SNAPTOBOTTOM)
	end

	-- now compute what skills we'd have at this level:
	local persona = personaList[sorted_personaList[cv_personatest.value]]
	local skills = {}

	local level = cv_leveltest.value

	for k,v in ipairs(persona.skills or {})
		if v

			if level >= v[2]
				-- but do we have the skill we need to remove, first?
				local found
				for rk, vv in ipairs(skills)
					if vv == v[3]
						--dprint("Removed "..vv)
						--table.remove(skills, rk)
						skills[rk] = v[1]
						found = true
					end
				end

				if not found
					-- add skill
					skills[#skills+1] = v[1]
				end
			end
		end
	end

	-- now display them...
	-- draw skills
	local x, y = 140, 96
	for i = 1, 8 do
		v.drawFill(x, y, 64, 10,  31|V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		local skname = (skills[i] or "/")
		local atype = 0

		if attackDefs[skname]
			if attackDefs[skname].type & ATK_PASSIVE
				atype = 15
			else
				atype = atk_constant_2_num[attackDefs[skname].type]
			end
			skname = attackDefs[skname].name
		end

		if atype
			v.drawScaled(x*FRACUNIT, (y+1)*FRACUNIT, FRACUNIT/4, v.cachePatch("ATK_"..atype), V_SNAPTOBOTTOM|V_SNAPTOLEFT)
			v.drawIndex(x*FRACUNIT, (y+1)*FRACUNIT, FRACUNIT/4, v.cachePatch("H_ELMF3"), V_SNAPTOBOTTOM|V_SNAPTOLEFT, 31)
		end
		V_drawString(v, x+32, y + 2, skname, "NFNT", V_SNAPTOBOTTOM|V_SNAPTOLEFT, "center", 0)
		if i%4 == 0
			x = $ + 68
			y = 96
		else
			y = $ + 12
		end
	end

	-- draw NEXT skill if we have one.
	local nextskill
	-- search for skills we can't learn with our current level progression FIRST, then we look in the skillqueue table to overwrite info
	for i = 1, #persona.skills
		local s = persona.skills[i]
		if s and s[2] and s[2] > level
			nextskill = s
			break
		end
	end

	-- display NEXT skill:
	if nextskill

		x = 140
		y = 144

		V_drawString(v, x, y, "NEXT: LV"..nextskill[2], "NFNT", V_SNAPTOTOP|V_SNAPTOLEFT, nil, 31, nil)
		v.drawFill(x, y+10, 64, 10, 31|V_SNAPTOTOP|V_SNAPTOLEFT)	-- we need a box o coc riiiiight here
		local nskname = nextskill[1]
		if attackDefs[nskname]
			nskname = attackDefs[$].name
		end

		V_drawString(v, x+32, y+12, nskname, "NFNT", V_SNAPTOTOP|V_SNAPTOLEFT, "center", 0)	-- skill name
	end
end

-- ready the debug menus:
local dbg_skillist = {}
for i = 1, #sorted_attackDefs do

	local s = sorted_attackDefs[i]
	local name = attackDefs[s] and attackDefs[s].name or "INVALID SKILL"

	dbg_skillist[i] = {name:upper(), 64, 32+ (i-1)*12, nil, nil, nil, "", s}
end

local function mm_drawSkilllist(v, anim, choices, curchoice)
	local t = TICRATE/4 - anim
	local scale = max(1, t*FRACUNIT /3)
	if scale/FRACUNIT < 2
		v.drawScaled(160<<FRACBITS, 100<<FRACBITS, scale, v.cachePatch("H_1M_B"), V_40TRANS)
	else
		v.fadeScreen(135, 6)
	end

	local width = max(0, 64 - anim*10)

	v.drawFill(64 - width/2, 0, width, 300, 31|V_SNAPTOTOP)

	SYS_drawGenericMenu(v, anim, choices, curchoice)

	-- now draw skill info
	v.drawFill(160, 0, 320 - 160, 300 - anim*40, 31|V_SNAPTORIGHT|V_SNAPTOTOP)

	local skname = attackDefs[choices[curchoice][8]] and attackDefs[choices[curchoice][8]].name or "INVALID SKILL"
	local inname = choices[curchoice][8]	-- internal name

	V_drawString(v, 165, 24, "\x82".."Name: ".."\x80".."\'"..skname.."\'", "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)
	V_drawString(v, 165, 34, "\x82".."Internal Name: ".."\x80".."\'"..inname.."\'", "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)

	local atk = attackDefs[choices[curchoice][8]]
	if not atk return end	-- no

	local desc = atk.desc or "No decription"
	V_drawString(v, 165, 44, "\x82".."Description:\n".."\x80"..desc, "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)

	local types = {
		"\x87".."Slash",
		"\x87".."Strike",
		"\x87".."Pierce",
		"\x85".."Fire",
		"\x88".."Ice",
		"\x83".."Wind",
		"\x82".."Elec",
		"\x89".."Psy",
		"\x8A".."Nuclear",
		"\x82".."Bless",
		"\x85".."Curse",
		"\x80".."Almighty",
		"\x83".."Heal",
		"\x84".."Support",
		"\x87".."(Passive)",
	}

	local t = ""
	local w = V_stringWidth(v, "Type(s):", "NFNT")
	local numlines = 10

	for i = 0, 31
		if atk.type & (2^i)
			local s = (types[i+1] or "???").."\x80"..", "
			w = $+ V_stringWidth(v, s, "NFNT")
			if w >= 155*FRACUNIT
				s = "\n"..(types[i+1] or "???").."\x80"..", "
				numlines = $+10
				w = 0
			end

			t = $..s
		end
	end
	V_drawString(v, 165, 76, "\x82".."Type(s): ".."\x80"..t, "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)


	if atk.passive
		local psvname = {
			"Evasion",
			"Resist",
			"Block",
			"Drain",
			"Repel",

			"Damage Boost",

			"Endure",

			"Battle Start",
			"Each Turn",
			"Battle end",

			"Condition resist",
			"Condition block",

			"Condition Boost",
		}

		local psvs = psvname[atk.passive] or "INVALID PASSIVE"

		if atk.passive == PSV_REPEL
		and atk.accuracy
			psvs = $.." ("..atk.accuracy.."% chance)"

		elseif atk.passive == PSV_DODGE
			psvs = $.." ("..atk.power.."% chance)"

		elseif atk.passive == PSV_BOOST
		and atk.power
			psvs = $.." ("..atk.power.."%)"

		elseif atk.passive == PSV_ENDURE
			if atk.accuracy
				psvs = $.." ("..atk.accuracy.."%)"
			end
			if atk.power
				psvs = $.."\n"..atk.power.." times"
			end
			if atk.instakill
				psvs = $.."\nOnly works on instant kills"
			end
		end

		V_drawString(v, 165, 76+numlines, "\x82".."Passive: ".."\x80"..psvs, "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)
		return
	end


	local cost = atk.cost or ""
	local costtype = "\x89".." SP"

	if cost == ""
		costtype = "/"
	elseif atk.costtype == CST_HP
		costtype = "\x88".." HP"
	elseif atk.costtype == CST_HPPERCENT
		costtype = "\x88".."% HP"
	elseif atk.costtype == CST_SPPERCENT
		costtype = "\x89".."% SP"
	elseif atk.costtype == CST_EP
		costtype = "\x83".." EP"
	end

	V_drawString(v, 165, 76+numlines, "\x82".."Cost: ".."\x80"..cost..costtype, "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)

	-- target
	local tgts = {
		[TGT_ENEMY] = "1 enemy",
		[TGT_ALLENEMIES] = "All enemies",
		[TGT_ALLY] = "Ally",
		[TGT_ALLALLIES] = "Party",
		[TGT_CASTER] = "User",
		[TGT_DEAD] = "Fallen",
		[TGT_EVERYONE] = "Everyone",
	}

	V_drawString(v, 165, 86+numlines, "\x82".."Target(s): ".."\x80"..tgts[atk.target] or "INVALID TARGET", "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)

	local pow = atk.power
	if pow and pow > 999
	or atk.instakill
	or not pow
		pow = "--"
	end

	local acc = atk.accuracy
	if not acc
		acc = "--"
	else
		acc = $.."%"
	end

	local crit = atk.critical
	if not crit
		crit = "--"
	else
		crit = $.."%"
	end

	local hits = atk.hits or 1

	V_drawString(v, 165, 96+numlines, "\x82".."Power: ".."\x80"..pow.." \x82".."Acc: ".."\x80"..acc, "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)
	V_drawString(v, 165, 106+numlines, "\x82".."Crit: ".."\x80"..crit.."\x82 ".."Hits: ".."\x80"..hits, "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)

	local conditions = {
		[COND_BURN]="\x85".."Burn",
		[COND_FREEZE]="\x88".."Freeze",
		[COND_SHOCK]="\x82".."Shock",
		[COND_BRAINWASH]="\x8E".."Brainwash",
		[COND_DIZZY]="\x87".."Dizzy",
		[COND_SILENCE]="\x83".."Silence",
		[COND_SLEEP]="\x86".."Sleep",
		[COND_HEX]="\x89".."Hex",
		[COND_DESPAIR]="\x89".."Despair",
		[COND_RAGE]="\x85".."Rage",
		[COND_HUNGER]="\x83".."Hunger",
		[COND_POISON]="\x89".."Poison",
		[COND_HYPER]="\x80".."Hyper",
		--"\x82".."Super",
	}

	if atk.status
		local s = conditions[atk.status] or "INVALID STATUS"
		local c = atk.statuschance and atk.statuschance.."%" or "--"

		V_drawString(v, 165, 116+numlines, "\x82".."Status: ".."\x80"..s.."\x80".." ("..c..")", "NFNT", V_SNAPTOTOP|V_SNAPTORIGHT, nil, 0, 31)
	else
		numlines = $-10
	end
end

-- WHY do I have to do this
addHook("MapLoad", do

SYS_closeMenu()	-- always.

--CV_FindVar isn't loaded by the time we reach this spot, so do it as the titlemap loads instead
if SYS_menus[SM_TITLE] return end

-- some menustates are shared between menus, so define their choices here to make editing easier

local settings_opt = {

	{"Control Options", 160, 64, CT_MENUSTATE, MS_SETCONTROLS, nil, "Change your key mapping and preferences."},
	{"Display Options", 145, 88, CT_MENUSTATE, MS_DISPLAYOPTIONS, nil, "Change display related options such as the resolution."},
	{"Sound Options", 135, 100, CT_MENUSTATE, MS_SOUNDOPTIONS, nil, "Change sound related options such as the game volume."},
	{"Netplay Options", 120, 124, CT_MENUSTATE, MS_NETOPTIONS, nil, "Change netplay related options"},
	{"Debug",  105, 136, CT_MENUSTATE, MS_DEBUG, nil, "Toggle debugging features & check global tables"}
}

local control_opt = {
	
	{"CURSOR MEMORY", 100, 8, CT_CVAR, cv_cursormemory, nil, "If on, cursor position is kept between turns."},
	{"INVERT COMMAND", 100, 20, CT_CVAR, cv_invertcommand, nil, "If on, flips the rotation of the battle wheel."},

	{"MOVE FORWARD", 100, 44, CT_GAMECONTROL, gc_forward, nil, "Set game controls"},
	{"MOVE BACKWARDS", 100,56, CT_GAMECONTROL, gc_backward, nil, "Set game controls"},
	{"MOVE LEFT", 100, 68, CT_GAMECONTROL, gc_strafeleft, nil, "Set game controls"},
	{"MOVE RIGHT", 100, 80, CT_GAMECONTROL, gc_straferight, nil, "Set game controls"},
	{"TURN LEFT", 100, 92, CT_GAMECONTROL, gc_turnleft, nil, "Set game controls"},
	{"TURN RIGHT", 100, 104, CT_GAMECONTROL, gc_turnright, nil, "Set game controls"},

	-- SRB2P Buttons
	{"A BUTTON", 100, 128, CT_GAMECONTROL, gc_jump, nil, "Jump/Confirm"},
	{"B BUTTON", 100, 140, CT_GAMECONTROL, gc_use, nil, "Open Menu/Back"},
	{"C BUTTON", 100, 152, CT_GAMECONTROL, gc_tossflag, nil, "Interact/Misc"},
	{"L BUTTON", 100, 164, CT_GAMECONTROL, gc_weaponprev, nil, "Cycle left/Misc"},
	{"R BUTTON", 100, 176, CT_GAMECONTROL, gc_weaponnext, nil, "Cycle right/Misc"},

	-- multiplayer?
	{"CHAT", 100, 200, CT_GAMECONTROL, gc_talkkey, nil, "Set game controls"},
	{"TEAM CHAT", 100, 212, CT_GAMECONTROL, gc_teamkey, nil, "Set game controls"},
	{"RANKINGS", 100, 224, CT_GAMECONTROL, gc_scores, nil, "Set game controls"},
	{"SWITCH VIEW", 100, 236, CT_GAMECONTROL, gc_viewpoint, nil, "Set game controls"},

	-- camera
	{"RESET CAM", 100, 260, CT_GAMECONTROL, gc_camreset, nil, "Set game controls"},

	-- META
	{"PAUSE", 100, 284, CT_GAMECONTROL, gc_pause, nil, "Set game controls"},
	{"SCREENSHOT", 100, 296, CT_GAMECONTROL, gc_screenshot, nil, "Also available by pressing F8"},
	{"RECORD GIF", 100, 308, CT_GAMECONTROL, gc_recordgif, nil, "Also available by pressing F9"},
	{"SYSTEM MENU", 100, 320, CT_GAMECONTROL, gc_systemmenu, nil, "Also available by pressing ESC"},
	{"CONSOLE", 100, 332, CT_GAMECONTROL, gc_console, nil, "Also available by pressing Tilde"},

	-- Lua?
	{"CUSTOM 1", 100, 356, CT_GAMECONTROL, gc_custom1, nil, "May be used by addons"},
	{"CUSTOM 2", 100, 368, CT_GAMECONTROL, gc_custom2, nil, "May be used by addons"},
	{"CUSTOM 3", 100, 380, CT_GAMECONTROL, gc_custom3, nil, "May be used by addons"},

	-- Opt
	{"MOUSE SETTINGS", 100, 404, CT_MENUSTATE, MS_MOUSEOPTIONS, nil, "Options relative to the Mouse"},
	{"CONTROLLER SETTINGS", 100, 416, CT_MENUSTATE, MS_CONTROLLEROPTIONS, nil, "Options relative to controller sticks and defaults."},
	{"ANALOG MODE", 100, 428, CT_CVAR, CV_FindVar("uconfiganalog"), nil, "If off, movement is in relation of the camera direction."},
}

local controller_opt = {
	{"Detect controller", 100, 32, CT_FUNCTION, mm_PickupController, nil, "Picks up your first plugged controller for use"},	--:wonderful:
	//{"Xbox defaults", 100, 44, CT_FUNCTION, mm_XboxDefaults, CS_GREYOUT, "For Xbox360/One controllers: sets suitable default controls"},

	{"Move axis A", 100, 68, CT_CVARNUM, {CV_FindVar("joyaxis_move"), -8, 8}, nil, "Axis for moving forward/backwards. Also used in battle menus"},
	{"Move axis B", 100, 80, CT_CVARNUM, {CV_FindVar("joyaxis_side"), -8, 8}, nil, "Axis for moving left/right. Also used in battle menus"},
	{"Camera Axis A", 100, 92, CT_CVARNUM, {CV_FindVar("joyaxis_look"), -8, 8}, nil, "Axis for looking up/down"},
	{"Camera Axis B", 100, 104, CT_CVARNUM, {CV_FindVar("joyaxis_turn"), -8, 8}, nil, "Axis for looking left/right"},
	{"Button A Axis", 100, 116, CT_CVARNUM, {CV_FindVar("joyaxis_jump"), -8, 8}, nil, "Axis to replace A button (Not recommended)"},
	{"Button B Axis", 100, 128, CT_CVARNUM, {CV_FindVar("joyaxis_spin"), -8, 8}, nil, "Axis to replace B button (Not recommended)"},

	{"FP V look", 100, 152, CT_CVAR, CV_FindVar("alwaysmlook"), nil, "Allows looking up/down in first person"},
	{"TP V look", 100, 164, CT_CVAR, CV_FindVar("chasemlook"), nil, "Allows looking up/down in third person (Not recommended)"}
}

local mouse_opt = {
	{"Use mouse", 100, 32, CT_CVAR, CV_FindVar("use_mouse"), nil, "Toggles mouse usage"},

	{"FP V look", 100, 56, CT_CVAR, CV_FindVar("alwaysmlook"), nil, "Allows looking up/down in first person"},
	{"TP V look", 100, 68, CT_CVAR, CV_FindVar("chasemlook"), nil, "Allows looking up/down in third person (Not recommended)"},

	{"Mouse Move", 100, 92, CT_CVAR, CV_FindVar("mousemove"), nil, "Mouse movement"},
	{"Invert Y axis", 100, 104, CT_CVAR, CV_FindVar("invertmouse"), nil, "Inverts the vertical mouse movement"},
	{"Mouse X sens", 100, 116, CT_CVARSLIDER, {CV_FindVar("mousesens"), 0, 100}, nil, "Mouse X sensitivity"},
	{"Mouse Y sens", 100, 128, CT_CVARSLIDER, {CV_FindVar("mouseysens"), 0, 100}, nil, "Mouse Y sensitivity"},
}

local display_opt = {
	{"Set Resolution", 100, 8, CT_FUNCTION, mm_setVidMode, nil, "Lft/Rgt to change resolution. Enter to set it"},
	{"Auto resolution", 100, 20, CT_CVAR, CV_FindVar("fullscreen"), nil, "Enables or disables auto resolution"},
	{"VSync", 100, 32, CT_CVAR, CV_FindVar("vid_wait"), nil, "Locks the framerate to your monitor's refresh rate"},

	-- for sliders: {CV_var, min, max}
	{"Brightness", 100, 58, CT_CVARSLIDER, {CV_FindVar("gamma"), -15, 5}, nil, "Change the brightness of the screen"},
	{"Saturation", 100, 70, CT_CVARSLIDER, {CV_FindVar("saturation"), 0, 10}, nil, "Change the colour saturation"},
	{"Colour Profile", 100, 82, CT_MENUSTATE, MS_COLOURPROFILES, nil, "In depth accessibility colour options"},

	{"Chat Options", 100, 106, CT_MENUSTATE, MS_CHATOPTIONS, nil, "Settings for chat display"},

	{"Show FPS", 100, 130, CT_CVARNUM, {CV_FindVar("showfps"), 0, 2}, nil, "Shows the framerate at the bottom right corner"},
	{"Show ping", 100, 142, CT_CVARNUM, {CV_FindVar("showping"), 0, 2}, nil, "Shows the ping at the bottom right corner in netgames"},
	{"Show commands", 100, 154, CT_CVAR, CV_FindVar("commandhelp"), nil, "Displays commands at the bottom right corner in-game"},

	{"Hardware Options", 100, 166, CT_MENUSTATE, MS_OPENGL, nil, "Change options for the hardware renderer"},
}

local opengl_opt = {

	{"Renderer", 100, 8, CT_CVARNUM, {CV_FindVar("renderer"), 1, 2}, nil, "Warning: OGL is incomplete and may have visual quirks"},

	{"3D models", 100, 44, CT_CVAR, CV_FindVar("gr_models"), nil, "Models are not supplied with the game (yet?)"},
	{"Model Interp", 100, 56, CT_CVARNUM, {CV_FindVar("gr_modelinterpolation"), 0, 2}, nil, "'Always' may have display issues depending on Model packs."},
	{"Model Lighting", 100, 68, CT_CVAR, CV_FindVar("gr_modellighting"), nil, "Enables ambient occlusion on models. 'Off' recommended."},

	{"GLSL shaders", 100, 92, CT_CVAR, CV_FindVar("gr_shaders"), nil, "Enables GLSL shaders"},
	{"Anisotropic Mode", 100, 104, CT_CVARNUM, {CV_FindVar("gr_filtermode"), 0, 5}, nil, "Set Anisotropic filter. 'Nearest' recommended"},
	--{"Anisotropic Level", 100, 116, CT_CVARNUM, {CV_FindVar("scr_depth"), 0, 16}, nil, "Set Anisotropic level."},
}

local colourprofiles_opt = {
	{"RED HUE", 100, 8, CT_CVARSLIDER, {CV_FindVar("rhue"), 0, 23}, nil, ""},
	{"RED GAMMA", 100, 20, CT_CVARSLIDER, {CV_FindVar("rgamma"), -15, 5}, nil, ""},
	{"RED SATURATION", 100, 32, CT_CVARSLIDER, {CV_FindVar("rsaturation"), 0, 10}, nil, ""},

	{"YLW HUE", 100, 56, CT_CVARSLIDER, {CV_FindVar("yhue"), 0, 23}, nil, ""},
	{"YLW GAMMA", 100, 68, CT_CVARSLIDER, {CV_FindVar("ygamma"), -15, 5}, nil, ""},
	{"YLW SATURATION", 100, 80, CT_CVARSLIDER, {CV_FindVar("ysaturation"), 0, 10}, nil, ""},

	{"GRN HUE", 100, 104, CT_CVARSLIDER, {CV_FindVar("ghue"), 0, 23}, nil, ""},
	{"GRN GAMMA", 100, 116, CT_CVARSLIDER, {CV_FindVar("ggamma"), -15, 5}, nil, ""},
	{"GRN SATURATION", 100, 128, CT_CVARSLIDER, {CV_FindVar("gsaturation"), 0, 10}, nil, ""},

	{"CYN HUE", 100, 152, CT_CVARSLIDER, {CV_FindVar("chue"), 0, 23}, nil, ""},
	{"CYN GAMMA", 100, 164, CT_CVARSLIDER, {CV_FindVar("cgamma"), -15, 5}, nil, ""},
	{"CYN SATURATION", 100, 176, CT_CVARSLIDER, {CV_FindVar("csaturation"), 0, 10}, nil, ""},

	{"BLU HUE", 100, 200, CT_CVARSLIDER, {CV_FindVar("bhue"), 0, 23}, nil, ""},
	{"BLU GAMMA", 100, 212, CT_CVARSLIDER, {CV_FindVar("bgamma"), -15, 5}, nil, ""},
	{"BLU SATURATION", 100, 224, CT_CVARSLIDER, {CV_FindVar("bsaturation"), 0, 10}, nil, ""},

	{"MGT HUE", 100, 248, CT_CVARSLIDER, {CV_FindVar("mhue"), 0, 23}, nil, ""},
	{"MGT GAMMA", 100, 260, CT_CVARSLIDER, {CV_FindVar("mgamma"), -15, 5}, nil, ""},
	{"MGT SATURATION", 100, 272, CT_CVARSLIDER, {CV_FindVar("msaturation"), 0, 10}, nil, ""},

	{"RESET ALL", 100, 296, CT_FUNCTION, mm_resetColourProfile, nil, ""},
}

local chatoptions_opt = {
	{"Chat Mode", 100, 32, CT_CVARNUM, {CV_FindVar("chatmode"), 0, 2}, nil, "Sets the mode for chat display"},

	{"Background colour", 100, 56, CT_CVARNUM, {CV_FindVar("con_backcolor"), 0, 18}, nil, "Background colour for the chat. Also affects the console."},
	{"Width", 100, 68, CT_CVARNUM, {CV_FindVar("chatwidth"), 64, 300}, nil, "Width of the chat box in pixels"},
	{"Height", 100, 80, CT_CVARNUM, {CV_FindVar("chatheight"), 6, 22}, nil, "Number of chat lines"},
	{"Background", 100, 92, CT_CVAR, CV_FindVar("chatbacktint"), nil, "Displays the console background while chat is minimized"},
	{"Fadeout time", 100, 104, CT_CVARNUM, {CV_FindVar("chattime"), 5, 999}, nil, "Time in seconds after which messages fade out"},

	{"Notifications", 100, 128, CT_CVAR, CV_FindVar("chatnotifications"), nil, "Plays a sound or not when a message is sent"},
	{"Spam Protection", 100, 140, CT_CVAR, CV_FindVar("chatspamprotection"), nil, "Deletes messages sent in rapid succession"},
}

local sound_opt = {
	{"Play Music", 100, 8, CT_CVAR, CV_FindVar("digimusic"), nil, "Enables or disables music"},
	{"Music Volume", 100, 20, CT_CVARSLIDER, {CV_FindVar("digmusicvolume"), 0, 31}, nil, "Set music volume"},

	{"Play Sounds", 100, 44, CT_CVAR, CV_FindVar("sounds"), nil, "Enables or disables sound effects"},
	{"Voice frequency", 100, 56, CT_CVARNUM, {cv_voices, 0, 2}, nil, "Set frequency of voice clips"},
	{"Sound Volume", 100, 68, CT_CVARSLIDER, {CV_FindVar("soundvolume"), 0, 31}, nil, "Set sound effect volume"},

	{"Closed Captions", 100, 88, CT_CVAR, CV_FindVar("closedcaptioning"), nil, "Displays closed captions for ease of accessibility"},
	{"Music while unfocused", 100, 100, CT_CVAR, CV_FindVar("playmusicifunfocused"), nil, "Music will keep playing even if the game is unfocused"},
	{"SFX while unfocused", 100, 112, CT_CVAR, CV_FindVar("playsoundsifunfocused"), nil, "Sound Effects will keep playing even if the game is unfocused"},

	{"Custom Battle Music", 100, 136, CT_MENUSTATE, MS_CUSTOMMUSIC, nil, "Set what musics you want to hear in battle"},

}

local net_opt = {
	{"Server Name", 100, 8, CT_CVARTEXT, CV_FindVar("servername"), nil, "Change the name of your server"},
	{"Max Players", 100, 38, CT_CVARNUM, {CV_FindVar("maxplayers"), 2, 16}, nil, "How many players can join your server"},
	{"Allow joining", 100, 50, CT_CVAR, CV_FindVar("allowjoin"), nil, "Allows players to join your game"},
	{"Allow file downloading", 100, 62, CT_CVAR, CV_FindVar("downloading"), nil, "Allows joining players to download files they're missing"},

	{"Gameplay Options", 100, 86, CT_MENUSTATE, MS_NETGAMEPLAYOPTIONS, nil, "Set various netplay gameplay options"},

	{"Resynch Attempts", 100, 110, CT_CVARNUM, {CV_FindVar("resynchattempts"), 1, 20}, nil, "Number of netgame resynch attempts before the player gets kicked"},
	{"Master Server Address", 100, 122, CT_CVARTEXT, CV_FindVar("masterserver"), nil, "(UNUSED): MS adress. Default is \'https://mb.srb2.org/MS/0\'"},
}

local netgameplay_opt = {

	{"Turn timer", 100, 32, CT_CVARNUM, {cv_turntimer, 0, 99}, nil, "Time in seconds for players to take their turn. Disabled if 0."},
	--{"Spawn Reaper", 100, 56, CT_CVAR, cv_reaper, nil, "Spawns the Reaper after a while in netgames"},
	--{"Reaper timer", 100, 68, CT_CVARNUM, {cv_reapertimer, 1, 30}, nil, "Reaper spawn timer (in minutes)"},
}

SYS_menus[SM_TITLE] = {

	openstate = MS_TITLE,
	openchoice = 1,

	[MS_TITLE] = {

		drawfunc =	mm_drawMainScreen,
		choices = 	{	-- dummy choice that sends us to the next menu
						{"Kanade best waifu <3", 0, 0, CT_MENUSTATE, MS_MAIN}	-- << factual
					},
	},

	[MS_MAIN] = {

		opentimer = TICRATE/4,
		drawfunc = SYS_drawGenericMenu,
		prev = MS_TITLE,
		runfunc = mm_checkTutorial,
		displayflags = V_SNAPTOBOTTOM|V_SNAPTOLEFT,
		choices = 	{
						{"1 Player", 64, 100, CT_MENUSTATE, MS_1PLAYER, nil, main_hints[1]},
						{"Quickplay", 64,112, CT_MENUSTATE, MS_QUICKPLAY, nil, main_hints[2]},
						{"Settings", 64, 124, CT_MENUSTATE, MS_SETTINGS, nil, main_hints[3]},
						{"Addons", 64, 136, CT_FUNCTION, SRB2P_openAddonsMenu, nil, main_hints[4]},
						{"Quit game", 64, 148, CT_PROMPT, {"Are you sure?", PT_YESNO, mm_quitSRB2}, nil, main_hints[5]},
					},

	},

	[MS_1PLAYER] = {

		opentimer = TICRATE/4,
		drawfunc = SYS_drawGenericMenu,
		prev = MS_MAIN,
		displayflags = V_SNAPTOBOTTOM|V_SNAPTOLEFT,
		choices = 	{
						{"Load Game", 64, 100, CT_PROMPT, {"There is no singleplayer story yet!\nBut you can experience the game\nin quickplay even by yourself!", PT_NOTIFICATION}, CS_FAKEGREYOUT, "Load a save file and resume your adventure"},	-- CT_MENUSTATE: MS_SAVES
						{"New Game", 64,112, CT_PROMPT, {"There is no singleplayer story yet!\nBut you can experience the game\nin quickplay even by yourself!", PT_NOTIFICATION}, CS_FAKEGREYOUT, "A new beginning!"},	-- CT_FUNCTION: mm_startNewGame
						{"Tutorial", 64, 124, CT_FUNCTION, mm_startTutorial, nil, "Recommended for people who have never played Persona"},
					},
	},

	[MS_QUICKPLAY] = {
		opentimer = TICRATE/4,
		drawfunc = SYS_drawGenericMenu,
		prev = MS_MAIN,
		displayflags = V_SNAPTOBOTTOM|V_SNAPTOLEFT,
		choices = 	{
						{"Host game", 64, 116, CT_FUNCTION, mm_hostNetGame, nil, "Set up a game your friends can join"},
						{"Join game", 64, 128, CT_TEXTFUNCTION, mm_joinNetGame, nil, "Join friends via IP"},
						{"Setup Player", 64, 155, CT_MENUSTATE, MS_SETUPPLAYER, nil, "Setup your player for online games"},
					},
	},

	[MS_SETUPPLAYER] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawPlayerSetup,
		runfunc = mm_handlePlayerSetup,
		prev = MS_QUICKPLAY,
		displayflags = 0,
		choices = 	{
						{"Name", 100, 32, CT_CVARTEXT, CV_FindVar("name"), nil, "Your name for netgame sessions"},
						{"Character", 100, 60, nil, nil, nil, "Character to use by default in netgames"},	-- we'll use a hack for skin selection.
						{"Colour", 100, 128, CT_CVARNUM, {CV_FindVar("color"), 1, MAXSKINCOLORS-1}, nil, "Character colour to use in netgames"},

						{"Save as default", 100, 160, CT_FUNCTION, mm_saveDefaultSkin, nil, "Save your character as default"},
					},


	},

	[MS_SETTINGS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawSettings,
		displayflags = 0,
		prev = MS_MAIN,

		choices = settings_opt,
	},


	[MS_SETCONTROLS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = control_opt,
	},

	[MS_CONTROLLEROPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETCONTROLS,

		choices = controller_opt,
	},

	[MS_MOUSEOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETCONTROLS,

		choices = mouse_opt,

	},


	[MS_DISPLAYOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawVideoSettings,
		runfunc = mm_handleVideoSettings,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = display_opt,

	},

	[MS_OPENGL] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawOpenGLOptions,
		displayflags = 0,
		prev = MS_DISPLAYOPTIONS,
		choices = opengl_opt,
	},

	[MS_COLOURPROFILES] = {
		opentimer = TICRATE/4,
		drawfunc = mm_colourProfile,
		displayflags = 0,
		prev = MS_DISPLAYOPTIONS,

		choices = colourprofiles_opt,

	},

	[MS_CHATOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_DISPLAYOPTIONS,

		choices = chatoptions_opt,
	},


	[MS_SOUNDOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = sound_opt,
	},

	[MS_NETOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = net_opt,

	},

	[MS_NETGAMEPLAYOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_NETOPTIONS,

		choices = netgameplay_opt,
	},

	[MS_CUSTOMMUSIC] = {
		opentimer = TICRATE/4,
		drawfunc = mm_customMusic,
		runfunc = mm_handlecustomMusic,
		displayflags = 0,
		prev = MS_SOUNDOPTIONS,	-- close

		choices = 	{
						{"Tracks", 100, 32, CT_CVARNUM, {cv_musicedit, 0, 5}, nil, "Select which music tables to edit"},
						{"", 100, 48, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 58, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 68, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 78, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 88, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 98, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 108, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 118, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 128, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 138, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
					},
	},

	[MS_CHANGEMUSIC] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawChangeMusic,
		displayflags = 0,
		prev = MS_CUSTOMMUSIC,	-- close

		choices = cache_musics,
	},

	[MS_DEBUG] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = 	{
						{"Debug prints", 100, 32, CT_CVAR, cv_debugprints, nil, "Display debug prints during gameplay."},
						{"Debug cheats", 100, 44, CT_CVAR, cv_debugcheats, nil, "Enable d_ cheat commands for debugging."},
						--{"View Skills List", 100, 56, CT_MENUSTATE, MS_SKILLIST, nil, "Display all the skills available in-game."},
						--{"View Personas List", 100, 68, CT_MENUSTATE, MS_PERSONALIST, nil, "Compute the skills of any Persona at a given level."},
					},
	},

	[MS_SKILLIST] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawSkilllist,
		displayflags = 0,
		prev = MS_DEBUG,

		choices = dbg_skillist,
	},

	[MS_PERSONALIST] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawPersonalist,
		runfunc = mm_dummyPersona,
		displayflags = 0,
		prev = MS_DEBUG,

		choices = 	{
						{"Select Persona", 100, 32, CT_CVARNUM, {cv_personatest, 1, #sorted_personaList}, nil, "Select which Persona to preview."},
						{"Select Level", 100, 44, CT_CVARNUM, {cv_leveltest, 10, 99}, nil, "Select which level to preview skills at"},
						{"Play attack anim", 100, 56, CT_FUNCTION, mm_personaAttackAnim, nil, "Preview the Persona's attack animation."},
					},
	},

}



SYS_menus[SM_PAUSE] = {

	openstate = MS_MAIN,
	openchoice = 1,
	opentimer = TICRATE/4,

	[MS_MAIN] = {
		opentimer = TICRATE/4,
		drawfunc = pm_pauseMain,
		displayflags = 0,
		runfunc = mp_checkMPPause,
		prev = -1,	-- close

		choices = 	{
						{"Continue", 160, 64, CT_FUNCTION, mp_closePauseMenu, nil, "Resume game"},

						{"Player setup", 160, 88, CT_MENUSTATE, MS_SETUPPLAYER, nil, "Change your name or colour"},
						{"Settings", 160, 100, CT_MENUSTATE, MS_SETTINGS, nil, "Change game settings"},

						{"Return to lobby", 160, 124, CT_PROMPT, {"Are you sure?\nAll progress will be lost.", PT_YESNO, mp_returnToLobby}, nil, "Return to the Tartarus entrance"},
						{"Return to title", 160, 136, CT_PROMPT, {"Are you sure?\nThis will end the netgame\nand drop all players.", PT_YESNO, mp_quitNetGame}, nil, "Exit the netgame and return to the title screen"},
						{"Quit game", 160, 148, CT_PROMPT, {"Are you sure?", PT_YESNO, mm_quitSRB2}, nil, "Quit the game"},
					}
	},

	[MS_SETTINGS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawSettings,
		displayflags = 0,
		prev = MS_MAIN,

		choices = settings_opt,
	},

	[MS_SETCONTROLS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = control_opt,
	},

	[MS_CONTROLLEROPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETCONTROLS,

		choices = controller_opt,
	},

	[MS_MOUSEOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETCONTROLS,

		choices = mouse_opt,

	},


	[MS_DISPLAYOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawVideoSettings,
		runfunc = mm_handleVideoSettings,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = display_opt,

	},

	[MS_COLOURPROFILES] = {
		opentimer = TICRATE/4,
		drawfunc = mm_colourProfile,
		displayflags = 0,
		prev = MS_DISPLAYOPTIONS,

		choices = colourprofiles_opt,

	},

	[MS_CHATOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_DISPLAYOPTIONS,

		choices = chatoptions_opt,
	},


	[MS_SOUNDOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = sound_opt,
	},

	[MS_NETOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = net_opt,

	},

	[MS_NETGAMEPLAYOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_NETOPTIONS,

		choices = netgameplay_opt,
	},

	[MS_SETUPPLAYER] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawPlayerSetup,
		runfunc = mm_handlePlayerSetup,
		prev = MS_MAIN,
		displayflags = 0,
		choices = 	{
						{"Name", 100, 32, CT_CVARTEXT, CV_FindVar("name"), nil, "Your name for netgame sessions"},
						{"Character", 100, 60, nil, nil, CS_GREYOUT, "Character to use by default in netgames"},	-- we'll use a hack for skin selection.
						{"Colour", 100, 128, CT_CVARNUM, {CV_FindVar("color"), 1, MAXSKINCOLORS-1}, nil, "Character colour to use in netgames"},

						{"Save as default", 100, 160, CT_FUNCTION, mm_saveDefaultSkin, CS_GREYOUT, "Save your character as default"},
					},
	},

	[MS_CUSTOMMUSIC] = {
		opentimer = TICRATE/4,
		drawfunc = mm_customMusic,
		runfunc = mm_handlecustomMusic,
		displayflags = 0,
		prev = MS_SOUNDOPTIONS,	-- close

		choices = 	{
						{"Tracks", 100, 32, CT_CVARNUM, {cv_musicedit, 0, 5}, nil, "Select which music tables to edit"},
						{"", 100, 48, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 58, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 68, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 78, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 88, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 98, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 108, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 118, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 128, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 138, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
					},
	},

	[MS_CHANGEMUSIC] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawChangeMusic,
		displayflags = 0,
		prev = MS_CUSTOMMUSIC,	-- close

		choices = cache_musics,
	},

	[MS_DEBUG] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = 	{
						{"Debug prints", 100, 32, CT_CVAR, cv_debugprints, nil, "Display debug prints during gameplay."},
						{"Debug cheats", 100, 44, CT_CVAR, cv_debugcheats, nil, "Enable d_ cheat commands for debugging."},
						--{"View Skills List", 100, 56, CT_MENUSTATE, MS_SKILLIST, nil, "Display all the skills available in-game."},
						--{"View Personas List", 100, 68, CT_MENUSTATE, MS_PERSONALIST, nil, "Compute the skills of any Persona at a given level."},
					},
	},

	[MS_SKILLIST] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = dbg_skills,
	},

}

SYS_menus[SM_PAUSE_SP] = {

	openstate = MS_MAIN,
	openchoice = 1,
	opentimer = TICRATE/4,

	[MS_MAIN] = {
		opentimer = TICRATE/4,
		drawfunc = pm_pauseMain,
		displayflags = 0,
		prev = -1,	-- close

		choices = 	{
						{"Continue", 160, 76, CT_FUNCTION, mp_closePauseMenu, nil, "Resume game"},
						{"Settings", 160, 88, CT_MENUSTATE, MS_SETTINGS, nil, "Change game settings"},

						{"Return to title", 160, 100, CT_PROMPT, {"Are you sure?\nAny unsaved progress\nwill be lost.", PT_YESNO, mp_quitNetGame}, nil, "Exit the netgame and return to the title screen"},
						{"Quit game", 160, 112, CT_PROMPT, {"Are you sure?\nAny unsaved progress\nwill be lost.", PT_YESNO, mm_quitSRB2}, nil, "Quit the game"},
					}
	},

	[MS_SETTINGS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawSettings,
		displayflags = 0,
		prev = MS_MAIN,

		choices = settings_opt,
	},

	[MS_SETCONTROLS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = control_opt,
	},

	[MS_CONTROLLEROPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETCONTROLS,

		choices = controller_opt,
	},

	[MS_MOUSEOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETCONTROLS,

		choices = mouse_opt,

	},


	[MS_DISPLAYOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawVideoSettings,
		runfunc = mm_handleVideoSettings,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = display_opt,

	},

	[MS_COLOURPROFILES] = {
		opentimer = TICRATE/4,
		drawfunc = mm_colourProfile,
		displayflags = 0,
		prev = MS_DISPLAYOPTIONS,

		choices = colourprofiles_opt,

	},

	[MS_CHATOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_DISPLAYOPTIONS,

		choices = chatoptions_opt,
	},


	[MS_SOUNDOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = sound_opt,
	},

	[MS_NETOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = net_opt,

	},

	[MS_NETGAMEPLAYOPTIONS] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_NETOPTIONS,

		choices = netgameplay_opt,
	},

	[MS_SETUPPLAYER] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawPlayerSetup,
		runfunc = mm_handlePlayerSetup,
		prev = MS_MAIN,
		displayflags = 0,
		choices = 	{
						{"Name", 100, 32, CT_CVARTEXT, CV_FindVar("name"), nil, "Your name for netgame sessions"},
						{"Character", 100, 60, nil, nil, CS_GREYOUT, "Character to use by default in netgames"},	-- we'll use a hack for skin selection.
						{"Colour", 100, 128, CT_CVARNUM, {CV_FindVar("color"), 1, MAXSKINCOLORS-1}, nil, "Character colour to use in netgames"},

						{"Save as default", 100, 160, CT_FUNCTION, mm_saveDefaultSkin, CS_GREYOUT, "Save your character as default"},
					},
	},

	[MS_CUSTOMMUSIC] = {
		opentimer = TICRATE/4,
		drawfunc = mm_customMusic,
		runfunc = mm_handlecustomMusic,
		displayflags = 0,
		prev = MS_SOUNDOPTIONS,	-- close

		choices = 	{
						{"Tracks", 100, 32, CT_CVARNUM, {cv_musicedit, 0, 5}, nil, "Select which music tables to edit"},
						{"", 100, 48, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 58, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 68, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 78, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 88, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 98, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 108, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 118, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 128, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
						{"", 100, 138, CT_MENUSTATE, MS_CHANGEMUSIC, nil, "Set music, press Escape to remove that entry."},
					},
	},

	[MS_CHANGEMUSIC] = {
		opentimer = TICRATE/4,
		drawfunc = mm_drawChangeMusic,
		displayflags = 0,
		prev = MS_CUSTOMMUSIC,	-- close

		choices = cache_musics,
	},

	[MS_DEBUG] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = 	{
						{"Debug prints", 100, 32, CT_CVAR, cv_debugprints, nil, "Display debug prints during gameplay."},
						{"Debug cheats", 100, 44, CT_CVAR, cv_debugcheats, nil, "Enable d_ cheat commands for debugging."},
						--{"View Skills List", 100, 56, CT_MENUSTATE, MS_SKILLIST, nil, "Display all the skills available in-game."},
						--{"View Personas List", 100, 68, CT_MENUSTATE, MS_PERSONALIST, nil, "Compute the skills of any Persona at a given level."},
					},
	},

	[MS_SKILLIST] = {
		opentimer = TICRATE/4,
		drawfunc = mm_genericOptions,
		displayflags = 0,
		prev = MS_SETTINGS,

		choices = dbg_skills,
	},

}

end)