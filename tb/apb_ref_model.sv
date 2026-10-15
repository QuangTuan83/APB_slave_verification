`ifndef APB_REF_MODEL_SV
`define APB_REF_MODEL_SV

class apb_ref_model #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
);

    localparam logic [31:0] ID_VALUE = 32'h4150_4231;
    logic [31:0] regs[4];

    function new();
        reset();
    endfunction

    function void reset();
        regs = '{default: '0};
    endfunction

    function automatic logic [31:0] apply_wstrb(logic [31:0] old_val, logic [31:0] new_val, logic [3:0] strb);
        apply_wstrb[ 7: 0] = strb[0] ? new_val[ 7: 0] : old_val[ 7: 0];
        apply_wstrb[15: 8] = strb[1] ? new_val[15: 8] : old_val[15: 8];
        apply_wstrb[23:16] = strb[2] ? new_val[23:16] : old_val[23:16];
        apply_wstrb[31:24] = strb[3] ? new_val[31:24] : old_val[31:24];
    endfunction

    function apb_trans #(ADDR_WIDTH) ref_result(apb_trans #(ADDR_WIDTH) tr);
        apb_trans #(ADDR_WIDTH) exp_tr = new();
        exp_tr.wait_cycles = WAIT_CYCLES;

        if (tr.PWRITE) begin
            case (tr.PADDR)
                'h00:    regs[0]        = apply_wstrb(regs[0], tr.PWDATA, tr.PSTRB);
                'h04:    regs[1]        = apply_wstrb(regs[1], tr.PWDATA, tr.PSTRB);
                'h08:    regs[2]        = apply_wstrb(regs[2], tr.PWDATA, tr.PSTRB);
                'h0C:    regs[3]        = apply_wstrb(regs[3], tr.PWDATA, tr.PSTRB);
                default: exp_tr.PSLVERR = 1'b1;
            endcase
        end else begin
            case (tr.PADDR)
                'h00:    exp_tr.PRDATA  = regs[0];
                'h04:    exp_tr.PRDATA  = regs[1];
                'h08:    exp_tr.PRDATA  = regs[2];
                'h0C:    exp_tr.PRDATA  = regs[3];
                'h10:    exp_tr.PRDATA  = ID_VALUE;
                default: exp_tr.PSLVERR = 1'b1;
            endcase
        end

        return exp_tr;
    endfunction

endclass : apb_ref_model

`endif
