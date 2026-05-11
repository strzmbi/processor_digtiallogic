module lab4_P3_instantiate(SW, LEDR, HEX0, HEX1);

    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1;

    // SW[3:0] = a, SW[7:4] = b, SW[8] = cin (optional)
    wire cout;
    wire [3:0] s;

    FA_4B fa_4b(
        .a(SW[3:0]),
        .b(SW[7:4]),
        .cin(1'b0),
        .cout(cout),
        .s(s)
    );

    assign LEDR[3:0] = s;
    assign LEDR[4]   = cout;
    assign LEDR[9:5] = 5'b00000;

endmodule