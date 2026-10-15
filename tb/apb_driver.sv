`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

class apb_driver #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
);

    virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif;
    mailbox #(apb_trans #(ADDR_WIDTH))        gen2drv_mbx;
    int unsigned                              driver_count = 0;

    function new(virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif,
                 mailbox #(apb_trans #(ADDR_WIDTH)) mbx);
        this.vif         = vif;
        this.gen2drv_mbx = mbx;
    endfunction

    task reset();
        vif.cb.PSEL    <= '0;
        vif.cb.PENABLE <= '0;
        vif.cb.PADDR   <= '0;
        vif.cb.PWRITE  <= '0;
        vif.cb.PWDATA  <= '0;
        vif.cb.PSTRB   <= '0;
        vif.cb.PPROT   <= '0;
    endtask

    task drive_transfer(apb_trans #(ADDR_WIDTH) tr);
        while (!vif.PRESETn) @(vif.cb);
        repeat (tr.delay_cycles) begin
            @(vif.cb);
            while (!vif.PRESETn) @(vif.cb);
        end

        fork
            begin
                vif.cb.PSEL    <= 1'b1;
                vif.cb.PENABLE <= 1'b0;
                vif.cb.PADDR   <= tr.PADDR;
                vif.cb.PWRITE  <= tr.PWRITE;
                vif.cb.PWDATA  <= tr.PWDATA;
                vif.cb.PSTRB   <= tr.PWRITE ? tr.PSTRB : 4'b0000;
                vif.cb.PPROT   <= tr.PPROT;

                @(vif.cb);
                vif.cb.PENABLE <= 1'b1;

                do @(vif.cb); while (vif.cb.PREADY !== 1'b1);

                vif.cb.PSEL    <= 1'b0;
                vif.cb.PENABLE <= 1'b0;
            end

            begin
                @(negedge vif.PRESETn);
                reset();
            end
        join_any
        disable fork;

        driver_count++;
    endtask

    task run();
        apb_trans #(ADDR_WIDTH) tr;
        reset();
        forever begin
            gen2drv_mbx.get(tr);
            drive_transfer(tr);
        end
    endtask

endclass : apb_driver

`endif
