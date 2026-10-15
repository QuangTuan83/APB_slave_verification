`ifndef APB_SVA_BIND_SV
`define APB_SVA_BIND_SV

bind apb_slave_regs apb_protocol_sva #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .WAIT_CYCLES(WAIT_CYCLES)
) u_apb_protocol_sva (.*);

`endif
