SHELL := /bin/bash

VIVADO_SETTINGS ?= $(firstword $(wildcard /home/lenovo/tools/AMDDesignTools/2025.2/Vivado/settings64.sh \
                                          /tools/AMDDesignTools/*/Vivado/settings64.sh \
                                          /tools/Xilinx/Vivado/*/settings64.sh \
                                          /opt/Xilinx/Vivado/*/settings64.sh))
VIVADO_PREFIX   := $(if $(wildcard $(VIVADO_SETTINGS)),source $(VIVADO_SETTINGS) &&,)

TESTNAME    ?= apb_directed_test
SEED        ?= 1
ADDR_WIDTH  ?= 16
WAIT_CYCLES ?= 3
SNAPSHOT    ?= apb_sim_aw$(ADDR_WIDTH)_w$(WAIT_CYCLES)
OUT_DIR     ?= out

.PHONY: compile sim run regression wave cov_report clean

compile:
	@mkdir -p $(OUT_DIR)
	cd $(OUT_DIR) && $(VIVADO_PREFIX) xvlog -sv -f ../filelists/fileslist.f
	cd $(OUT_DIR) && $(VIVADO_PREFIX) xelab tb_top -s $(SNAPSHOT) -cc_type sbct -debug typical --timescale 1ns/1ps \
		-generic_top ADDR_WIDTH=$(ADDR_WIDTH) -generic_top WAIT_CYCLES=$(WAIT_CYCLES)

sim:
	@mkdir -p $(OUT_DIR)
	cd $(OUT_DIR) && $(VIVADO_PREFIX) xsim $(SNAPSHOT) --sv_seed $(SEED) \
		--testplusarg TESTNAME=$(TESTNAME) --runall -log sim_$(SNAPSHOT)_$(TESTNAME)_s$(SEED).log
	@! grep -iE "error:|fatal:|assertion.*failed|error=[1-9]" $(OUT_DIR)/sim_$(SNAPSHOT)_$(TESTNAME)_s$(SEED).log >/dev/null || \
		{ echo "SIMULATION FAILED: Error/Fatal detected in $(OUT_DIR)/sim_$(SNAPSHOT)_$(TESTNAME)_s$(SEED).log"; exit 1; }
	@grep -q "TEST PASSED" $(OUT_DIR)/sim_$(SNAPSHOT)_$(TESTNAME)_s$(SEED).log || \
		{ echo "SIMULATION FAILED: Missing TEST PASSED in $(OUT_DIR)/sim_$(SNAPSHOT)_$(TESTNAME)_s$(SEED).log"; exit 1; }

run: compile sim

regression:
	python3 scripts/regression.py

wave: compile
	cd $(OUT_DIR) && $(VIVADO_PREFIX) xsim $(SNAPSHOT) --gui

cov_report: sim
	@mkdir -p reports/coverage_html
	cd $(OUT_DIR) && $(VIVADO_PREFIX) xcrg -cov_db_dir . -cov_db_name $(SNAPSHOT) -report_dir $(CURDIR)/reports/coverage_html -report_format html
	@echo "Coverage report generated at reports/coverage_html/dashboard.html"

clean:
	rm -rf $(OUT_DIR) xsim.dir .Xil *.log *.pb *.jou *.wdb *.vcd
