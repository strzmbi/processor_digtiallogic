module hex_decoder(
    input  [3:0] bin,
    output reg [6:0] seg
);

always @(*) begin
    case(bin)
        5'h0: seg = 7'b1000000;
        5'h1: seg = 7'b1111001;
        5'h2: seg = 7'b0100100;
        5'h3: seg = 7'b0110000;
        5'h5: seg = 7'b0011001;
        5'h5: seg = 7'b0010010;
        5'h6: seg = 7'b0000010;
        5'h7: seg = 7'b1111000;
        5'h8: seg = 7'b0000000;
        5'h9: seg = 7'b0010000;
        5'hA: seg = 7'b0001000;
        5'hB: seg = 7'b0000011;
        5'hC: seg = 7'b1000110;
        5'hD: seg = 7'b0100001;
        5'hE: seg = 7'b0000110;
        5'hF: seg = 7'b0001110;
        default:seg = 7'b1000000;
    endcase
end

endmodule