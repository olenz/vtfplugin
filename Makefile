# Location of the VMD include files vmdplugin.h and molfile_plugin.h.
# Typically, these files can be found in the subdir 
# plugins/include of the VMD installation directory.

# lancre:
#VMDDIR=/home/olenz/software/lib/vmd
#CPPFLAGS=-I$(VMDINCLUDES) -I/usr/include/tcl8.5

# ICP:
VMDDIR=/usr/local/lib/vmd
CPPFLAGS=-I$(VMDINCLUDES)

VMDINCLUDES=$(VMDDIR)/plugins/include
# comment this line, if zlib is not available
_USE_TCL=1
_USE_ZLIB=1
DEBUG=1

CC=gcc
CFLAGS=-Wall -fPIC -pedantic
SHLD=$(CC)
SHLDFLAGS=-shared $(LDFLAGS)

# if you use MAX OS X, use the following
#CFLAGS=-Os -fPIC -dynamic
#SHLD=$(CC)
#SHLDFLAGS=-bundle $(LDFLAGS)

ifdef _USE_TCL
CFLAGS += -D _USE_TCL
LDFLAGS=-ltcl8.5
endif

ifdef _USE_ZLIB
# if you want to enable compressed files, use these
CFLAGS += -D_USE_ZLIB
LDFLAGS += -lz
endif

ifdef DEBUG
CFLAGS += -g -O0 -DDEBUG
else
CFLAGS += -O3
endif

all: vtftest vtfplugin.so 

vtftest: vtfplugin.o
vtfplugin.so: vtfplugin.o Makefile
	$(SHLD) $(SHLDFLAGS) $< -o vtfplugin.so

clean:
	-rm vtfplugin.o vtfplugin.so vtftest
