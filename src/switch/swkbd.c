// Borrowed from https://github.com/joel16/NX-Shell/ (/source/keyboard.c)

#include "swkbd.h"
#include <switch/applets/swkbd.h>

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