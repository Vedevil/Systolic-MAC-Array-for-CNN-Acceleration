// tb_systolic_gls.v - Gate-Level Simulation Testbench for 4x4 systolic array
`timescale 1ns/1ps

module tb;
    parameter DATA_W = 8;
    parameter ACC_W  = 32;
    parameter M = 4;
    parameter N = 4;
    
    reg clk = 0;
    reg rst_n = 0;
    
    // Input streams
    reg [DATA_W-1:0] a_in;
    reg a_in_valid;
    wire a_in_ready;
    
    reg [DATA_W-1:0] b_in;
    reg b_in_valid;
    wire b_in_ready;
    
    integer i;
    
    // Instantiate DUT (no parameters for gate-level netlist)
    systolic_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_in),
        .a_in_valid(a_in_valid),
        .a_in_ready(a_in_ready),
        .b_in(b_in),
        .b_in_valid(b_in_valid),
        .b_in_ready(b_in_ready)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Monitor PE[0][0] output continuously to see when it changes
    always @(posedge clk) begin
        if (dut.\row[0].col[0].pe_inst .out_valid)
            $display("Time=%0t: PE[0][0] output = %0d", $time, dut.\row[0].col[0].pe_inst .out);
    end
    
    // Test stimulus
    initial begin
        $dumpfile("tb_systolic_4x4_gls.vcd");
        $dumpvars(0, tb);
        
        // Initialize
        rst_n = 0;
        a_in = 0;
        b_in = 0;
        a_in_valid = 0;
        b_in_valid = 0;
        
        // Reset - longer reset for gate-level
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        $display("\n=== Test 1: Simple MAC operations (GLS) ===");
        $display("Sending pairs of (a,b) values to all PEs");
        
        // Send a few pairs of values
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            #1;
            a_in = 2 + i;
            b_in = 3 + i;
            a_in_valid = 1;
            b_in_valid = 1;
            $display("Time=%0t: Sending a=%0d, b=%0d", $time, a_in, b_in);
        end
        
        @(posedge clk);
        #1;
        a_in_valid = 0;
        b_in_valid = 0;
        
        // Wait longer for gate-level simulation (more delays)
        $display("\nWaiting for computation...");
        repeat(200) @(posedge clk);
        
        // Sample after settling
        @(posedge clk);
        #2;  // Wait after clock edge for signals to settle
        
        $display("\n=== Final accumulator values (4x4 constant indices) ===");
        $display("PE[0][0] accumulator = %0d", dut.\row[0].col[0].pe_inst .acc_reg);
        $display("PE[0][1] accumulator = %0d", dut.\row[0].col[1].pe_inst .acc_reg);
        $display("PE[0][2] accumulator = %0d", dut.\row[0].col[2].pe_inst .acc_reg);
        $display("PE[0][3] accumulator = %0d", dut.\row[0].col[3].pe_inst .acc_reg);
        
        $display("PE[1][0] accumulator = %0d", dut.\row[1].col[0].pe_inst .acc_reg);
        $display("PE[1][1] accumulator = %0d", dut.\row[1].col[1].pe_inst .acc_reg);
        $display("PE[1][2] accumulator = %0d", dut.\row[1].col[2].pe_inst .acc_reg);
        $display("PE[1][3] accumulator = %0d", dut.\row[1].col[3].pe_inst .acc_reg);
        
        $display("PE[2][0] accumulator = %0d", dut.\row[2].col[0].pe_inst .acc_reg);
        $display("PE[2][1] accumulator = %0d", dut.\row[2].col[1].pe_inst .acc_reg);
        $display("PE[2][2] accumulator = %0d", dut.\row[2].col[2].pe_inst .acc_reg);
        $display("PE[2][3] accumulator = %0d", dut.\row[2].col[3].pe_inst .acc_reg);
        
        $display("PE[3][0] accumulator = %0d", dut.\row[3].col[0].pe_inst .acc_reg);
        $display("PE[3][1] accumulator = %0d", dut.\row[3].col[1].pe_inst .acc_reg);
        $display("PE[3][2] accumulator = %0d", dut.\row[3].col[2].pe_inst .acc_reg);
        $display("PE[3][3] accumulator = %0d", dut.\row[3].col[3].pe_inst .acc_reg);
        
        $display("\n=== Output Matrix Values (Top-level signals) ===");
        $display("out_matrix[0]  = %0d", dut.\out_matrix[0] );
        $display("out_matrix[1]  = %0d", dut.\out_matrix[1] );
        $display("out_matrix[2]  = %0d", dut.\out_matrix[2] );
        $display("out_matrix[3]  = %0d", dut.\out_matrix[3] );
        $display("out_matrix[4]  = %0d", dut.\out_matrix[4] );
        $display("out_matrix[5]  = %0d", dut.\out_matrix[5] );
        $display("out_matrix[6]  = %0d", dut.\out_matrix[6] );
        $display("out_matrix[7]  = %0d", dut.\out_matrix[7] );
        $display("out_matrix[8]  = %0d", dut.\out_matrix[8] );
        $display("out_matrix[9]  = %0d", dut.\out_matrix[9] );
        $display("out_matrix[10] = %0d", dut.\out_matrix[10] );
        $display("out_matrix[11] = %0d", dut.\out_matrix[11] );
        $display("out_matrix[12] = %0d", dut.\out_matrix[12] );
        $display("out_matrix[13] = %0d", dut.\out_matrix[13] );
        $display("out_matrix[14] = %0d", dut.\out_matrix[14] );
        $display("out_matrix[15] = %0d", dut.\out_matrix[15] );
        
        $display("\nSimulation completed successfully!");
        
        // Compare with expected RTL values
        $display("\n=== Expected values from RTL sim ===");
        $display("PE[0][0] should be 68, PE[0][1] should be 34");
        $display("PE[1][0] should be 36, PE[1][1] should be 48");
        $display("Most others should be 6");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
