# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# LDFLAGS	linker flags for linking all binaries

LDFLAGS +=
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c99 -D_GNU_SOURCE
CC ?= $(CROSSCOMPILER)gcc

SRC=$(wildcard src/*.c)

# Windows-specific updates
ifeq ($(OS),Windows_NT)

# TBD

EXEEXT=.exe

else
# Non-Windows

LDFLAGS += -lfluidsynth

endif

OBJ=$(SRC:.c=.o)

.PHONY: all clean

all: priv priv/midi_synth$(EXEEXT)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

priv:
	mkdir -p priv

priv/midi_synth$(EXEEXT): $(OBJ)
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	rm -f priv/midi_synth$(EXEEXT) src/*.o
