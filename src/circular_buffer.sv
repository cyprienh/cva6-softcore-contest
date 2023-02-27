//INSA tout le module
module circular_buffer
#( 	
  parameter N = 6)
(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        write,
  input  logic[31:0]  find_in,
  input  logic[31:0]  data_in,
  output logic        data_in_memory,
  input  logic[19:0]  read_index,
  output logic[31:0]  read_out
);

  logic[31:0] mem[2**N-1:0];
  integer wp;
  logic[2**N-1:0] data_vector;
  logic data_mem;
  
  genvar i;
  generate
      for (i=0; i < 2**N; i++) assign data_vector[i] = (mem[i] == find_in);
  endgenerate

  assign data_in_memory = (data_vector != 0);
  assign read_out = mem[wp-1];

  integer j;
  always_ff @(posedge clk_i, negedge rst_ni) 
  begin
      if (~rst_ni) begin
		    wp <= 'b0;
        for (j=0; j<2**N; j=j+1) mem[j] <= 'b0;
      end else if (write) begin
        mem[wp] <= data_in;
        wp <= (wp+1) % (2**N);
      end
  end

endmodule
