module ram (
    input  [4:0]  address,
    input  [15:0] data_in,

    output reg [15:0] data_out,

    input chip_sel,
    input write_en,
    input read_en
);

    /*
    -----------------------------------------------------------------------
    MEMORY ARRAY
    -----------------------------------------------------------------------
    */

    reg [15:0] mem [0:31];

    /*
    -----------------------------------------------------------------------
    MEMORY WRITE
    -----------------------------------------------------------------------
    */

    always @(*) begin
        if (chip_sel && write_en)
            mem[address] = data_in;
    end

    /*
    -----------------------------------------------------------------------
    MEMORY READ
    -----------------------------------------------------------------------
    */

    always @(*) begin
        if (chip_sel && read_en && !write_en)
            data_out = mem[address];
        else
            data_out = 16'b0;
    end

endmodule