################################################################################
# quartus.mk - makefile support for Quartus designs
#
# To use, include at the end of a makefile that defines the following...
#	QUARTUS_PART			FPGA part number
#	QUARTUS_TOP				top entity name for synthesis and implementation
#	QUARTUS_MAP_OPTIMIZE	synthesis optimization (area|speed|balanced)
#	QUARTUS_FIT_EFFORT		fitter effort (standard|fast|auto)
# ...and optionally...
#	QUARTUS_VHDL			design source(s) (VHDL)
#	QUARTUS_VLOG			design source(s) (Verilog)
#	QUARTUS_TCL				TCL scripts (e.g. pin assignments)
#	QUARTUS_SDC				timing constraints
#	QUARTUS_QIP				IP qip file(s)
#	QUARTUS_SIP				IP sip file(s)
#	QUARTUS_MIF				memory initialisation file(s)
#	QUARTUS_PGM_OPT			command line options for quartus_pgm
# Define QUARTUS_PATH if the Quartus executables are not in your path.
#
################################################################################

QUARTUS_SH=$(QUARTUS_PATH:=/)quartus_sh
QUARTUS_MAP=$(QUARTUS_PATH:=/)quartus_map
QUARTUS_FIT=$(QUARTUS_PATH:=/)quartus_fit
QUARTUS_ASM=$(QUARTUS_PATH:=/)quartus_asm
QUARTUS_PGM=$(QUARTUS_PATH:=/)quartus_pgm
QUARTUS_CPF=$(QUARTUS_PATH:=/)quartus_cpf

QUARTUS_DIR=quartus

ifndef QUARTUS_PART
$(error QUARTUS_PART not defined)
endif
ifndef QUARTUS_TOP
$(error QUARTUS_TOP not defined)
endif
ifndef QUARTUS_PGM_OPT
QUARTUS_PGM_OPT=-m jtag -c 1
endif

QUARTUS_RBF_FILE=$(QUARTUS_TOP).rbf
QUARTUS_SOF_FILE=$(QUARTUS_TOP).sof
QUARTUS_FIT_FILE=$(QUARTUS_DIR)/db/$(QUARTUS_TOP).cmp.cdb
QUARTUS_MAP_FILE=$(QUARTUS_DIR)/db/$(QUARTUS_TOP).map.cdb
QUARTUS_QPF_FILE=$(QUARTUS_DIR)/$(QUARTUS_TOP).qpf

prog: $(QUARTUS_SOF_FILE)
	$(QUARTUS_PGM) $(QUARTUS_PGM_OPT) -o P\;$(QUARTUS_SOF_FILE)$(addprefix @,$(QUARTUS_PGM_DEV))

rbf: $(QUARTUS_RBF_FILE)
$(QUARTUS_RBF_FILE): $(QUARTUS_SOF_FILE)
	$(QUARTUS_CPF) -c $(QUARTUS_SOF_FILE) $(QUARTUS_RBF_FILE)

sof: $(QUARTUS_SOF_FILE)
$(QUARTUS_SOF_FILE): $(QUARTUS_FIT_FILE)
	$(QUARTUS_ASM) \
		$(QUARTUS_DIR)/$(QUARTUS_TOP) \
		--rev=$(QUARTUS_TOP)
	mv $(QUARTUS_DIR)/output_files/$(QUARTUS_SOF_FILE) .

fit: $(QUARTUS_FIT_FILE)
$(QUARTUS_FIT_FILE): $(QUARTUS_MAP_FILE) $(QUARTUS_MIF) $(QUARTUS_SDC)
	$(QUARTUS_FIT) \
		$(QUARTUS_DIR)/$(QUARTUS_TOP) \
		--effort=$(QUARTUS_FIT_EFFORT) \
		--rev=$(QUARTUS_TOP)

map: $(QUARTUS_MAP_FILE)
$(QUARTUS_MAP_FILE): $(QUARTUS_QIP) $(QUARTUS_SIP) $(QUARTUS_VHDL) $(QUARTUS_VLOG) | $(QUARTUS_QPF_FILE)
	$(QUARTUS_MAP) \
		$(QUARTUS_DIR)/$(QUARTUS_TOP) \
		--part=$(QUARTUS_PART) \
		$(addprefix --optimize=,$(QUARTUS_MAP_OPTIMIZE)) \
		--rev=$(QUARTUS_TOP)

qpf: $(QUARTUS_QPF_FILE)
$(QUARTUS_QPF_FILE): makefile $(QUARTUS_TCL) | $(QUARTUS_QIP) $(QUARTUS_MIF) $(QUARTUS_SIP) $(QUARTUS_VHDL) $(QUARTUS_VLOG) $(QUARTUS_SDC)
	rm -rf $(QUARTUS_DIR)
	mkdir $(QUARTUS_DIR)
	$(QUARTUS_SH) --tcl_eval \
		project_new $(QUARTUS_DIR)/$(QUARTUS_TOP) -revision $(QUARTUS_TOP) -overwrite \;\
		set_global_assignment -name DEVICE $(QUARTUS_PART) \;\
		set_global_assignment -name TOP_LEVEL_ENTITY $(QUARTUS_TOP) \;\
		set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files \;\
		$(addprefix set_global_assignment -name QIP_FILE ,$(QUARTUS_QIP:=\;)) \
		$(addprefix set_global_assignment -name SIP_FILE ,$(QUARTUS_SIP:=\;)) \
		$(addprefix set_global_assignment -name MIF_FILE ,$(QUARTUS_MIF:=\;)) \
		$(addprefix set_global_assignment -name VHDL_FILE ,$(QUARTUS_VHDL:=\;)) \
		$(addprefix set_global_assignment -name VERILOG_FILE ,$(QUARTUS_VLOG:=\;)) \
		$(addprefix set_global_assignment -name SDC_FILE ,$(QUARTUS_SDC:=\;)) \
		$(subst =, ,$(addprefix set_parameter -name ,$(QUARTUS_GEN:=\;))) \
		$(addprefix source ,$(QUARTUS_TCL:=\;))

clean::
	rm -rf $(QUARTUS_DIR)
