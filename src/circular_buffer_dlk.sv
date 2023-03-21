// TODO: change 32s into RISCV len constant

// INSA : circular buffer that stores the first adress of data blocks in memory
module circular_buffer_dlk
#(
  parameter SIZE = 32) //FIXME: A voir...
(
  input  logic       clk_i,
  input  logic       rst_ni,
  //input  logic       rst_us,          // Reset custom for debug instructions
  input  logic       en_write_i,      // Write base address in memory
  input  logic[31:0] base_addr_i,     // Base address to write or read into the buffer
  input  logic[31:0] read_addr_i,     // Actual read address
  output logic       read_overflow_o, // If we read over an address already in the buffer
  output logic[31:0] read_o
  );

  logic[4:0] cursor; // FIXME: TO CHANGE IF SIZE CHANGES
  // Circular buffer per se
  logic[31:0] mem[SIZE-1:0];

  logic[31:0] closest_base_address;
  logic[SIZE-1:0] addr_already_in_mem;

  
  assign read_o = mem[cursor-1]; // debug si jamais :D

  generate // check for address in memory
    for (genvar i = 0; i < SIZE; i++) begin
      assign addr_already_in_mem[i] = (base_addr_i == mem[i]);
    end
  endgenerate

  always_comb begin
    //case pas de closest base addr?
    //if lecture à rajouter pour opti
    closest_base_address = {32{1'b1}};
    for (int j = 0; j < SIZE; j++) begin // Look for the closest (higher) base_adress
      if ((mem[j] != {32{1'b0}}) && (mem[j] < closest_base_address) && (mem[j] > base_addr_i)) begin
        closest_base_address = mem[j];
      end
    end 
    read_overflow_o = (read_addr_i > closest_base_address);
  end

  // Writing data
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      // reset : fill the circular buffer with 0s
      for (integer i = 0; i < SIZE; i++) begin
        mem[i] <= {32{1'b0}};
      end
      // place cursor to index 0
      cursor <= 0;
    end else if (en_write_i && (addr_already_in_mem == {32{1'b0}})) begin
      // store base address if it is not in memory
      mem[cursor] <= base_addr_i;
      // cursor is incremented and is 0 if the buffer is full
      cursor <= cursor + 1;
    end
  end
endmodule // circular_buffer_dlk
