module test_myPipeMIPS32;

    reg clk1, clk2;
    integer k;

    // Instantiate your module (with your own processor name!)
    myPipeMIPS32 mips(clk1, clk2);

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (25) begin
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end

    initial begin
        // Initialize registers with offset values
        for (k = 0; k < 32; k = k + 1)
            mips.Reg[k] = k + 7;

        // Program: Simple addition and halt
        mips.Mem[0] = 32'h28010003;  // ADDI R1, R0, 3
        mips.Mem[1] = 32'h28020004;  // ADDI R2, R0, 4
        mips.Mem[2] = 32'h28030005;  // ADDI R3, R0, 5
        mips.Mem[3] = 32'h00221800;  // ADD  R3, R1, R2
        mips.Mem[4] = 32'h00632000;  // ADD  R4, R3, R3
        mips.Mem[5] = 32'hfc000000;  // HLT

        // Reset processor state
        mips.HALTED = 0;
        mips.PC = 0;
        mips.TAKEN_BRANCH = 0;

        // Wait to finish execution
        #300;
        $display("================================");
        $display("Register Dump After Execution:");
        $display("R1 = %d", mips.Reg[1]);
        $display("R2 = %d", mips.Reg[2]);
        $display("R3 = %d", mips.Reg[3]);  // Should be R1 + R2 = 7
        $display("R4 = %d", mips.Reg[4]);  // Should be 2 * R3 = 14
        $display("================================");
    end

    initial begin
        $dumpfile("test_myPipeMIPS32.vcd");
        $dumpvars(0, test_myPipeMIPS32);
        #400 $finish;
    end

endmodule
