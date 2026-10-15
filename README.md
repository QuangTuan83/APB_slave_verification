# APB4 Slave Verification

SystemVerilog OOP testbench for `apb_slave_regs` using Vivado XSim.

## Project Structure

```text
.
├── Makefile
├── rtl/                  # apb_slave_regs.sv
├── sva/                  # Protocol assertions and bind
├── tb/                   # Layered testbench and coverage
│   └── tests/            # Directed and random tests
├── filelists/            # fileslist.f
├── scripts/              # regression.py
├── reports/              # Regression and coverage outputs
└── docs/                 # spec.md, verification_plan.md
```

## Make

```bash
make run                                  # Run directed test
make run TESTNAME=apb_random_test SEED=42 # Run random test
make run WAIT_CYCLES=0                    # Override parameters (WAIT_CYCLES, ADDR_WIDTH)
make regression                           # Run 20-seed regression
make cov_report                           # Generate HTML coverage report
make wave                                 # Open waveform in XSim GUI
make clean
```
