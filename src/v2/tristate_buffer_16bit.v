module tristate_buffer_16bit(a, b, enable);
    input[15:0] a;
    input enable;
    output[15:0] b;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            tristate_buffer t(.a(a[i]), .b(b[i]), .enable(enable));
        end
    endgenerate

endmodule