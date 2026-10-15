`ifndef APB_DIRECTED_TEST_SV
`define APB_DIRECTED_TEST_SV

class apb_directed_test #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
) extends apb_base_test #(ADDR_WIDTH, WAIT_CYCLES);

    function new(virtual apb_if #(ADDR_WIDTH, WAIT_CYCLES) vif);
        super.new(vif);
    endfunction

    virtual task build();
        add_write('h00, 32'hCAFE_0001);
        add_write('h00, 32'hDEAD_0001, 4'hF, 3);
        if (WAIT_CYCLES > 0) add_write('h04, 32'hDEAD_0002);

        for (int addr = 'h00; addr <= 'h0C; addr += 4) begin
            for (int strb = 0; strb < 16; strb++) begin
                bit [31:0] data = (strb == 0)  ? 32'h0000_0000 :
                                  (strb == 15) ? 32'hFFFF_FFFF : 32'h5555_5555;
                add_write(addr, data, strb, strb % 4);
                add_read (addr, 0);
            end
        end

        add_write('h10, 32'hDEAD_BEEF); add_read('h10);
        add_write('h14, 32'hBAD1_0000); add_read('h14);
    endtask

    virtual task run();
        build();
        apply_reset();
        fork
            env.run();
            begin
                while (!(env.drv.driver_count == 1 && !vif.PSEL)) @(posedge vif.PCLK);
                #2ns apply_reset(2);

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

endclass : apb_directed_test

`endif
