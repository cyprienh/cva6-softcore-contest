/* 
  Authors: 
  - Emily Holmes <holmes@insa-toulouse.fr>
  - Cyprien Heusse <heusse@insa-toulouse.fr>
  - Maïlis Dy <mdy@insa-toulouse.fr>
  - Arthur Gautheron <gauthero@insa-toulouse.fr>
  INSA Toulouse
  Date: 17.04.2023
  Description: Circular buffer to store overflow intervals
  Intervals are stored in 64-bit vectors, with indexes [64:32] for the first address
                                                       [31:0]  for the last address 
  When buffer is full, write over oldest entry (LIFO)
*/

module circular_buffer
#(
  parameter SIZE = 32)                  // buffer holds SIZE intervals
(
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       en_write_i,        // enable write
  input  logic[31:0] addr_first_i,      // first address of overflow interval
  input  logic[31:0] addr_last_i,       // last address of overflow interval
  input  logic[31:0] current_addr_i,    // address to compare to intervals
  output logic       addr_in_range_o,   // is the address located in one of the intervals? 
  output logic       addr_is_first_o    // is the address the first one of an interval?
);

  logic[4:0] cursor;
  logic[63:0] mem[SIZE-1:0];
  logic[SIZE-1:0] addr_in_buffer;
  logic[SIZE-1:0] addr_first_in_interval;

  genvar i;
  generate
    for (i=0; i < SIZE; i++) begin
      assign addr_in_buffer[i] = (current_addr_i inside {[mem[i][63:32]:mem[i][31:0]]}) ? 1'b1 : 1'b0;
      assign addr_first_in_interval[i] = (current_addr_i == mem[i][63:32]) ? 1'b1 : 1'b0;  
    end
  endgenerate

  assign addr_in_range_o = (addr_in_buffer != {SIZE{1'b0}}) ? 1'b1 : 1'b0;       // set to 1 if the address was found in one of the intervals
  assign addr_is_first_o = (addr_first_in_interval != {SIZE{1'b0}}) ? 1'b1 : 1'b0; // set to 1 if the address was found in one of the intervals

  // Writing data synchronous with clock edge
  always_ff @(posedge clk_i or negedge rst_ni) 
  begin
    if(~rst_ni) begin
      for (integer i=0; i<SIZE; i++) mem[i] <=  64'b0;
      cursor <= 0;
    end else if (en_write_i) begin
      mem[cursor] <= {addr_first_i, addr_last_i};
      cursor <= cursor + 1;
    end
  end
    
endmodule // circular_buffer
