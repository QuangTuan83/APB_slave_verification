`ifndef APB_RANDOM_TEST_SV
`define APB_RANDOM_TEST_SV

class apb_random_test #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
) extends apb_base_test #(ADDR_WIDTH, WAIT_CYCLES);

    function new(virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif);
        super.new(vif, 678);
    endfunction

    virtual task run();
        build();
        apply_reset();
        fork
            env.run();
            begin
                @(negedge vif.PCLK iff !vif.PSEL);
                apply_reset(2);

                @(posedge vif.PSEL);
                #2ns apply_reset(2);

                if (WAIT_CYCLES > 0) begin
                    @(posedge vif.PENABLE);
                    #2ns apply_reset(2);
                end
            end
        join
        env.report();
    endtask

endclass : apb_random_test

`endif
