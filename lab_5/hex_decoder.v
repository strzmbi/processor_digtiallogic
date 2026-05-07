module hex_decoder(binary, sevenSeg);

	input[3:0] binary;
	output reg[6:0]  sevenSeg; // MSB , LSB

	always @(binary) begin
		case (binary)
			4'b0000 : begin sevenSeg = 7'b1000000; end
			4'b0001 : begin sevenSeg = 7'b1111001; end
			4'b0010 : begin sevenSeg = 7'b0100100; end
			4'b0011 : begin sevenSeg = 7'b0110000; end
			4'b0100 : begin sevenSeg = 7'b0011001; end
			4'b0101 : begin sevenSeg = 7'b0010010; end
			4'b0110 : begin sevenSeg = 7'b0000011; end
			4'b0111 : begin sevenSeg = 7'b1111000; end
			4'b1000 : begin sevenSeg = 7'b0000000; end
			4'b1001 : begin sevenSeg = 7'b0011000; end
			default : begin sevenSeg = 7'b1000000; end
		endcase
	end
	
endmodule