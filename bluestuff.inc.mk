BLUESTUFFDIR ?= $(CURDIR)/BlueStuff
BLUEAVALONDIR = $(BLUESTUFFDIR)/BlueAvalon
include $(BLUEAVALONDIR)/blueavalon.inc.mk
BLUEAXI4DIR = $(BLUESTUFFDIR)/BlueAXI4
include $(BLUEAXI4DIR)/blueaxi4.inc.mk
BLUEBASICSDIR = $(BLUESTUFFDIR)/BlueBasics
BLUEUTILSDIR = $(BLUESTUFFDIR)/BlueUtils
RECIPEDIR = $(BLUESTUFFDIR)/Recipe
BLUESTUFF_DIRS = $(BLUESTUFFDIR):$(BLUEAVALON_DIRS):$(BLUEAXI4_DIRS):$(BLUEBASICSDIR):$(BLUEUTILSDIR):$(RECIPEDIR):$(BLUESTUFFDIR)/Stratix10ChipID
