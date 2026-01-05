//============================================================
// Post-Synthesis Gate-Level Testbench for 8-bit Counter
// Uses synthesized netlist with SDF timing back-annotation
// Version: 1.0
//============================================================

`timescale 1ns/1ps

module counter_8bit_gate_tb;

    //------------------------------------------------------------
    // Parameters - Use slower clock for gate-level (timing margin)
    //------------------------------------------------------------
    parameter CLK_PERIOD = 1.1;  // GHz (safe timing margin)

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
    // DUT Instantiation (Gate-level netlist)
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
    // SDF Annotation
    //------------------------------------------------------------
    initial begin
        // Annotate SDF timing (comment out if SDF not available)
        // $sdf_annotate("../dc/netlist/counter_8bit_NL.sdf", DUT);
        $display("[INFO] Gate-level simulation started");
        $display("[INFO] Clock Period: %0.2f ns", CLK_PERIOD);
    end

    //------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------
    initial begin
        Clk = 0;
        forever #(CLK_PERIOD/2) Clk = ~Clk;
    end

    //------------------------------------------------------------
    // Main Test Sequence (Simplified for gate-level)
    //------------------------------------------------------------
    initial begin
        error_count = 0;
        test_count = 0;
        Reset = 1;
        E = 0;
        M = 1;
        
        $display("============================================================");
        $display("  POST-SYNTHESIS GATE-LEVEL TESTBENCH");
        $display("  Clock: %0.2f ns (%0.2f GHz)", CLK_PERIOD, 1.0/CLK_PERIOD);
        $display("============================================================");
        
        #(CLK_PERIOD * 5);
        
        //--------------------------------------------------------
        // TEST 1: Reset Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 1: Asynchronous Reset ---");
        
        Reset = 0;
        #(CLK_PERIOD * 5);
        
        test_count = test_count + 1;
        if (Q !== 8'h00) begin
            $display("[FAIL] Reset: Q=%h", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Reset: Q=00");
        end
        
        Reset = 1;
        #(CLK_PERIOD * 3);
        
        //--------------------------------------------------------
        // TEST 2: Count Up Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 2: Count Up ---");
        
        @(negedge Clk);
        E = 1;
        M = 1;
        
        @(posedge Clk); @(posedge Clk); @(posedge Clk);
        @(posedge Clk); @(posedge Clk); @(posedge Clk);
        @(posedge Clk); @(posedge Clk); @(posedge Clk);
        @(posedge Clk);  // 10 counts
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'h0A) begin
            $display("[FAIL] Count Up 10: Q=%h (expected 0A)", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Count Up 10: Q=0A");
        end

        //--------------------------------------------------------
        // TEST 3: Hold Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 3: Hold ---");
        
        saved_Q = Q;
        E = 0;
        
        @(posedge Clk); @(posedge Clk); @(posedge Clk);
        @(posedge Clk); @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== saved_Q) begin
            $display("[FAIL] Hold: Q=%h (expected %h)", Q, saved_Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Hold: Q=%h", Q);
        end
        
        //--------------------------------------------------------
        // TEST 4: Count Down Test
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 4: Count Down ---");
        
        saved_Q = Q;
        E = 1;
        M = 0;
        
        @(posedge Clk); @(posedge Clk); @(posedge Clk);
        @(posedge Clk); @(posedge Clk);  // 5 counts down
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== (saved_Q - 8'h05)) begin
            $display("[FAIL] Count Down 5: Q=%h (expected %h)", Q, saved_Q - 8'h05);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Count Down 5: Q=%h", Q);
        end

        //--------------------------------------------------------
        // TEST 5: Full Cycle (256 counts wrap)
        //--------------------------------------------------------
        $display("");
        $display("--- TEST 5: Full Cycle Wrap ---");
        
        E = 0;
        Reset = 0;
        #(CLK_PERIOD * 3);
        Reset = 1;
        #(CLK_PERIOD * 2);
        
        @(negedge Clk);
        E = 1;
        M = 1;
        
        // Count 256 times to wrap back to 0
        repeat(256) @(posedge Clk);
        @(negedge Clk);
        
        test_count = test_count + 1;
        if (Q !== 8'h00) begin
            $display("[FAIL] Full Cycle: Q=%h (expected 00)", Q);
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Full Cycle Wrap: Q=00");
        end

        //--------------------------------------------------------
        // SUMMARY
        //--------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("  GATE-LEVEL TEST SUMMARY");
        $display("============================================================");
        $display("  Total: %0d  |  Passed: %0d  |  Failed: %0d", 
                 test_count, test_count - error_count, error_count);
        $display("============================================================");
        
        if (error_count == 0) begin
            $display("  *** ALL GATE-LEVEL TESTS PASSED ***");
            $display("  Netlist functionally verified!");
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
        $dumpfile("counter_8bit_gate_tb.vcd");
        $dumpvars(0, counter_8bit_gate_tb);
    end

endmodule


