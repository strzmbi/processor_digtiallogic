module output_to_bus(
    input  [15:0] alu_data,
    input         alu_enable,

    input  [15:0] immediate_data,
    input         immediate_enable,

    input  [15:0] register_data,
    input         register_enable,

    input [15:0] memory_data,
    input         memory_enable,

    inout  [15:0] BUS
);

    /*
    -----------------------------------------------------------------------
    ALU OUTPUT
    -----------------------------------------------------------------------
    */

    tristate_buffer_16bit alu_bus_driver(
        .a(alu_data),
        .b(BUS),
        .enable(alu_enable)
    );

    /*
    -----------------------------------------------------------------------
    IMMEDIATE OUTPUT
    -----------------------------------------------------------------------
    */

    tristate_buffer_16bit immediate_bus_driver(
        .a(immediate_data),
        .b(BUS),
        .enable(immediate_enable)
    );

    /*
    -----------------------------------------------------------------------
    REGISTER FILE OUTPUT
    -----------------------------------------------------------------------
    */

    tristate_buffer_16bit register_bus_driver(
        .a(register_data),
        .b(BUS),
        .enable(register_enable)
    );

    /*
    -----------------------------------------------------------------------
    RAM OUTPUT
    -----------------------------------------------------------------------
    */

    tristate_buffer_16bit memory_bus_driver(
        .a(memory_data),
        .b(BUS),
        .enable(memory_enable)
    );

    wire [3:0] driver_count;

    assign driver_count =
        alu_enable +
        immediate_enable +
        register_enable;

    always @(*) begin
        if (driver_count > 1)
            $display("BUS CONTENTION t=%0t", $time);
    end

endmodule