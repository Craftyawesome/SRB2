// Borrowed from https://github.com/joel16/NX-Shell/ (/source/keyboard.c)

#include <string>

extern "C" {

#include "swkbd.h"
#include <switch/applets/swkbd.h>
#include "../blua/lua.h"

SwkbdInline switch_kbdinline;
SwkbdAppearArg switch_appearArg;
Result switch_kdbresult;
SwkbdState switch_kbdstate;

void Switch_Keyboard_Deinit() {
    swkbdInlineClose(&switch_kbdinline);
}

void Switch_Keyboard_Init() {
	Result rc=0;
	rc = swkbdInlineCreate(&switch_kbdinline);
	// Launch the applet.

	// switch_kbdinline.calcArg.initArg.mode = SwkbdInlineMode_AppletDisplay;

	if (R_SUCCEEDED(rc))
		rc = swkbdInlineLaunchForLibraryApplet(&switch_kbdinline, SwkbdInlineMode_AppletDisplay, 0);

	swkbdInlineMakeAppearArg(&switch_appearArg, SwkbdType_Normal);
	// You can optionally set switch_appearArg text / fields here.
	swkbdInlineAppearArgSetOkButtonText(&switch_appearArg, "Submit");
	switch_appearArg.dicFlag = 0;
	switch_appearArg.returnButtonFlag = 0;

	swkbdInlineSetKeytopBgAlpha(&switch_kbdinline, 0.75); // Make it transparent
}

void Switch_Keyboard_Update() {
	switch_kdbresult = swkbdInlineUpdate(&switch_kbdinline, &switch_kbdstate); // Handles updating SwkbdInline state, this should be called periodically.
	if (R_FAILED(switch_kdbresult)) // Swkbd applet sometimes gets closed when multitasking
		Switch_Keyboard_Init(); 
}

void Switch_Keyboard_Open() {
	swkbdInlineSetAlphaEnabledInInputMode(&switch_kbdinline, false);
	swkbdInlineAppear(&switch_kbdinline, &switch_appearArg);
}

void Switch_Keyboard_Close() {
	swkbdInlineDisappear(&switch_kbdinline);
}

std::string GetText(const std::string &guide_text, const std::string &initial_text) {
	Result ret = 0;
	SwkbdConfig swkbd;
	static char input_string[256];
	
	if (R_FAILED(ret = swkbdCreate(std::addressof(swkbd), 0))) {
		swkbdClose(std::addressof(swkbd));
		return std::string();
	}
	
	swkbdConfigMakePresetDefault(std::addressof(swkbd));
	if (!guide_text.empty())
		swkbdConfigSetGuideText(std::addressof(swkbd), guide_text.c_str());
		
	if (!initial_text.empty())
		swkbdConfigSetInitialText(std::addressof(swkbd), initial_text.c_str());
		
	//swkbdConfigSetTextCheckCallback(std::addressof(swkbd), Keyboard::ValidateText);
	if (R_FAILED(ret = swkbdShow(std::addressof(swkbd), input_string, sizeof(input_string)))) {
		swkbdClose(std::addressof(swkbd));
		return std::string();
	}
	
	swkbdClose(std::addressof(swkbd));
	return input_string;
}

int LUA_GetText(lua_State *L) {
    const char *guide_text = lua_tostring(L, 1);
    const char *initial_text = lua_tostring(L, 2);

    std::string result = GetText(guide_text, initial_text);

    lua_pushstring(L, result.c_str());

    return 1;
}

}