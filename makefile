################################################################################
# template makefile for driving Intel Quartus Prime
################################################################################

# suggestion:
# 1. Add quartus-mk to your repo as a submodule.
# 2. Copy this makefile to your build directory (this is where the Quartus
#    project will be created) and edit it to add your sources etc.
# 3. Use the following definitions:

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
QUARTUS_MK=$(SUBMODULES)/quartus-mk

################################################################################

# primary target
all: sof

################################################################################

# FPGA part number
QUARTUS_PART=part_number

# top entity name
QUARTUS_TOP=top

# synthesis optimization (area|speed|balanced)
QUARTUS_MAP_OPTIMIZE=speed

# fitter effort (standard|fast|auto)
QUARTUS_FIT_EFFORT=auto

# design source(s) (HDL, SDC)
QUARTUS_SRC=

# TCL scripts (e.g. pin assignments)
QUARTUS_TCL=

################################################################################

include $(QUARTUS_MK)/quartus.mk
