`ifndef APB_TRANS_SV
`define APB_TRANS_SV

class apb_trans #(
    parameter int unsigned ADDR_WIDTH = 16
);

    rand bit [ADDR_WIDTH-1:0] PADDR;
    rand bit                  PWRITE;
    rand bit [31:0]           PWDATA;
    rand bit [3:0]            PSTRB;
    rand bit [2:0]            PPROT;
    rand int unsigned         delay_cycles;

    logic [31:0] PRDATA      = '0;
    logic        PSLVERR     = 1'b0;
    int unsigned wait_cycles = 0;
    bit          is_reset    = 1'b0;
    bit          is_aborted  = 1'b0;
    bit [1:0]    abort_phase = 2'b00;

    constraint c_pwdata {
        PWDATA dist {
            32'h0000_0000 := 5,
            32'hFFFF_FFFF := 5,
            [32'h0000_0001 : 32'hFFFF_FFFE] :/ 90 };}

    constraint c_delay_cycles {
        delay_cycles dist{   0 :/ 50,
                         [1:3] :/ 30, 
                         [4:5] :/ 20 };}

    constraint strb_read {
        (!PWRITE) -> (PSTRB == 4'b0000);}

    constraint addr {
        PADDR dist {
            'h00 := 20, 'h04 := 20, 'h08 := 20, 'h0C := 20,
            'h10 := 5,
            'h14 := 3,  'h18 := 3,  'h1C := 3,
            ['h01 : 'h03] := 2
        };
    }

    function apb_trans #(ADDR_WIDTH) copy();
        copy = new this;
    endfunction

    function void display(string prefix = "");
        $display("[%s] PADDR=0x%0h PWRITE=%0b PWDATA=0x%08h PSTRB=0x%0h PPROT=0x%0h delay=%0d  PRDATA=0x%08h PSLVERR=%0b wait=%0d rst=%0b abort=%0b (%0b)",
                 prefix, PADDR, PWRITE, PWDATA, PSTRB, PPROT, delay_cycles,
                 PRDATA, PSLVERR, wait_cycles, is_reset, is_aborted, abort_phase);
    endfunction

endclass : apb_trans

`endif
