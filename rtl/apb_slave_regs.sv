module apb_slave_regs #(
    parameter int unsigned ADDR_WIDTH  = 16,
    parameter int unsigned WAIT_CYCLES = 0
) (
    input  logic                  PCLK,
    input  logic                  PRESETn,
    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic                  PWRITE,
    input  logic [31:0]           PWDATA,
    input  logic [3:0]            PSTRB,
    input  logic [2:0]            PPROT,
    output logic [31:0]           PRDATA,
    output logic                  PREADY,
    output logic                  PSLVERR
);

    localparam logic [ADDR_WIDTH-1:0] ADDR_CTRL     = 'h00;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SCRATCH0 = 'h04;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SCRATCH1 = 'h08;
    localparam logic [ADDR_WIDTH-1:0] ADDR_SCRATCH2 = 'h0C;
    localparam logic [ADDR_WIDTH-1:0] ADDR_ID       = 'h10;

    localparam logic [31:0]           ID_VALUE      = 32'h4150_4231; 

    logic [31:0]           ctrl, scratch0, scratch1, scratch2;
    logic [7:0]            wait_count;
    logic                  addr_valid;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) wait_count <= '0;
        else if (PSEL && PENABLE) begin
            if (wait_count < 8'(WAIT_CYCLES)) wait_count <= wait_count + 1'b1;
        end else begin
            wait_count <= '0;
        end
    end

    assign PREADY = PSEL && PENABLE && (wait_count == 8'(WAIT_CYCLES));

    function automatic logic [31:0] apply_wstrb(
        input logic [31:0] old_data,
        input logic [31:0] wr_data,
        input logic [3:0]  strb
    );
        apply_wstrb[ 7: 0] = strb[0] == 1'b1 ? wr_data[ 7: 0] : old_data[ 7: 0];
        apply_wstrb[15: 8] = strb[1] == 1'b1 ? wr_data[15: 8] : old_data[15: 8];
        apply_wstrb[23:16] = strb[2] == 1'b1 ? wr_data[23:16] : old_data[23:16];
        apply_wstrb[31:24] = strb[3] == 1'b1 ? wr_data[31:24] : old_data[31:24];
    endfunction

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ctrl     <= '0;
            scratch0 <= '0;
            scratch1 <= '0;
            scratch2 <= '0;
        end else if (PSEL && PENABLE && PREADY && PWRITE) begin
            case (PADDR)
                ADDR_CTRL:     ctrl     <= apply_wstrb(ctrl, PWDATA, PSTRB);
                ADDR_SCRATCH0: scratch0 <= apply_wstrb(scratch0, PWDATA, PSTRB);
                ADDR_SCRATCH1: scratch1 <= apply_wstrb(scratch1, PWDATA, PSTRB);
                ADDR_SCRATCH2: scratch2 <= apply_wstrb(scratch2, PWDATA, PSTRB);
                default:;
            endcase
        end 
    end

    always_comb begin
        PRDATA     = '0;
        addr_valid = 1'b1;

        case (PADDR)
            ADDR_CTRL:      PRDATA = ctrl;
            ADDR_SCRATCH0:  PRDATA = scratch0;
            ADDR_SCRATCH1:  PRDATA = scratch1;
            ADDR_SCRATCH2:  PRDATA = scratch2;
            ADDR_ID:        PRDATA = ID_VALUE;
            default:        addr_valid = 1'b0;          
        endcase
        if(!(PSEL && !PWRITE)) begin
            PRDATA = '0;
        end
    end
    assign PSLVERR = PREADY && (!addr_valid || (PWRITE && (PADDR == ADDR_ID)));

endmodule
