`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV

class apb_scoreboard #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
);

    mailbox #(apb_trans #(ADDR_WIDTH))       mon2scb_mbx;
    apb_ref_model #(ADDR_WIDTH, WAIT_CYCLES) ref_model;
    int unsigned                             pass_count = 0, error_count = 0, reset_count = 0;

    function new(mailbox #(apb_trans #(ADDR_WIDTH)) mon2scb_mbx);
        this.mon2scb_mbx = mon2scb_mbx;
        this.ref_model   = new();
    endfunction

    function void compare(apb_trans #(ADDR_WIDTH) act_tr, apb_trans #(ADDR_WIDTH) exp_tr);
        if (act_tr.PRDATA === exp_tr.PRDATA &&
            act_tr.PSLVERR === exp_tr.PSLVERR &&
            act_tr.wait_cycles === exp_tr.wait_cycles) begin
            pass_count++;
            return;
        end

        error_count++;
        $error("[SCB] BUG at %0t | ADDR=0x%0h WR=%0b", $time, act_tr.PADDR, act_tr.PWRITE);
        if (act_tr.PRDATA !== exp_tr.PRDATA)
            $display("-> PRDATA: ACT=0x%08h != EXP=0x%08h", act_tr.PRDATA, exp_tr.PRDATA);
        if (act_tr.PSLVERR !== exp_tr.PSLVERR)
            $display("-> PSLVERR: ACT=%0b != EXP=%0b", act_tr.PSLVERR, exp_tr.PSLVERR);
        if (act_tr.wait_cycles !== exp_tr.wait_cycles)
            $display("-> WAIT_CYCLES: ACT=%0d != EXP=%0d", act_tr.wait_cycles, exp_tr.wait_cycles);
    endfunction

    task run();
        apb_trans #(ADDR_WIDTH) act_tr;
        forever begin
            mon2scb_mbx.get(act_tr);
            if (act_tr.is_reset || act_tr.is_aborted) begin
                ref_model.reset();
                reset_count++;
                continue;
            end
            compare(act_tr, ref_model.ref_result(act_tr));
        end
    endtask

    function void report();
        $display("[SCB] SUMMARY: pass=%0d | error=%0d | reset=%0d",
                 pass_count, error_count, reset_count);
    endfunction

endclass : apb_scoreboard

`endif
