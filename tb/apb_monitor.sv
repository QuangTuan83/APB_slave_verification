`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
);
    virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif;
    mailbox #(apb_trans #(ADDR_WIDTH))        mon2scb_mbx, mon2cov_mbx;
    int unsigned                              monitor_count = 0;

    function new(virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif,
                 mailbox #(apb_trans #(ADDR_WIDTH)) scb_mbx, cov_mbx);
        this.vif         = vif;
        this.mon2scb_mbx = scb_mbx;
        this.mon2cov_mbx = cov_mbx;
    endfunction

    task run();
        apb_trans #(ADDR_WIDTH) tr;
        forever begin
            while (!vif.PRESETn) @(vif.mon_cb);
            tr = new();
            fork
                begin
                    @(vif.mon_cb);
                    while (!(vif.mon_cb.PSEL && vif.mon_cb.PENABLE && vif.mon_cb.PREADY)) begin
                        if (!vif.mon_cb.PSEL)        tr.delay_cycles++;
                        else if (vif.mon_cb.PENABLE) tr.wait_cycles++;
                        @(vif.mon_cb);
                    end

                    tr.PADDR   = vif.mon_cb.PADDR;
                    tr.PWRITE  = vif.mon_cb.PWRITE;
                    tr.PWDATA  = vif.mon_cb.PWDATA;
                    tr.PSTRB   = vif.mon_cb.PSTRB;
                    tr.PPROT   = vif.mon_cb.PPROT;
                    tr.PRDATA  = vif.mon_cb.PRDATA;
                    tr.PSLVERR = vif.mon_cb.PSLVERR;
                    monitor_count++;
                end

                begin
                    @(negedge vif.PRESETn);
                    tr.is_reset    = 1'b1;
                    tr.is_aborted  = vif.PSEL;
                    tr.abort_phase = !vif.PSEL ? 2'b01 : (vif.PENABLE ? 2'b11 : 2'b10);
                    if (vif.PSEL) monitor_count++;
                end
            join_any
            disable fork;
            mon2scb_mbx.put(tr);
            mon2cov_mbx.put(tr.copy());
        end
    endtask
endclass : apb_monitor
`endif
