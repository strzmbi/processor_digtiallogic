module ram_sp_ar_aw (
input [ADDR_WIDTH-1:0] address, // Address Input
inout [DATA_WIDTH-1:0]  data,   // Data bi-directional
input cs,                       // Chip Select
input we,                       // Write Enable/Read Enable
input oe                        // Output Enable
);         

/***************************************************************************
   INITAL STATEMENT
 -------------------------------------------------------------------------*/
parameter   DATA_WIDTH      = 8                 ;
parameter   ADDR_WIDTH      = 8                 ;
parameter   RAM_DEPTH       = 1 << ADDR_WIDTH   ;

/***************************************************************************
   INITAL STATEMENT
 -------------------------------------------------------------------------*/
reg     [DATA_WIDTH-1:0]        data_out            ;
reg     [DATA_WIDTH-1:0]        mem [0:RAM_DEPTH-1] ;

/***************************************************************************
   TRI-STATE BUFFER CONTROL
   output : When we = 0, oe = 1, cs = 1
 -------------------------------------------------------------------------*/
assign data     = (cs && oe && !we)     ?   data_out    :   8'bz; 

/***************************************************************************
   MEMORY WRITE BLOCK
   Write Operation : When we = 1, cs = 1
 -------------------------------------------------------------------------*/
always @ (address or data or cs or we)
begin : MEM_WRITE
   if ( cs && we ) begin
       mem[address] = data;
   end
end

/***************************************************************************
   MEMORY READ BLOCK
   Read Operation : When we = 0, oe = 1, cs = 1
 -------------------------------------------------------------------------*/
always @ (address or cs or we or oe)
begin : MEM_READ
    if (cs && !we && oe)  begin
         data_out = mem[address];
    end
end

endmodule