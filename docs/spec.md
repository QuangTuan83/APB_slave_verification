# APB4 Slave Register Specification

`apb_slave_regs` is a 32-bit AMBA APB4 slave with configurable address width (`ADDR_WIDTH`, default 16) and wait states (`WAIT_CYCLES`, default 0).

## Interface

| Port | Dir | Width | Description |
|---|:---:|:---:|---|
| `PCLK` | In | 1 | System clock (rising-edge triggered) |
| `PRESETn` | In | 1 | Active-low asynchronous reset |
| `PADDR` | In | `ADDR_WIDTH` | Byte address |
| `PSEL` | In | 1 | Slave select |
| `PENABLE` | In | 1 | Enable (0 in SETUP, 1 in ACCESS) |
| `PWRITE` | In | 1 | Direction (1 = Write, 0 = Read) |
| `PWDATA` | In | 32 | Write data |
| `PSTRB` | In | 4 | Byte write strobes (`PSTRB[i]` updates `PWDATA[8*i +: 8]`) |
| `PPROT` | In | 3 | Protection type (unused) |
| `PRDATA` | Out | 32 | Read data |
| `PREADY` | Out | 1 | Slave ready |
| `PSLVERR` | Out | 1 | Transfer error |

## Register Map

| Offset | Name | Type | Reset Value | Description |
|---|---|:---:|---|---|
| `0x00` | `CTRL` | RW | `0x0000_0000` | Control register |
| `0x04` | `SCRATCH0` | RW | `0x0000_0000` | Scratch register 0 |
| `0x08` | `SCRATCH1` | RW | `0x0000_0000` | Scratch register 1 |
| `0x0C` | `SCRATCH2` | RW | `0x0000_0000` | Scratch register 2 |
| `0x10` | `ID` | RO | `0x4150_4231` | Read-only ID (`"APB1"`); writes return `PSLVERR` |

## Behavior
- **Reset**: `!PRESETn` asynchronously clears `wait_count` and all RW registers to 0.
- **Wait States**: `PREADY` stays low for `WAIT_CYCLES` cycles in ACCESS, asserting when `wait_count == WAIT_CYCLES`.
- **Writes**: Update selected byte lanes on `PSEL && PENABLE && PREADY && PWRITE`. `PSTRB = 4'b0000` performs no update.
- **Reads**: Drive `PRDATA` combinationally when `PSEL && !PWRITE`, else `0`.
- **Errors**: Unmapped/unaligned accesses or writes to `0x10` assert `PSLVERR = 1` on completion without modifying registers.
