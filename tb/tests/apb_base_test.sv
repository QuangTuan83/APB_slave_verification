`ifndef APB_BASE_TEST_SV
`define APB_BASE_TEST_SV

class apb_base_test #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
);

    virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif;
    apb_env        #(ADDR_WIDTH, WAIT_CYCLES) env;

    function new(virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif, int unsigned num_trans = 0);
        bit _ok;
        this.vif = vif;
        if (num_trans > 0) _ok = $value$plusargs("NUM_TRANS=%d", num_trans);
        this.env = new(vif, num_trans);
    endfunction

    task apply_reset(int unsigned cycles = 5);
        vif.PRESETn = 1'b0;
        repeat (cycles) @(posedge vif.PCLK);
        vif.PRESETn = 1'b1;
    endtask

    function void add_write(
        bit [ADDR_WIDTH-1:0] addr,
        bit [31:0]           data,
        bit [3:0]            strb  = 4'b1111,
        int unsigned         delay = 1
    );
        apb_trans #(ADDR_WIDTH) tr = new();
        tr.PADDR        = addr;
        tr.PWRITE       = 1'b1;
        tr.PWDATA       = data;
        tr.PSTRB        = strb;
        tr.delay_cycles = delay;
        env.gen.custom_queue.push_back(tr);
    endfunction

    function void add_read(
        bit [ADDR_WIDTH-1:0] addr,
        int unsigned         delay = 1
    );
        apb_trans #(ADDR_WIDTH) tr = new();
        tr.PADDR        = addr;
        tr.PWRITE       = 1'b0;
        tr.delay_cycles = delay;
        env.gen.custom_queue.push_back(tr);
    endfunction

    virtual task build();
    endtask

    virtual task run();
        build();
        apply_reset();
        env.run();
        env.report();
    endtask

endclass : apb_base_test

`endif
