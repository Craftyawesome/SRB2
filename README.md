# Sonic Robo Blast 2
[![latest release](https://badgen.net/github/release/STJr/SRB2/stable)](https://github.com/STJr/SRB2/releases/latest)

[![Nintendo Switch](https://github.com/heyjoeway/SRB2/actions/workflows/switch.yml/badge.svg)](https://github.com/heyjoeway/SRB2/actions/workflows/switch.yml)

[Sonic Robo Blast 2](https://srb2.org/) is a 3D Sonic the Hedgehog fangame based on a modified version of [Doom Legacy](http://doomlegacy.sourceforge.net/).


This fork aims to support the Nintendo Switch.

## Installation Instructions
You can find downloads in [releases](https://github.com/heyjoeway/SRB2/releases).

1. Make sure your Switch can run homebrew.
2. Extract the contents of the zip to the root of your SD card.
3. Start SRB2 via hbmenu (or whatever method you prefer).

NOTE: This game requires full RAM access. This means you can't launch hbmenu from the album applet when running this. With the latest Atmosphere build and its default config, you can hold R while starting any game to open hbmenu with full RAM access.

## Update Instructions
Extract the contents of the update patch to the root of your SD card. Overwrite any files that might conflict.

## Features
- Full online support
- Full mouse/keyboard support
- Full software keyboard support

## Notes
- The game takes a bit to boot. A faster SD card or higher CPU clock may help with this.
- The game defaults to software renderer. Consider changing to OpenGL. Performance is similar at low resolutions and better at high resolutions.
- The automatic resolution option runs at 800x450 on software, 1280x720 OpenGL handheld, 1920x1080 OpenGL docked. This can be disabled.
- The game is CPU bottlenecked even on OpenGL. Models are an additional small performance loss.
- The game continues to run while on the Switch's home screen when you are unable to pause to prevent lag-switching.
- If you want to play the game with mouse/keyboard, you'll have to bind most of the buttons yourself.
- All button bindings are set "correctly" out-of-the-box. You might want to tweak them to your liking though.

## Compilation

### Dependencies
- NASM (x86 builds only)
- SDL2 (Linux/OS X only)
- SDL2-Mixer (Linux/OS X only)
- libupnp (Linux/OS X only)
- libgme (Linux/OS X only)
- libopenmpt (Linux/OS X only)

### Compiling

See [SRB2 Wiki/Source code compiling](http://wiki.srb2.org/wiki/Source_code_compiling)

### Switch

Follow the instructions [here](http://wiki.srb2.org/wiki/Source_code_compiling/Makefiles), using the following make command:
```
make PLATFORM=Switch
```
Or, if you want to enable network debugging:
```
make PLATFORM=Switch NXLINK=1
```
If you plan on switching flags, make sure to run `make PLATFORM=Switch clean` first.

More complete build instructions coming soon(TM).

## Disclaimer
Sonic Team Junior is in no way affiliated with SEGA or Sonic Team. We do not claim ownership of any of SEGA's intellectual property used in SRB2.

I (heyjoeway), STJr, or the SRB2MB are in no way responsible if this port somehow manages to break your Switch.
