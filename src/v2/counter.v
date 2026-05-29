module counter(
    input CLOCK,
    input reset,
    output reg pulse
);

reg [25:0] data;

initial begin
    data = 26'd0;
    pulse = 1'b0;
end

always @(posedge CLOCK) begin

    if (reset) begin
        data  <= 26'd0;
        pulse <= 1'b0;
    end

    else if (data == 26'd49_000_000) begin
        data  <= 26'd0;
        pulse <= 1'b1;
    end

    else begin
        data  <= data + 1'b1;
        pulse <= 1'b0;
    end
end

endmodule