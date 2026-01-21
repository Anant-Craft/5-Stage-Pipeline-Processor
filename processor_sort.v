module tb;

    reg clk1, clk2;

    // ---------------- CLOCK GENERATION ----------------
    initial begin 
        clk1 = 1'b0;
        clk2 = 1'b0;
    end

    // Two-phase clock: clk1 leads, clk2 follows
    always begin
        #5 clk1 = 1'b1; #5 clk1 = 1'b0;
        #5 clk2 = 1'b1; #5 clk2 = 1'b0;
    end

    // ---------------- DUT INSTANTIATION ----------------
    myPipeMIPS32 dut (clk1, clk2);

    // ---------------- INITIALIZATION & PROGRAM ----------------
    initial begin
        // Reset Control Signals
        dut.HALTED = 0;
        dut.TAKEN_BRANCH = 0;
        dut.PC = 0;

        // -------- DATA INITIALIZATION (Mem[100] to Mem[119]) --------
        // Initializing with a descending sequence to test worst-case sorting
        dut.Mem[100] = 20; dut.Mem[101] = 19; dut.Mem[102] = 18; dut.Mem[103] = 17;
        dut.Mem[104] = 16; dut.Mem[105] = 15; dut.Mem[106] = 14; dut.Mem[107] = 13;
        dut.Mem[108] = 12; dut.Mem[109] = 11; dut.Mem[110] = 10; dut.Mem[111] = 9;
        dut.Mem[112] = 8;  dut.Mem[113] = 7;  dut.Mem[114] = 6;  dut.Mem[115] = 5;
        dut.Mem[116] = 4;  dut.Mem[117] = 3;  dut.Mem[118] = 2;  dut.Mem[119] = 1;

        // -------- MACHINE CODE PROGRAM --------
        // Note: 3 NOPs (0x0C000000 or 0x0) are required between a 
        // destination register write and a source register read.

        // [0-3] Setup: R7 = 20 (Size), R3 = 100 (Base Address)
        dut.Mem[0]  = 32'h28070014; // ADDI R7, R0, 20
        dut.Mem[1]  = 32'h28030064; // ADDI R3, R0, 100
        dut.Mem[2]  = 32'h00000000; // NOP
        dut.Mem[3]  = 32'h00000000; // NOP

        // [4-7] Outer Loop Init: R1 = 0
        dut.Mem[4]  = 32'h28210000; // ADDI R1, R0, 0   <-- OUTER_LOOP_START
        dut.Mem[5]  = 32'h00000000; // NOP
        dut.Mem[6]  = 32'h00000000; // NOP
        dut.Mem[7]  = 32'h00000000; // NOP

        // [8-11] Inner Loop Init: R2 = 0
        dut.Mem[8]  = 32'h28020000; // ADDI R2, R0, 0   <-- INNER_LOOP_START
        dut.Mem[9]  = 32'h00000000; // NOP
        dut.Mem[10] = 32'h00000000; // NOP
        dut.Mem[11] = 32'h00000000; // NOP

        // [12-15] Calculate Address: R10 = Base + j
        dut.Mem[12] = 32'h00625000; // ADD  R10, R3, R2
        dut.Mem[13] = 32'h00000000; // NOP
        dut.Mem[14] = 32'h00000000; // NOP
        dut.Mem[15] = 32'h00000000; // NOP

        // [16-20] Load elements: R5 = Mem[j], R6 = Mem[j+1]
        dut.Mem[16] = 32'h21450000; // LW   R5, 0(R10)
        dut.Mem[17] = 32'h21460001; // LW   R6, 1(R10)
        dut.Mem[18] = 32'h00000000; // NOP
        dut.Mem[19] = 32'h00000000; // NOP
        dut.Mem[20] = 32'h00000000; // NOP

        // [21-24] Comparison: R9 = (R6 < R5)
        dut.Mem[21] = 32'h10C54800; // SLT  R9, R6, R5
        dut.Mem[22] = 32'h00000000; // NOP
        dut.Mem[23] = 32'h00000000; // NOP
        dut.Mem[24] = 32'h00000000; // NOP

        // [25-26] Branch if No Swap needed: if R9==0 skip to [30]
        // Offset: Target(30) - NPC(26) = 4
        dut.Mem[25] = 32'h39200004; // BEQZ R9, 4
        dut.Mem[26] = 32'h00000000; // NOP (Branch Delay Slot)

        // [27-29] Swap Elements
        dut.Mem[27] = 32'h15460000; // SW   R6, 0(R10)
        dut.Mem[28] = 32'h15450001; // SW   R5, 1(R10)
        dut.Mem[29] = 32'h00000000; // NOP

        // [30-33] Increment Inner Loop: j = j + 1
        dut.Mem[30] = 32'h28420001; // ADDI R2, R2, 1
        dut.Mem[31] = 32'h00000000; // NOP
        dut.Mem[32] = 32'h00000000; // NOP
        dut.Mem[33] = 32'h00000000; // NOP

        // [34-37] Check Inner Loop Condition: R9 = (20 - 1 - j)
        // For simplicity, we compare j against (Size - 1)
        dut.Mem[34] = 32'h28E9FFFF; // ADDI R9, R7, -1 (R9 = 19)
        dut.Mem[35] = 32'h00000000; // NOP
        dut.Mem[36] = 32'h04494800; // SUB  R9, R9, R2 (R9 = 19 - j)
        dut.Mem[37] = 32'h00000000; // NOP

        // [38-39] Inner Loop Branch: if R9 != 0 back to [12]
        // Offset: Target(12) - NPC(39) = -27 (0xFFE5)
        dut.Mem[38] = 32'h3520FFE5; // BNEQZ R9, -27
        dut.Mem[39] = 32'h00000000; // NOP (Branch Delay Slot)

        // [40-43] Increment Outer Loop: i = i + 1
        dut.Mem[40] = 32'h28210001; // ADDI R1, R1, 1
        dut.Mem[41] = 32'h00000000; // NOP
        dut.Mem[42] = 32'h00000000; // NOP
        dut.Mem[43] = 32'h00000000; // NOP

        // [44-47] Check Outer Loop Condition: R9 = (20 - i)
        dut.Mem[44] = 32'h04274800; // SUB  R9, R7, R1
        dut.Mem[45] = 32'h00000000; // NOP
        dut.Mem[46] = 32'h00000000; // NOP
        dut.Mem[47] = 32'h00000000; // NOP

        // [48-49] Outer Loop Branch: if R9 != 0 back to [8]
        // Offset: Target(8) - NPC(49) = -41 (0xFFD7)
        dut.Mem[48] = 32'h3520FFD7; // BNEQZ R9, -41
        dut.Mem[49] = 32'h00000000; // NOP (Branch Delay Slot)

        // [50] Finish
        dut.Mem[50] = 32'hFC000000; // HLT
    end

    // ---------------- WAVEFORM & MONITORING ----------------
    initial begin 
        $dumpfile("bubble_sort.vcd");
        $dumpvars(0, dut);
    end

    initial begin
        // The sorting of 20 numbers takes thousands of cycles
        #500000; 
        if (!dut.HALTED) begin
            $display("Simulation Timed Out!");
            $finish;
        end
    end

    initial begin
        wait(dut.HALTED == 1);
        #100; // Final buffer
        $display("       BUBBLE SORT COMPLETED SUCCESSFULLY       ");
        for (integer i = 0; i < 4; i = i + 1) begin
            $display("Mem[%0d-%0d]: %3d %3d %3d %3d %3d", 
                100 + (i*5), 104 + (i*5),
                dut.Mem[100 + (i*5)], dut.Mem[101 + (i*5)], 
                dut.Mem[102 + (i*5)], dut.Mem[103 + (i*5)], 
                dut.Mem[104 + (i*5)]);
        end

        $display("========================================");
        $finish;
    end


endmodule

