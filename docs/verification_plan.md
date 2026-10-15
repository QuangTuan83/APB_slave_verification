# Verification Plan

## Test Scenarios
- `apb_directed_test`: Writes/reads all 4 RW registers (`0x00..0x0C`) across all 16 `PSTRB` values, tests RO `ID` (`0x10`) and unmapped (`0x14`) error responses, sweeps idle delays (`0..3`), and triggers reset aborts in IDLE, SETUP, and ACCESS phases.
- `apb_random_test`: Runs 678 randomized transfers per seed with mid-transfer reset aborts across IDLE, SETUP, and ACCESS phases.

## Protocol Assertions (`sva/apb_protocol_sva.sv`)
- `reset_regs`: Async reset clears `wait_count` and all RW registers to 0.
- `setup_to_access`: SETUP and wait-state cycles transition to / stay in ACCESS (`PSEL && PENABLE`).
- `penable_after_ready`: `PENABLE` deasserts on the cycle after transfer completion.
- `psel_to_penable`: `PENABLE` never asserts without `PSEL`.
- `control_data_stable`: Address, control, and write data remain stable during SETUP and wait states.
- `no_pstrb_on_read`: `PSTRB` is `4'b0000` during read transfers.
- `wait_pready`: `PREADY` asserts after exactly `WAIT_CYCLES` in ACCESS.
- `pready_w_pslverr`: `PSLVERR` only asserts on a valid transfer completion cycle.
- `no_xz`: No X/Z values on active bus signals.

## Coverage (`tb/apb_cov.sv`)
- `cp_reset`: `normal`, `idle_abort`, `setup_abort`, `access_abort`.
- `cp_addr`: RW regs (`0x00..0x0C`), RO ID (`0x10`), unmapped (`>= 0x14`).
- `cp_pwrite`: Read (`0`), Write (`1`).
- `cp_pstrb`: All 16 write strobe values (`4'b0000..4'b1111`).
- `cp_pwdata`: `0x0000_0000`, `0xFFFF_FFFF`, and other patterns.
- `cp_delay`: Back-to-back (`0`), single (`1`), multi-cycle (`2..5`).
- `cp_pslverr`: Normal (`0`) and error (`1`).
- Crosses: `cx_addr_x_pwrite` (all regions x R/W) and `cx_rw_x_pstrb` (4 RW regs x 16 strobes).

## Pass Criteria
- Zero compile/elaboration errors and no watchdog timeouts (10,000 cycles).
- Scoreboard `error = 0` and `TEST PASSED` banner printed in log.
- Zero SVA errors, 100% functional coverage on directed test, and 20/20 seeds passing in `make regression`.
