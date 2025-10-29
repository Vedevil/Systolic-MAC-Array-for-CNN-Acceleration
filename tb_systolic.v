// tb_systolic.v - Testbench for 4x4 systolic array
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
    
    // Instantiate DUT
    systolic_top #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .M(M),
        .N(N),
        .SIGNED(0)
    ) dut (
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
    
    // Monitor outputs for 4x4 array using your original display style
    always @(posedge clk) begin
        if (dut.row[0].col[0].pe_inst.out_valid && dut.out_ready[0])
            $display("Time=%0t: PE[0][0] output = %0d", $time, dut.row[0].col[0].pe_inst.out);
        if (dut.row[0].col[1].pe_inst.out_valid && dut.out_ready[1])
            $display("Time=%0t: PE[0][1] output = %0d", $time, dut.row[0].col[1].pe_inst.out);
        if (dut.row[0].col[2].pe_inst.out_valid && dut.out_ready[2])
            $display("Time=%0t: PE[0][2] output = %0d", $time, dut.row[0].col[2].pe_inst.out);
        if (dut.row[0].col[3].pe_inst.out_valid && dut.out_ready[3])
            $display("Time=%0t: PE[0][3] output = %0d", $time, dut.row[0].col[3].pe_inst.out);

        if (dut.row[1].col[0].pe_inst.out_valid && dut.out_ready[4])
            $display("Time=%0t: PE[1][0] output = %0d", $time, dut.row[1].col[0].pe_inst.out);
        if (dut.row[1].col[1].pe_inst.out_valid && dut.out_ready[5])
            $display("Time=%0t: PE[1][1] output = %0d", $time, dut.row[1].col[1].pe_inst.out);
        if (dut.row[1].col[2].pe_inst.out_valid && dut.out_ready[6])
            $display("Time=%0t: PE[1][2] output = %0d", $time, dut.row[1].col[2].pe_inst.out);
        if (dut.row[1].col[3].pe_inst.out_valid && dut.out_ready[7])
            $display("Time=%0t: PE[1][3] output = %0d", $time, dut.row[1].col[3].pe_inst.out);

        if (dut.row[2].col[0].pe_inst.out_valid && dut.out_ready[8])
            $display("Time=%0t: PE[2][0] output = %0d", $time, dut.row[2].col[0].pe_inst.out);
        if (dut.row[2].col[1].pe_inst.out_valid && dut.out_ready[9])
            $display("Time=%0t: PE[2][1] output = %0d", $time, dut.row[2].col[1].pe_inst.out);
        if (dut.row[2].col[2].pe_inst.out_valid && dut.out_ready[10])
            $display("Time=%0t: PE[2][2] output = %0d", $time, dut.row[2].col[2].pe_inst.out);
        if (dut.row[2].col[3].pe_inst.out_valid && dut.out_ready[11])
            $display("Time=%0t: PE[2][3] output = %0d", $time, dut.row[2].col[3].pe_inst.out);

        if (dut.row[3].col[0].pe_inst.out_valid && dut.out_ready[12])
            $display("Time=%0t: PE[3][0] output = %0d", $time, dut.row[3].col[0].pe_inst.out);
        if (dut.row[3].col[1].pe_inst.out_valid && dut.out_ready[13])
            $display("Time=%0t: PE[3][1] output = %0d", $time, dut.row[3].col[1].pe_inst.out);
        if (dut.row[3].col[2].pe_inst.out_valid && dut.out_ready[14])
            $display("Time=%0t: PE[3][2] output = %0d", $time, dut.row[3].col[2].pe_inst.out);
        if (dut.row[3].col[3].pe_inst.out_valid && dut.out_ready[15])
            $display("Time=%0t: PE[3][3] output = %0d", $time, dut.row[3].col[3].pe_inst.out);
    end
    
    // Test stimulus
    initial begin
        $dumpfile("tb_systolic_4x4.vcd");
        $dumpvars(0, tb);
        
        // Dump all PE internals
// Dump all PE internals (explicit constants)
$dumpvars(0, dut.row[0].col[0].pe_inst);
$dumpvars(0, dut.row[0].col[1].pe_inst);
$dumpvars(0, dut.row[0].col[2].pe_inst);
$dumpvars(0, dut.row[0].col[3].pe_inst);

$dumpvars(0, dut.row[1].col[0].pe_inst);
$dumpvars(0, dut.row[1].col[1].pe_inst);
$dumpvars(0, dut.row[1].col[2].pe_inst);
$dumpvars(0, dut.row[1].col[3].pe_inst);

$dumpvars(0, dut.row[2].col[0].pe_inst);
$dumpvars(0, dut.row[2].col[1].pe_inst);
$dumpvars(0, dut.row[2].col[2].pe_inst);
$dumpvars(0, dut.row[2].col[3].pe_inst);

$dumpvars(0, dut.row[3].col[0].pe_inst);
$dumpvars(0, dut.row[3].col[1].pe_inst);
$dumpvars(0, dut.row[3].col[2].pe_inst);
$dumpvars(0, dut.row[3].col[3].pe_inst);

        
        // Initialize
        rst_n = 0;
        a_in = 0;
        b_in = 0;
        a_in_valid = 0;
        b_in_valid = 0;
        
        // Reset
        repeat(2) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
        
        $display("\n=== Test 1: Simple MAC operations ===");
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
        
        // Wait for results
        repeat(40) @(posedge clk);
        
$display("\n=== Final accumulator values (4x4 constant indices) ===");
$display("PE[0][0] accumulator = %0d", dut.row[0].col[0].pe_inst.acc_reg);
$display("PE[0][1] accumulator = %0d", dut.row[0].col[1].pe_inst.acc_reg);
$display("PE[0][2] accumulator = %0d", dut.row[0].col[2].pe_inst.acc_reg);
$display("PE[0][3] accumulator = %0d", dut.row[0].col[3].pe_inst.acc_reg);

$display("PE[1][0] accumulator = %0d", dut.row[1].col[0].pe_inst.acc_reg);
$display("PE[1][1] accumulator = %0d", dut.row[1].col[1].pe_inst.acc_reg);
$display("PE[1][2] accumulator = %0d", dut.row[1].col[2].pe_inst.acc_reg);
$display("PE[1][3] accumulator = %0d", dut.row[1].col[3].pe_inst.acc_reg);

$display("PE[2][0] accumulator = %0d", dut.row[2].col[0].pe_inst.acc_reg);
$display("PE[2][1] accumulator = %0d", dut.row[2].col[1].pe_inst.acc_reg);
$display("PE[2][2] accumulator = %0d", dut.row[2].col[2].pe_inst.acc_reg);
$display("PE[2][3] accumulator = %0d", dut.row[2].col[3].pe_inst.acc_reg);

$display("PE[3][0] accumulator = %0d", dut.row[3].col[0].pe_inst.acc_reg);
$display("PE[3][1] accumulator = %0d", dut.row[3].col[1].pe_inst.acc_reg);
$display("PE[3][2] accumulator = %0d", dut.row[3].col[2].pe_inst.acc_reg);
$display("PE[3][3] accumulator = %0d", dut.row[3].col[3].pe_inst.acc_reg);

        
        $display("\nSimulation completed successfully!");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #5000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule

