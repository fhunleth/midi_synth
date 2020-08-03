# Makefile for building the midi_synth port process
#
# Makefile targets:
#
# all           build and install
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_APP_PATH  path to the build directory
# CC            C compiler. MUST be set if crosscompiling
# CFLAGS	compiler flags for compiling all C files
# LDFLAGS	linker flags for linking all binaries

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj

LDFLAGS +=
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c99 -D_GNU_SOURCE

# Windows-specific updates
ifeq ($(OS),Windows_NT)
# TBD
EXEEXT=.exe
else
# Non-Windows
LDFLAGS += -lfluidsynth
endif

SOUND_FONT_FILE = FluidR3_GM.sf2
MIDI_SYNTH = $(PREFIX)/midi_synth$(EXEEXT)
SOUND_FONT = $(PREFIX)/$(SOUND_FONT_FILE)
SOUND_FONT_SRC = $(SOUND_FONT_FILE)

SRC = $(wildcard *.c)
OBJ = $(SRC:%.c=$(BUILD)/%.o)

calling_from_make:
	cd .. && mix compile

all: $(PREFIX) $(BUILD) $(MIDI_SYNTH) $(SOUND_FONT)

$(OBJ): Makefile

$(BUILD)/%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(MIDI_SYNTH): $(OBJ)
	$(CC) $^ $(LDFLAGS) -o $@

$(PREFIX) $(BUILD):
	mkdir -p $@

$(SOUND_FONT_SRC):
	curl -LO https://github.com/fhunleth/midi_synth/releases/download/v0.1.0/$(SOUND_FONT_FILE)

$(SOUND_FONT): $(SOUND_FONT_SRC)
	cp $^ $@

clean:
	$(RM) $(MIDI_SYNTH) $(BUILD)/*.o $(SOUND_FONT)

.PHONY: calling_from_make all clean
