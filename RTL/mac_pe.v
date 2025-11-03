// mac_pe.v - Fixed version with data forwarding
// Parameterized MAC PE with streaming valid/ready handshake and pass-through outputs
module mac_pe #(
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32,
    parameter integer SIGNED = 0
)(
    input  wire                     clk,
    input  wire                     rst_n,
    
    // streaming inputs: a (from left), b (from top)
    input  wire [DATA_W-1:0]        a,
    input  wire                     a_valid,
    output wire                     a_ready,
    
    input  wire [DATA_W-1:0]        b,
    input  wire                     b_valid,
    output wire                     b_ready,
    
    // pass-through outputs: a (to right), b (to bottom)
    output reg  [DATA_W-1:0]        a_out,
    output reg                      a_out_valid,
    input  wire                     a_out_ready,
    
    output reg  [DATA_W-1:0]        b_out,
    output reg                      b_out_valid,
    input  wire                     b_out_ready,
    
    // streaming output: accumulator result
    output reg  [ACC_W-1:0]         out,
    output reg                      out_valid,
    input  wire                     out_ready
);

    // Internal state
    reg have_a, have_b;
    reg [DATA_W-1:0] a_reg;
    reg [DATA_W-1:0] b_reg;
    reg [ACC_W-1:0] acc_reg;
    
    // Ready signals: can accept when we don't have data AND downstream is ready
    assign a_ready = !have_a || (have_a && have_b && a_out_ready);
    assign b_ready = !have_b || (have_a && have_b && b_out_ready);
    
    // Multiply logic
    wire signed [DATA_W-1:0] a_signed = (SIGNED) ? $signed(a_reg) : $signed({1'b0, a_reg[DATA_W-2:0]});
    wire signed [DATA_W-1:0] b_signed = (SIGNED) ? $signed(b_reg) : $signed({1'b0, b_reg[DATA_W-2:0]});
    
    wire signed [2*DATA_W-1:0] mul_result;
    assign mul_result = (SIGNED) ? (a_signed * b_signed) : ($signed($unsigned(a_reg) * $unsigned(b_reg)));
    
    // Sign-extend multiply result to accumulator width
    wire signed [ACC_W-1:0] mul_ext = {{(ACC_W-2*DATA_W){mul_result[2*DATA_W-1]}}, mul_result};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            have_a <= 1'b0;
            have_b <= 1'b0;
            a_reg  <= {DATA_W{1'b0}};
            b_reg  <= {DATA_W{1'b0}};
            acc_reg <= {ACC_W{1'b0}};
            
            a_out <= {DATA_W{1'b0}};
            a_out_valid <= 1'b0;
            b_out <= {DATA_W{1'b0}};
            b_out_valid <= 1'b0;
            
            out <= {ACC_W{1'b0}};
            out_valid <= 1'b0;
        end else begin
            
            // ========== Input Capture ==========
            // Capture a if valid and we're ready
            if (a_valid && a_ready && !have_a) begin
                a_reg  <= a;
                have_a <= 1'b1;
            end
            
            // Capture b if valid and we're ready
            if (b_valid && b_ready && !have_b) begin
                b_reg  <= b;
                have_b <= 1'b1;
            end
            
            // ========== MAC Computation & Forwarding ==========
            // When both operands are available, compute and forward
            if (have_a && have_b && a_out_ready && b_out_ready) begin
                // Perform MAC operation
                acc_reg <= acc_reg + mul_ext;
                
                // Forward a to right neighbor
                a_out <= a_reg;
                a_out_valid <= 1'b1;
                
                // Forward b to bottom neighbor
                b_out <= b_reg;
                b_out_valid <= 1'b1;
                
                // Mark both operands as consumed
                have_a <= 1'b0;
                have_b <= 1'b0;
                
                // Output the accumulated result
                if (!out_valid || out_ready) begin
                    out <= acc_reg + mul_ext;
                    out_valid <= 1'b1;
                end
            end
            
            // ========== Output Handshakes ==========
            // Clear a_out_valid when downstream accepts
            if (a_out_valid && a_out_ready) begin
                a_out_valid <= 1'b0;
            end
            
            // Clear b_out_valid when downstream accepts
            if (b_out_valid && b_out_ready) begin
                b_out_valid <= 1'b0;
            end
            
            // Clear out_valid when consumer accepts
            if (out_valid && out_ready) begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
