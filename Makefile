.DEFAULT_GOAL := all

NAME		=  srb2switch22
SUFFIX		= 
PKGCONFIG	=  pkg-config
DEBUG		?= 0
STATIC		?= 1
VERBOSE		?= 0
PROFILE		?= 0
STRIP		?= strip
DEFINES		?= -DHAVE_SDL -DHAVE_THREADS -DHAVE_MIXER -DHAVE_ZLIB -DHAVE_CURL -DLOGMESSAGES

CFLAGS		?= -std=c++17

# =============================================================================
# Detect default platform if not explicitly specified
# =============================================================================

ifeq ($(OS),Windows_NT)
	PLATFORM ?= Windows
else
	UNAME_S := $(shell uname -s)

	ifeq ($(UNAME_S),Linux)
		PLATFORM ?= Linux
	endif

	ifeq ($(UNAME_S),Darwin)
		PLATFORM ?= macOS
	endif

endif

ifdef EMSCRIPTEN
	PLATFORM = Emscripten
endif

PLATFORM ?= Unknown

# =============================================================================

OUTDIR = bin/$(PLATFORM)
OBJDIR = obj/$(PLATFORM)

include Makefile_cfgs/Platforms/$(PLATFORM).cfg

# =============================================================================

ifeq ($(STATIC),1)
	PKGCONFIG +=  --static
endif

ifeq ($(DEBUG),1)
	CFLAGS += -g
	STRIP = :
else
	CFLAGS += -O3
endif

ifeq ($(PROFILE),1)
	CFLAGS += -pg -g -fno-inline-functions -fno-inline-functions-called-once -fno-optimize-sibling-calls -fno-default-inline
endif

ifeq ($(VERBOSE),0)
	CC := @$(CC)
	CXX := @$(CXX)
endif

# =============================================================================

CFLAGS += `$(PKGCONFIG) --cflags sdl2 ogg vorbis theora vorbisfile theoradec SDL2_mixer zlib`
LIBS   += `$(PKGCONFIG) --libs-only-l --libs-only-L sdl2 ogg vorbis theora vorbisfile theoradec SDL2_mixer zlib`

ifeq ($(STATIC),1)
	CFLAGS += -static
endif

INCLUDES  += \
    -I./src

INCLUDES += $(LIBS)

# Main Sources
SOURCES = \
	src/sdl/i_net \
	src/sdl/i_system \
	src/sdl/i_main \
	src/sdl/i_video \
	src/sdl/dosstr \
	src/sdl/endtxt \
	src/sdl/hwsym_sdl \
	src/sdl/mixer_sound \
	src/sdl/i_threads \
	src/md5 \
	src/apng \
	src/string \
	src/d_main \
	src/d_clisrv \
	src/d_net \
	src/d_netfil \
	src/d_netcmd \
	src/dehacked \
	src/deh_soc \
	src/deh_lua \
	src/deh_tables \
	src/z_zone \
	src/f_finale \
	src/f_wipe \
	src/g_demo \
	src/g_game \
	src/g_input \
	src/am_map \
	src/command \
	src/console \
	src/hu_stuff \
	src/y_inter \
	src/st_stuff \
	src/m_aatree \
	src/m_anigif \
	src/m_argv \
	src/m_bbox \
	src/m_cheat \
	src/m_cond \
	src/m_easing \
	src/m_fixed \
	src/m_menu \
	src/m_misc \
	src/m_perfstats \
	src/m_random \
	src/m_queue \
	src/info \
	src/p_ceilng \
	src/p_enemy \
	src/p_floor \
	src/p_inter \
	src/p_lights \
	src/p_map \
	src/p_maputl \
	src/p_mobj \
	src/p_polyobj \
	src/p_saveg \
	src/p_setup \
	src/p_sight \
	src/p_spec \
	src/p_telept \
	src/p_tick \
	src/p_user \
	src/p_slopes \
	src/tables \
	src/r_bsp \
	src/r_data \
	src/r_draw \
	src/r_main \
	src/r_plane \
	src/r_segs \
	src/r_skins \
	src/r_sky \
	src/r_splats \
	src/r_things \
	src/r_textures \
	src/r_patch \
	src/r_patchrotation \
	src/r_picformats \
	src/r_portal \
	src/screen \
	src/taglist \
	src/v_video \
	src/s_sound \
	src/sounds \
	src/w_wad \
	src/filesrch \
	src/mserv \
	src/http-mserv \
	src/i_tcp \
	src/lzf \
	src/b_bot \
	src/lua_script \
	src/lua_baselib \
	src/lua_mathlib \
	src/lua_hooklib \
	src/lua_consolelib \
	src/lua_infolib \
	src/lua_mobjlib \
	src/lua_playerlib \
	src/lua_skinlib \
	src/lua_thinkerlib \
	src/lua_maplib \
	src/lua_taglib \
	src/lua_polyobjlib \
	src/lua_blockmaplib \
	src/lua_hudlib \
	src/lua_inputlib \
	src/blua/lapi \
	src/blua/lbaselib \
	src/blua/ldo \
	src/blua/lfunc \
	src/blua/linit \
	src/blua/liolib \
	src/blua/llex \
	src/blua/lmem \
	src/blua/lobject \
	src/blua/lstate \
	src/blua/lstrlib \
	src/blua/ltablib \
	src/blua/lundump \
	src/blua/lzio \
	src/blua/lauxlib \
	src/blua/lcode \
	src/blua/ldebug \
	src/blua/ldump \
	src/blua/lgc \
	src/blua/lopcodes \
	src/blua/lparser \
	src/blua/lstring \
	src/blua/ltable \
	src/blua/ltm \
	src/blua/lvm \
	src/comptime \
	src/switch/swkbd


PKGSUFFIX ?= $(SUFFIX)

BINPATH = $(OUTDIR)/$(NAME)$(SUFFIX)
PKGPATH = $(OUTDIR)/$(NAME)$(PKGSUFFIX)

OBJECTS += $(addprefix $(OBJDIR)/, $(addsuffix .o, $(SOURCES)))

$(shell mkdir -p $(OUTDIR))
$(shell mkdir -p $(OBJDIR))

$(OBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	@echo -n Compiling $<...
	$(CC) -c $(CFLAGS) $(INCLUDES) $(DEFINES) $< -o $@
	@echo " Done!"

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(@D)
	@echo -n Compiling $<...
	$(CXX) -c $(CFLAGS) $(INCLUDES) $(DEFINES) $< -o $@
	@echo " Done!"

$(BINPATH): $(OBJDIR) $(OBJECTS)
	@echo -n Linking...
	$(CXX) $(CFLAGS) $(LDFLAGS) $(OBJECTS) -o $@ $(LIBS)
	@echo " Done!"
	$(STRIP) $@

ifeq ($(BINPATH),$(PKGPATH))
all: $(BINPATH)
else
all: $(PKGPATH)
endif

clean:
	rm -rf $(OBJDIR)