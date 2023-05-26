#ifndef _SWITCH_SWKBD
#define _SWITCH_SWKBD

#include <switch/applets/swkbd.h>

extern SwkbdInline switch_kbdinline;
extern SwkbdAppearArg switch_appearArg;
extern Result switch_kdbresult;
extern SwkbdState switch_kbdstate;

void Switch_Keyboard_Deinit();
void Switch_Keyboard_Init();
void Switch_Keyboard_Update();
void Switch_Keyboard_Open();
void Switch_Keyboard_Close();

#endif