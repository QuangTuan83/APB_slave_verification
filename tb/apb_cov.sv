`ifndef APB_COV_SV
`define APB_COV_SV

class apb_cov #(
    parameter int unsigned ADDR_WIDTH = 16
);

    mailbox #(apb_trans #(ADDR_WIDTH)) mon2cov_mbx;
    apb_trans #(ADDR_WIDTH)            tr;

    covergroup cg_apb;
        option.per_instance = 1;

        cp_reset: coverpoint tr.abort_phase {
            bins normal       = {2'b00};
            bins idle_abort   = {2'b01};
            bins setup_abort  = {2'b10};
            bins access_abort = {2'b11};}

        cp_addr: coverpoint tr.PADDR iff (!tr.is_reset) {
            bins regs[]   = {'h00, 'h04, 'h08, 'h0C};
            bins id_reg   = {'h10};
            bins unmapped = {['h14:$]};}

        cp_pwrite: coverpoint tr.PWRITE iff (!tr.is_reset) {
            bins read  = {1'b0};
            bins write = {1'b1};}

        cp_pstrb: coverpoint tr.PSTRB iff (!tr.is_reset && tr.PWRITE) {
            bins strb[] = {[4'b0000 : 4'b1111]};}

        cp_pwdata: coverpoint tr.PWDATA iff (!tr.is_reset && tr.PWRITE) {
            bins min    = {32'h0000_0000};
            bins max    = {32'hFFFF_FFFF};
            bins others = default;}

        cp_delay: coverpoint tr.delay_cycles iff (!tr.is_reset) {
            bins back_to_back = {0};
            bins single       = {1};
            bins multi        = {[2:5]};}

        cp_pslverr: coverpoint tr.PSLVERR iff (!tr.is_reset) {
            bins normal = {1'b0};
            bins err    = {1'b1};}

        cx_addr_x_pwrite: cross cp_addr, cp_pwrite;

        cx_rw_x_pstrb: cross cp_addr, cp_pstrb { ignore_bins non_rw = binsof(cp_addr.id_reg) || binsof(cp_addr.unmapped);}
    endgroup

    function new(mailbox #(apb_trans #(ADDR_WIDTH)) mon2cov_mbx);
        this.mon2cov_mbx = mon2cov_mbx;
        cg_apb = new();
    endfunction

    task run();
        forever begin
            mon2cov_mbx.get(tr);
            cg_apb.sample();
        end
    endtask

    function void report();
        $display("FUNCTIONAL COVERAGE:%0.2f%%", cg_apb.get_inst_coverage());
    endfunction

endclass : apb_cov

`endif
