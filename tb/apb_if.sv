`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
) (
    input logic PCLK
);

    logic                  PRESETn = 1'b0;
    logic [ADDR_WIDTH-1:0] PADDR   = '0;
    logic                  PSEL    = 1'b0;
    logic                  PENABLE = 1'b0;
    logic                  PWRITE  = 1'b0;
    logic [31:0]           PWDATA  = '0;
    logic [3:0]            PSTRB   = '0;
    logic [2:0]            PPROT   = '0;

    logic [31:0]           PRDATA;
    logic                  PREADY;
    logic                  PSLVERR;

    clocking cb @(posedge PCLK);
        default input #1step output #0;
        inout PRESETn;
        inout PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PPROT;
        input PRDATA, PREADY, PSLVERR;
    endclocking

    clocking mon_cb @(posedge PCLK);
        default input #1step;
        input PRESETn;
        input PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PPROT;
        input PRDATA, PREADY, PSLVERR;
    endclocking

endinterface : apb_if

`endif
