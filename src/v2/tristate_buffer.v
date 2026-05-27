module tristate_buffer(a, b, enable);
    input a;
    input enable;
    output reg b;

    always @(enable or a) begin
        if (enable) begin
            b = a;
        end else begin
            b = 1'bz;
        end

    end

endmodule