`ifndef APB_ENV_SV
`define APB_ENV_SV

class apb_env #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
);

    virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif;
    mailbox #(apb_trans #(ADDR_WIDTH))        gen2drv_mbx, mon2scb_mbx, mon2cov_mbx;

    apb_gen        #(ADDR_WIDTH)              gen;
    apb_driver     #(ADDR_WIDTH, WAIT_CYCLES) drv;
    apb_monitor    #(ADDR_WIDTH, WAIT_CYCLES) mon;
    apb_scoreboard #(ADDR_WIDTH, WAIT_CYCLES) scb;
    apb_cov        #(ADDR_WIDTH)              cov;

    function new(virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif,
                 int unsigned num_trans = 0);
        this.vif    = vif;
        gen2drv_mbx = new();
        mon2scb_mbx = new();
        mon2cov_mbx = new();

        gen = new(gen2drv_mbx, num_trans);
        drv = new(vif, gen2drv_mbx);
        mon = new(vif, mon2scb_mbx, mon2cov_mbx);
        scb = new(mon2scb_mbx);
        cov = new(mon2cov_mbx);
    endfunction

    task run();
        fork
            drv.run();
            mon.run();
            scb.run();
            cov.run();
            begin
                wait (vif.PRESETn);
                gen.run();
                wait (drv.driver_count == gen.gen_count && mon.monitor_count == gen.gen_count);
                while (mon2scb_mbx.num() > 0 || mon2cov_mbx.num() > 0) @(vif.cb);
                repeat (2) @(vif.cb);
            end
            begin
                repeat (10000) @(vif.cb);
                $fatal(1, "[ENV] TIMEOUT at 10000 cycles!");
            end
        join_any
        disable fork;
    endtask

    function void report();
        scb.report();
        cov.report();
        if (scb.error_count == 0 && mon.monitor_count > 0)
            $display("TEST PASSED (Count=%0d)", mon.monitor_count);
        else
            $fatal(1, "TEST FAILED (Errors=%0d)", scb.error_count);
    endfunction

endclass : apb_env

`endif
