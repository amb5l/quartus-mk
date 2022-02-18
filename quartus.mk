################################################################################
# quartus.mk - makefile support for Quartus designs
#
# To use, include at the end of a makefile that defines the following...
#	QUARTUS_PART			FPGA part number
#	QUARTUS_TOP				top entity name for synthesis and implementation
#	QUARTUS_MAP_OPTIMIZE	synthesis optimization (area|speed|balanced)
#	QUARTUS_FIT_EFFORT		fitter effort (standard|fast|auto)
#	QUARTUS_SRC				design source(s) (HDL, SDC)
#	QUARTUS_TCL				TCL scripts (e.g. pin assignments)
#
# Define QUARTUS_PATH if the Quartus executables are not in your path.
#
################################################################################

QUARTUS_SH=$(QUARTUS_PATH:=/)quartus_sh
QUARTUS_MAP=$(QUARTUS_PATH:=/)quartus_map
QUARTUS_FIT=$(QUARTUS_PATH:=/)quartus_fit
QUARTUS_ASM=$(QUARTUS_PATH:=/)quartus_asm

QUARTUS_DIR=quartus

ifndef QUARTUS_PART
$(error QUARTUS_PART not defined)
endif
ifndef QUARTUS_TOP
$(error QUARTUS_TOP not defined)
endif

QUARTUS_SOF_FILE=$(QUARTUS_DIR)/output_files/$(QUARTUS_TOP).sof
QUARTUS_FIT_FILE=$(QUARTUS_DIR)/db/$(QUARTUS_TOP).fit.qmsg
QUARTUS_MAP_FILE=$(QUARTUS_DIR)/db/$(QUARTUS_TOP).cdb
QUARTUS_QPF_FILE=$(QUARTUS_DIR)/$(QUARTUS_TOP).qpf

sof: $(QUARTUS_SOF_FILE)
$(QUARTUS_SOF_FILE): $(QUARTUS_FIT_FILE)
	$(QUARTUS_ASM) \
		$(QUARTUS_DIR)/$(QUARTUS_TOP) \
		--rev=$(QUARTUS_TOP)

fit: $(QUARTUS_FIT_FILE)
$(QUARTUS_FIT_FILE): $(QUARTUS_MAP_FILE)
	$(QUARTUS_FIT) \
		$(QUARTUS_DIR)/$(QUARTUS_TOP) \
		--effort=$(QUARTUS_FIT_EFFORT) \
		--rev=$(QUARTUS_TOP)

map: $(QUARTUS_MAP_FILE)
$(QUARTUS_MAP_FILE): $(QUARTUS_SRC) $(QUARTUS_QPF_FILE)
	$(QUARTUS_MAP) \
		$(QUARTUS_DIR)/$(QUARTUS_TOP) \
		--part=$(QUARTUS_PART) \
		$(addprefix --optimize=,$(QUARTUS_MAP_OPTIMIZE)) \
		--rev=$(QUARTUS_TOP) \
		$(foreach X,$(QUARTUS_SRC),--source=$X)

qpf: $(QUARTUS_QPF_FILE)
$(QUARTUS_QPF_FILE): makefile $(QUARTUS_TCL)
	rm -rf $(QUARTUS_DIR)
	mkdir $(QUARTUS_DIR)
	$(QUARTUS_SH) --tcl_eval \
		project_new $(QUARTUS_DIR)/$(QUARTUS_TOP) -revision $(QUARTUS_TOP) -overwrite \;\
		set_global_assignment -name DEVICE $(QUARTUS_PART) \;\
		set_global_assignment -name TOP_LEVEL_ENTITY $(QUARTUS_TOP) \;\
		set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files \;\
		$(addprefix source ,$(QUARTUS_TCL:=;))

clean::
	rm -rf $(QUARTUS_DIR)
