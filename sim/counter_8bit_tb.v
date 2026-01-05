//============================================================
// Testbench for 8-bit Up/Down Counter
// Verifies: Up count, Down count, Hold, Reset, Carry output
// Version: 4.0 - All control and check at negedge only
//============================================================

`timescale 1ns/1ps

module counter_8bit_tb;

    //------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------
    parameter CLK_PERIOD = 0.7;  // 1.43 GHz

    //------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------
    reg         Clk;
    reg         Reset;
    reg         E;
    reg         M;
    wire [7:0]  Q;
    wire        Cout;

    //------------------------------------------------------------
    // Test Variables
    //------------------------------------------------------------
    integer error_count;
    integer test_count;
    reg [7:0] saved_Q;

    //------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------
    counter_8bit DUT (
        .Clk    (Clk),
        .Reset  (Reset),
        .E      (E),
        .M      (M),
        .Q      (Q),
        .Cout   (Cout)
    );

    //------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------
    initial begin
        Clk = 0;
        forever #(CLK_PERIOD/2) Clk = ~Clk;
    end

    //------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------
    initial begin
        error_count = 0;
        test_count = 0;
        Reset = 1;
        E = 0;
        M = 1;
        
        $display("============================================================");
        $display("  COUNTER 8-BIT TESTBENCH v4.0");
        $display("  Clock Period: %0.2f ns", CLK_PERIOD);
        $display("============================================================");
        
        #(CLK_PERIOD * 3);
        
        //--------------------------------------------------------
        // TEST 1: Reset Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 1: Asynchronous Reset ---");
        
        Reset = 0;  // Assert reset
        #(CLK_PERIOD * 3);
        
        test_count = test_count + 1;
        if (Q !== 8'h00) begin
            $display("[FAIL] Reset: Q=%h (expected 00)", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Reset: Q=00");
        end
        
        Reset = 1;  // Deassert reset
        #(CLK_PERIOD * 2);
        
        //--------------------------------------------------------
        // TEST 2: Count Up Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 2: Count Up (E=1, M=1) ---");
        
        // Enable at negedge, count on next 5 posedges
        @(negedge Clk);
        E = 1;
        M = 1;
        $display("  Starting count up from Q=%h", Q);
        
        // Wait exactly 5 clock rising edges
        @(posedge Clk); // Q = 1
        @(posedge Clk); // Q = 2
        @(posedge Clk); // Q = 3
        @(posedge Clk); // Q = 4
        @(posedge Clk); // Q = 5
        
        // Check at negedge (after output settles)
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'h05) begin
            $display("[FAIL] Count Up: Q=%h (expected 05)", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Count Up: Q=05");
        end

        //--------------------------------------------------------
        // TEST 3: Hold Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 3: Hold (E=0) ---");
        
        // At this negedge, save Q and disable E
        saved_Q = Q;
        E = 0;
        $display("  Saved Q=%h, E disabled", saved_Q);
        
        // Wait 5 clock cycles (counter should NOT change)
        @(posedge Clk);
        @(posedge Clk);
        @(posedge Clk);
        @(posedge Clk);
        @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== saved_Q) begin
            $display("[FAIL] Hold: Q=%h (expected %h)", Q, saved_Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Hold: Q=%h maintained", Q);
        end
        
        //--------------------------------------------------------
        // TEST 4: Count Down Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 4: Count Down (E=1, M=0) ---");
        
        // Record current Q, enable down counting
        saved_Q = Q;
        E = 1;
        M = 0;
        $display("  Starting count down from Q=%h", saved_Q);
        
        // Wait exactly 3 clock rising edges
        @(posedge Clk); // Q = 4
        @(posedge Clk); // Q = 3
        @(posedge Clk); // Q = 2
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== (saved_Q - 8'h03)) begin
            $display("[FAIL] Count Down: Q=%h (expected %h)", Q, saved_Q - 8'h03);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Count Down: Q=%h (from %h)", Q, saved_Q);
        end

        //--------------------------------------------------------
        // TEST 5: Overflow and Carry Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 5: Overflow and Carry ---");
        
        // Reset to 0
        E = 0;
        Reset = 0;
        #(CLK_PERIOD * 2);
        Reset = 1;
        #(CLK_PERIOD);
        
        // Count up 253 times to reach 0xFD
        @(negedge Clk);
        E = 1;
        M = 1;
        
        repeat(253) @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'hFD) begin
            $display("[FAIL] Count to 0xFD: Q=%h", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Count to 0xFD: Q=%h", Q);
        end
        
        // One more count to 0xFE
        @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'hFE) begin
            $display("[FAIL] Count to 0xFE: Q=%h", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Count to 0xFE: Q=%h, Cout=%b", Q, Cout);
        end
        
        // One more count to 0xFF (overflow condition)
        @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'hFF) begin
            $display("[FAIL] At 0xFF: Q=%h", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] At 0xFF: Q=%h", Q);
        end
        
        test_count = test_count + 1;
        if (Cout !== 1'b1) begin
            $display("[FAIL] Cout at 0xFF: %b (expected 1)", Cout);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Cout=1 at overflow");
        end
        
        // One more count to wrap to 0x00
        @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'h00) begin
            $display("[FAIL] Wrap to 0x00: Q=%h", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Wrap to 0x00: Q=%h, Cout=%b", Q, Cout);
        end

        //--------------------------------------------------------
        // TEST 6: Underflow Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 6: Underflow ---");
        
        // Reset to 0
        E = 0;
        Reset = 0;
        #(CLK_PERIOD * 2);
        Reset = 1;
        #(CLK_PERIOD);
        
        // Count down from 0
        @(negedge Clk);
        E = 1;
        M = 0;
        
        @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'hFF) begin
            $display("[FAIL] Underflow: Q=%h (expected FF)", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Underflow: Q=FF");
        end

        //--------------------------------------------------------
        // SUMMARY
        //--------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("  TEST SUMMARY");
        $display("============================================================");
        $display("  Total: %0d  |  Passed: %0d  |  Failed: %0d", 
                 test_count, test_count - error_count, error_count);
        $display("============================================================");
        
        if (error_count == 0) begin
            $display("  *** ALL TESTS PASSED ***");
        end else begin
            $display("  *** SOME TESTS FAILED ***");
        end
        $display("============================================================");
        
        #100;
        $finish;
    end

    //------------------------------------------------------------
    // Waveform Dump
    //------------------------------------------------------------
    initial begin
        $dumpfile("counter_8bit_tb.vcd");
        $dumpvars(0, counter_8bit_tb);
    end

endmodule

