# Location of the VMD include files vmdplugin.h and molfile_plugin.h.
# Typically, these files can be found in the subdir 
# plugins/include of the VMD installation directory.

#qwghlm:
#VMDDIR=/usr/local/lib/vmd

#MPIP:
VMDDIR=/usr/people/lenzo/software/lib/vmd

VMDINCLUDES=$(VMDDIR)/plugins/include
# comment this line, if zlib is not available
_USE_ZLIB=1

CPPFLAGS=-I$(VMDINCLUDES)

CC=gcc
CFLAGS=-Wall -g -O0 -fPIC -pedantic
LDFLAGS=-ltcl8.4
SHLD=$(CC)
SHLDFLAGS=-shared $(LDFLAGS)

# if you use MAX OS X, use the following
#CFLAGS=-Os -fPIC -dynamic
#SHLD=$(CC)
#SHLDFLAGS=-bundle $(LDFLAGS)

ifdef _USE_ZLIB
# if you want to enable compressed files, use these
CFLAGS += -D_USE_ZLIB
LDFLAGS += -lz
endif

all: vtftest vtfplugin.so

vtftest: vtfplugin.o
vtfplugin.so: vtfplugin.o
	$(SHLD) $(SHLDFLAGS) $< -o vtfplugin.so

clean:
	-rm vtfplugin.o vtfplugin.so vtftest
