// systolic_top.v - Corrected version compatible with Icarus Verilog
// Systolic array with proper data flow between PEs

module systolic_top #(
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32,
    parameter integer M = 4, // rows
    parameter integer N = 4, // cols
    parameter integer SIGNED = 0
)(
    input  wire                     clk,
    input  wire                     rst_n,
    
    // Global stream inputs
    input  wire [DATA_W-1:0]        a_in,
    input  wire                     a_in_valid,
    output wire                     a_in_ready,

    input  wire [DATA_W-1:0]        b_in,
    input  wire                     b_in_valid,
    output wire                     b_in_ready

    // Note: Outputs removed from port list - will be accessed via hierarchical reference
    // or you can add them back as flattened arrays if needed
);

    // Flattened output arrays (internal wires)
    wire [ACC_W-1:0] out_matrix [0:(M*N)-1];
    wire             out_valid [0:(M*N)-1];
    wire             out_ready [0:(M*N)-1];
    
    // For testbench: tie all output ready signals high
    genvar idx;
    generate
        for (idx = 0; idx < M*N; idx = idx + 1) begin : tie_out_ready
            assign out_ready[idx] = 1'b1;
        end
    endgenerate

    // Inter-PE horizontal connections (a flows left to right)
    wire [DATA_W-1:0] a_horz [0:M-1][0:N];
    wire              a_horz_valid [0:M-1][0:N];
    wire              a_horz_ready [0:M-1][0:N];

    // Inter-PE vertical connections (b flows top to bottom)
    wire [DATA_W-1:0] b_vert [0:M][0:N-1];
    wire              b_vert_valid [0:M][0:N-1];
    wire              b_vert_ready [0:M][0:N-1];

    genvar i, j;
    
    // ========== Input Connections ==========
    // Connect leftmost column (col 0) to global a_in
    generate
        for (i = 0; i < M; i = i + 1) begin : connect_a_input
            assign a_horz[i][0] = a_in;
            assign a_horz_valid[i][0] = a_in_valid;
        end
    endgenerate
    
    // Connect topmost row (row 0) to global b_in
    generate
        for (j = 0; j < N; j = j + 1) begin : connect_b_input
            assign b_vert[0][j] = b_in;
            assign b_vert_valid[0][j] = b_in_valid;
        end
    endgenerate
    
    // ========== Global Ready Signals ==========
    // a_in_ready: combine ready signals from all leftmost PEs (column 0)
    wire [M-1:0] a_ready_col0;
    generate
        for (i = 0; i < M; i = i + 1) begin : collect_a_ready
            assign a_ready_col0[i] = a_horz_ready[i][0];
        end
    endgenerate
    assign a_in_ready = &a_ready_col0;
    
    // b_in_ready: combine ready signals from all topmost PEs (row 0)
    wire [N-1:0] b_ready_row0;
    generate
        for (j = 0; j < N; j = j + 1) begin : collect_b_ready
            assign b_ready_row0[j] = b_vert_ready[0][j];
        end
    endgenerate
    assign b_in_ready = &b_ready_row0;

    // ========== PE Array Instantiation ==========
    generate
        for (i = 0; i < M; i = i + 1) begin : row
            for (j = 0; j < N; j = j + 1) begin : col
                
                mac_pe #(
                    .DATA_W(DATA_W),
                    .ACC_W(ACC_W),
                    .SIGNED(SIGNED)
                ) pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    // Horizontal data flow (left to right)
                    .a(a_horz[i][j]),
                    .a_valid(a_horz_valid[i][j]),
                    .a_ready(a_horz_ready[i][j]),
                    
                    .a_out(a_horz[i][j+1]),
                    .a_out_valid(a_horz_valid[i][j+1]),
                    .a_out_ready(a_horz_ready[i][j+1]),
                    
                    // Vertical data flow (top to bottom)
                    .b(b_vert[i][j]),
                    .b_valid(b_vert_valid[i][j]),
                    .b_ready(b_vert_ready[i][j]),
                    
                    .b_out(b_vert[i+1][j]),
                    .b_out_valid(b_vert_valid[i+1][j]),
                    .b_out_ready(b_vert_ready[i+1][j]),
                    
                    // Accumulator output
                    .out(out_matrix[i*N + j]),
                    .out_valid(out_valid[i*N + j]),
                    .out_ready(out_ready[i*N + j])
                );
                
            end
        end
    endgenerate
    
    // ========== Boundary Conditions ==========
    // Tie off ready signals at rightmost edge
    generate
        for (i = 0; i < M; i = i + 1) begin : tie_right_edge
            assign a_horz_ready[i][N] = 1'b1;
        end
    endgenerate
    
    // Tie off ready signals at bottom edge
    generate
        for (j = 0; j < N; j = j + 1) begin : tie_bottom_edge
            assign b_vert_ready[M][j] = 1'b1;
        end
    endgenerate

endmodule
