module sreg(
	//Status Register Input
	input [15:0]  		difference,
	input 		  		clk,
	input		  		rst,
	input			  	write_e,
	
	//Status Register Output
	output reg [2:0]  	values);
	
/***************************************************************************
   Status Register Output Bits
 -------------------------------------------------------------------------
   LSB		GREATER
   BIT 2	LESS
   MSB		EQUAL	
 --------------------------------------------------------------------------*/

    always @(posedge clk or posedge rst) begin
		if (rst) begin
			values <= 16'd0;
		end else begin
			if (difference > 16'd0 && difference < 16'h8000) begin
				values <= 3'b001;
			end
			else if (difference > 16'h8000) begin
				values <= 3'b010;
			end
			else if (difference == 16'd0)   begin
				values <= 3'b100;
			end
		end
    end
	
endmodule
