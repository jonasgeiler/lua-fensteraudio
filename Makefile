#
# !IMPORTANT!
# I created this file for CLion and it works on my machine, but you should rather use `luarocks make` to build the library.
# I really don't have any experience with Makefiles, so I can't guarantee that it will work on your machine.
#

all: fenster_audio.so

LD ?= gcc
LDFLAGS ?= -shared
ALSA_LIBDIR ?= /usr/lib64
fenster_audio.so: src/main.o
	$(LD) $(LDFLAGS) $(LIBFLAG) -o $@ $< -L$(ALSA_LIBDIR) -lasound

CC ?= gcc
CFLAGS ?= -O2 -fPIC
LUA_INCDIR ?= /usr/include
ALSA_INCDIR ?= /usr/include
src/main.o: src/main.c
	$(CC) $(CFLAGS) -I$(LUA_INCDIR) -c $< -o $@ -I$(ALSA_INCDIR)

clean:
	rm -f src/main.o fenster_audio.so