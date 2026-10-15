`ifndef APB_GEN_SV
`define APB_GEN_SV

class apb_gen #(
    parameter int unsigned ADDR_WIDTH = 16
);

    mailbox #(apb_trans #(ADDR_WIDTH)) gen2drv_mbx;
    int unsigned                       num_transactions;
    int unsigned                       gen_count;
    apb_trans #(ADDR_WIDTH)            custom_queue[$];

    function new(mailbox #(apb_trans #(ADDR_WIDTH)) gen2drv_mbx, int unsigned num_transactions = 20);
        this.gen2drv_mbx       = gen2drv_mbx;
        this.num_transactions  = num_transactions;
        this.gen_count         = 0;
    endfunction : new

    task run();
        apb_trans #(ADDR_WIDTH) tr;
        if (custom_queue.size() > 0) begin
            while (custom_queue.size() > 0) begin
                tr = custom_queue.pop_front();
                gen2drv_mbx.put(tr.copy());
                gen_count++;
            end
        end else begin
            for (int unsigned i = 0; i < num_transactions; i++) begin
                tr = new();
                if (!tr.randomize()) $fatal(1, "[GEN] Randomization failed at index %0d!", i);
                gen2drv_mbx.put(tr);
                gen_count++;
            end
        end
    endtask : run

endclass : apb_gen

`endif
