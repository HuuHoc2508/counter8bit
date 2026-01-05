//============================================================
// 8-bit Up/Down Counter
// Author: ASIC Training
// Features:
//   - 8-bit output (Q)
//   - Up/Down counting (M: 1=up, 0=down)
//   - Asynchronous active-low reset (Reset)
//   - Enable control (E: 1=count, 0=hold)
//   - Carry output (Cout)
// Design: Fully synchronous logic
//============================================================

module counter_8bit (
    input  wire        Clk,      // Clock input
    input  wire        Reset,    // Asynchronous reset (active low)
    input  wire        E,        // Enable (1=count, 0=hold)
    input  wire        M,        // Mode/Direction (1=up, 0=down)
    output reg  [7:0]  Q,        // 8-bit counter output
    output wire        Cout      // Carry out (overflow when counting up)
);

    //------------------------------------------------------------
    // Carry logic (combinational)
    //------------------------------------------------------------
    // Cout serves as overflow indicator when counting up
    assign Cout = (Q == 8'hFF) & E & M;

    //------------------------------------------------------------
    // Counter logic
    //------------------------------------------------------------
    always @(posedge Clk or negedge Reset) begin
        if (!Reset) begin
            // Asynchronous reset - clear counter
            Q <= 8'h00;
        end
        else if (E) begin
            // Count enabled
            if (M) begin
                // Count up (M=1)
                Q <= Q + 8'h01;
            end
            else begin
                // Count down (M=0)
                Q <= Q - 8'h01;
            end
        end
        // else: E=0, hold voltage
    end

endmodule
