`ifndef APB_PROTOCOL_SVA_SV
`define APB_PROTOCOL_SVA_SV

module apb_protocol_sva #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
) (
    input  logic                  PCLK,
    input  logic                  PRESETn,
    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic                  PWRITE,
    input  logic [31:0]           PWDATA,
    input  logic [3:0]            PSTRB,
    input  logic [2:0]            PPROT,
    input  logic [31:0]           PRDATA,
    input  logic                  PREADY,
    input  logic                  PSLVERR,
    input  logic [7:0]            wait_count,
    input  logic [31:0]           ctrl, scratch0, scratch1, scratch2
);

    default clocking cb @(posedge PCLK); endclocking

    reset_regs: assert property (
        !PRESETn |-> !{wait_count, ctrl, scratch0, scratch1, scratch2}
    ) else $error("ERROR: [SVA] reset_regs failed");

    setup_to_access: assert property (
        disable iff (!PRESETn)
        (PSEL && (!PENABLE || !PREADY)) |=> (PSEL && PENABLE)
    ) else $error("ERROR: [SVA] setup_to_access failed");

    penable_after_ready: assert property (
        disable iff (!PRESETn)
        (PSEL && PENABLE && PREADY) |=> !PENABLE
    ) else $error("ERROR: [SVA] penable_after_ready failed");

    psel_to_penable: assert property (
        disable iff (!PRESETn)
        PENABLE |-> PSEL
    ) else $error("ERROR: [SVA] psel_to_penable failed");

    control_data_stable: assert property (
        disable iff (!PRESETn)
        (PSEL && (!PENABLE || !PREADY)) |=> ($stable({PADDR, PWRITE, PSTRB, PPROT}) &&
                               (!PWRITE || $stable(PWDATA)))
    ) else $error("ERROR: [SVA] control_data_stable failed");

    no_pstrb_on_read: assert property (
        disable iff (!PRESETn)
        (PSEL && !PWRITE) |-> !PSTRB
    ) else $error("ERROR: [SVA] no_pstrb_on_read failed");

    wait_pready: assert property (
        disable iff (!PRESETn)
        PREADY == (PSEL && PENABLE && (wait_count == 8'(WAIT_CYCLES)))
    ) else $error("ERROR: [SVA] wait_pready failed");

    pready_w_pslverr: assert property (
        disable iff (!PRESETn)
        PSLVERR |-> (PSEL && PENABLE && PREADY)
    ) else $error("ERROR: [SVA] pready_w_pslverr failed");

    no_xz: assert property (
        disable iff (!PRESETn)
        !$isunknown({PSEL, PENABLE, PREADY, PSLVERR, PRDATA}) &&
        (!PSEL || !$isunknown({PADDR, PWRITE, PSTRB, PPROT, PWDATA}))
    ) else $error("ERROR: [SVA] no_xz failed");

endmodule : apb_protocol_sva

`endif
