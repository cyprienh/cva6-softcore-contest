//INSA tout le module
module circular_buffer
#( 	
  parameter N = 6)
(
  input  logic        write,
  input  logic[31:0]  find_in,
  input  logic[31:0]  data_in,
  output logic        data_in_memory,
  input  logic[19:0]  read_index,
  output logic[31:0]  read_out,
  output logic[1:0]   led);

  logic[31:0] mem[2**N-1:0];
  integer wp;
  logic[2**N-1:0] data_vector;
  logic data_mem;
  
  genvar i;
  generate
      for (i=0; i < 2**N; i++) begin
          assign data_vector[i] = (mem[i] == find_in) ? 1'b1 : 1'b0;
      end
  endgenerate

  assign data_mem = (data_vector != 0) ? 1'b1 : 1'b0;
  assign data_in_memory = data_mem;
  assign led[0] = data_mem;
  assign read_out = mem[read_index];

  always_ff @(posedge write) 
  begin
      mem[wp] <= data_in;
      wp <= (wp+1) % (2**N);
      if (data_in[31:28] == 4'h8)
        led[1] <= 1'b1;
  end

endmodule
