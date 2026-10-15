`timescale 1ns/1ps

import apb_pkg::*;

module tb_top #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
);

    logic PCLK = 1'b0;
    always #5 PCLK = ~PCLK;

    apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif (PCLK);

    apb_slave_regs #(ADDR_WIDTH, WAIT_CYCLES) dut (
        .PCLK(vif.PCLK),     .PRESETn(vif.PRESETn), .PADDR(vif.PADDR),   .PSEL(vif.PSEL),
        .PENABLE(vif.PENABLE), .PWRITE(vif.PWRITE), .PWDATA(vif.PWDATA), .PSTRB(vif.PSTRB),
        .PPROT(vif.PPROT),   .PREADY(vif.PREADY),   .PRDATA(vif.PRDATA), .PSLVERR(vif.PSLVERR)
    );

    apb_base_test     #(ADDR_WIDTH, WAIT_CYCLES) test;
    apb_directed_test #(ADDR_WIDTH, WAIT_CYCLES) directed;
    apb_random_test   #(ADDR_WIDTH, WAIT_CYCLES) random;
    string testname = "apb_directed_test";

    initial begin
        $value$plusargs("TESTNAME=%s", testname);
        $display("Running test: %s", testname);

        if (testname == "apb_directed_test") begin
            directed = new(vif);
            test     = directed;
        end else if (testname == "apb_random_test") begin
            random = new(vif);
            test   = random;
        end else begin
            $fatal(1, "[TB_TOP] Unknown test name: %s", testname);
        end

        test.run();
        $finish;
    end

endmodule : tb_top
