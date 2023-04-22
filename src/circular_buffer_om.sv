/* 
  Authors: 
  - Emily Holmes <holmes@insa-toulouse.fr>
  - Cyprien Heusse <heusse@insa-toulouse.fr>
  - Maïlis Dy <mdy@insa-toulouse.fr>
  - Arthur Gautheron <gauthero@insa-toulouse.fr>
  INSA Toulouse
  Date: 17.04.2023
  Description: Circular buffer used to store the intervals of overflows
*/

module circular_buffer_om
#(
  parameter SIZE = 32)
(
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       en_write_i,
  input  logic[31:0] addr_first_i,
  input  logic[31:0] addr_last_i,
  input  logic[31:0] find_addr_i,
  output logic       addr_in_range_o,
  output logic       addr_is_first_o);

  logic[4:0] cursor;
  logic[63:0] mem[SIZE-1:0];
  logic[SIZE-1:0] data_vector;
  logic[SIZE-1:0] data_vector2;

  genvar i;
  generate
    for (i=0; i < SIZE; i++) begin
      assign data_vector[i] = (find_addr_i inside {[mem[i][63:32]:mem[i][31:0]]}) ? 1'b1 : 1'b0;
      assign data_vector2[i] = (find_addr_i == mem[i][63:32]) ? 1'b1 : 1'b0;  // && ~is_big_vec[i]
    end
  endgenerate

  assign addr_in_range_o = (data_vector != {SIZE{1'b0}}) ? 1'b1 : 1'b0;
  assign addr_is_first_o = (data_vector2 != {SIZE{1'b0}}) ? 1'b1 : 1'b0;

  // Writing data
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
    
endmodule // circular_buffer_om
