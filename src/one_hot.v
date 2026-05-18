module one_hot(
    output reg [4:0] out,   // Output of the counter
    input enable,       // enable for counter
    input [4:0] instruction_reg,  // instruction input
    input clk,          // clock input
    input reset         // reset input
);

/***************************************************************************
   INTERNAL VARIABLES
 -------------------------------------------------------------------------*/

always @ (posedge clk or posedge reset)
    if (reset) begin
        out <= 5'd0;
    end else if (enable) begin
        out <= 5'b00001 << instruction_reg;
end

endmodule  