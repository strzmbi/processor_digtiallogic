module one_hot(
    output [7:0] out,   // Output of the counter
    input enable,       // enable for counter
    input instruction_reg,  // instruction input
    input clk,          // clock input
    input reset         // reset input
);

/***************************************************************************
   INTERNAL VARIABLES
 -------------------------------------------------------------------------*/
reg [7:0] out;  

always @ (posedge clk)
    if (reset) begin
        out <= 8'd0;
    end else if (enable) begin
        out <= instruction_reg;
end

endmodule  