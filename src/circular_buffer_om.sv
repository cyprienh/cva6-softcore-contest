// INSA : circular buffer used to store the first and last 
module circular_buffer_om
#(
  parameter SIZE = 8)
(
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       rst_us,
  input  logic       en_write_i,
  input  logic[31:0] addr_first_i,
  input  logic[31:0] addr_last_i,
  input  logic[31:0] find_addr_i,
  output logic       addr_in_range_o,
  output logic[31:0] read_o,
  output logic[31:0] read2_o,
  input  logic       find_i,
  // DLK
  input logic[31:0] base_addr_i,
  output logic      read_overflow_o
  );

  logic[3:0] cursor;
  // Circular buffer per se
  logic[63:0] mem[SIZE-1:0];
  logic[SIZE-1:0] data_vector;

/******************************************************************************/
/*                                BUFFER DLK                                  */
/******************************************************************************/
  logic[31:0] closest_base_addr;

  always_comb begin : check_for_closest_base_addr
    closest_base_addr = {32{1'b1}};
    for (int j = 0; j < SIZE; j++) begin // Look for the closest (higher) start adress of intervals
      if ((mem[j][63:32] != {32{1'b0}}) && (mem[j][63:32] < closest_base_addr) && (mem[j][63:32] > addr_first_i)) begin
        closest_base_addr = mem[j][63:32];
      end
    end
    read_overflow_o = (start_addr_i > closest_base_address);
  end 
/******************************************************************************/

  genvar i;
  generate
    for (i=0; i < SIZE; i++) assign data_vector[i] = (find_addr_i inside {[mem[i][63:32]:mem[i][31:0]]}) ? 1'b1 : 1'b0;
  endgenerate
 
  assign addr_in_range_o = (data_vector != 8'b0) ? 1'b1 : 1'b0; //Par contre le 8'b0 c'est SIZE'b0 non?

  assign read_o = mem[cursor-1][63:32]; //first
  assign read2_o = mem[cursor-1][31:0]; //end

  // Writing data
  always_ff @(posedge clk_i or negedge rst_ni) : writing_data_ff 
  begin
    if (~rst_ni) begin
      // reset : fill the circular buffer with 0s
      for (integer i=0; i<SIZE; i++) mem[i] <=  64'b0;
      // place cursor to index 0
      cursor <= 0;
    end else if (en_write_i) begin
      // store both addresses in a 64 word
      mem[cursor] <= {addr_first_i, addr_last_i};
      // cursor is incremented and is 0 if the buffer is full
      cursor <= cursor + 1;
    end
  end
    
endmodule // circular_buffer_om
