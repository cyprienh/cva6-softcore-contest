/* 
  Authors: 
  - Emily Holmes <holmes@insa-toulouse.fr>
  - Cyprien Heusse <heusse@insa-toulouse.fr>
  - Maïlis Dy <mdy@insa-toulouse.fr>
  - Arthur Gautheron <gauthero@insa-toulouse.fr>
  INSA Toulouse
  Date: 17.04.2023
  Description: Buffer Overflow Protection (BOP) unit

  Store instructions of consecutive addresses with few instructions inbetween are stored in a
  circular buffer. 
  Future load and store instructions are compared to the entries in this buffer to ensure that
  no illegal operation (as defined by our hypotheses) are performed
*/

module bop_unit (
  input  logic                          clk_i,
  input  logic                          rst_ni,
  input  ariane_pkg::fu_data_t          fu_data_i,
  input  ariane_pkg::scoreboard_entry_t decoded_instr_i,
  input  logic                          en_crash_i,
  output logic                          bop_load_in_buffer_o,
  output logic                          illegal_double_dereference_o,
  output logic                          lb_crash
);
   
  // Parameters for interval detection
  parameter   bop_write_size = 16;    // minimum number consecutive stores required to create an interval
  parameter   bop_date_max = 6;       // maximum number of instructions required inbetween store instructions 
                                      // to remain in the same interval

  // Signals
  logic       buffer_write_d;         // write to circular buffer
  logic[31:0] bop_start_d;            // start addr of consecutive store instr
  logic[31:0] bop_end_d;              // end addr of consecutive store instr
  logic       bop_active_d;           // is bop unit currently tracking consecutive stores?
  logic       bop_load_in_buffer_d;   // is last load in the buffer?
  logic[31:0] bop_count_d;            // number of consecutive stores
  logic[31:0] bop_same_d;             // number of stores with identical value stored (used to detect memset)
  logic[3:0]  bop_date_d;             // number of instructions stince last store instr
  logic[6:0]  bop_last_reg_d;         // last register loaded to (used to detect double dereferencing)
  logic[31:0] bop_pc_d;               // pc
  logic[31:0] bop_last_data_d;        // value stored
  logic       illegal_double_dereference_d;         
  logic       crash_d;

  logic       buffer_write_q;
  logic[31:0] bop_start_q;
  logic[31:0] bop_end_q;
  logic       bop_active_q;
  logic       bop_load_in_buffer_q;
  logic[31:0] bop_count_q;
  logic[31:0] bop_same_q;
  logic[3:0]  bop_date_q;
  logic[6:0]  bop_last_reg_q;
  logic[31:0] bop_pc_q;
  logic[31:0] bop_last_data_q;
  logic       illegal_double_dereference_q;
  logic       crash_q;

  logic       addr_in_buffer;
  logic       addr_is_first;

  logic [riscv::VLEN-1:0]   vaddr_i;
  riscv::xlen_t             vaddr_xlen;
  assign vaddr_xlen = $unsigned($signed(fu_data_i.imm) + $signed(fu_data_i.operand_a));   // addr to load to/store to is the signed sum of operand a + an immediate
  assign vaddr_i = vaddr_xlen[riscv::VLEN-1:0];

  circular_buffer insa_buffer (
    .clk_i,
    .rst_ni,
    .en_write_i       (buffer_write_q),
    .addr_first_i     (bop_start_q),   
    .addr_last_i      (bop_end_q),    
    .current_addr_i   (vaddr_i),
    .addr_in_range_o  (addr_in_buffer),
    .addr_is_first_o  (addr_is_first)
  );

  assign bop_load_in_buffer_o = bop_load_in_buffer_q;
  // assign bop_load_in_buffer_o = 0;
  // assign illegal_double_dereference_o = illegal_double_dereference_q;
  assign illegal_double_dereference_o = 0;
  // assign lb_crash = 0;
  assign lb_crash = crash_q;

  always_comb begin : heap_safe
    buffer_write_d = 1'b0;

    bop_active_d = bop_active_q;
    bop_start_d = bop_start_q;
    bop_end_d = bop_end_q;
    bop_load_in_buffer_d = bop_load_in_buffer_q;
    bop_count_d = bop_count_q;
    bop_date_d = bop_date_q;
    bop_same_d = bop_same_q;
    
    bop_pc_d = bop_pc_q;
    bop_last_data_d = bop_last_data_q;

    bop_last_reg_d = bop_last_reg_q;
    illegal_double_dereference_d = illegal_double_dereference_q;

    crash_d = crash_q;

    // Detecting interactions with saved intervals
    if(decoded_instr_i.op == ariane_pkg::LW && decoded_instr_i.rs1 != 2) begin         // if load instruction doesn't use sp (stack pointer)
      if (addr_in_buffer) begin                                                        // if addr is in one of the intervals
        bop_load_in_buffer_d = 1'b1;
        bop_last_reg_d = decoded_instr_i.rd;                                           // memorize register used for double dereferencing
      end else if (decoded_instr_i.rs1 == bop_last_reg_q && bop_load_in_buffer_q) begin // detect double dereferencing of overwritten value
        illegal_double_dereference_d = 1'b1;
      end else begin                                                                   // legitimate load -> do nothing
        bop_load_in_buffer_d = 1'b0;
        bop_last_reg_d = 0;
      end
    end

    // Detecting and saving intervals
    if (bop_pc_q != decoded_instr_i.pc && en_crash_i) begin                            // ignore ignore stalls, only perform check if crash is enabled
      bop_pc_d = decoded_instr_i.pc;
      if(decoded_instr_i.op == ariane_pkg::SB) begin
        if(!(decoded_instr_i.rs1 inside {2, 8})) begin                                 // if store doesn't use sp or fp (memcpy and similar function) 
          bop_last_data_d = fu_data_i.operand_b;
          if(~bop_active_q) begin                                                      // start tracking interval
            bop_active_d = 1'b1;
            bop_start_d = vaddr_i;
            bop_end_d = vaddr_i;
            bop_date_d = bop_date_max;
            bop_count_d = 32'b1;
            bop_same_d = 32'b1;
          end else if(bop_end_q + 1 == vaddr_i) begin                                  // if storing to a consecutive address, increase interval size
            bop_end_d = vaddr_i;
            bop_count_d = bop_count_q + 1;
            bop_date_d = bop_date_max;     
            if(fu_data_i.operand_b == bop_last_data_q) begin                           // check if storing the same value as the last one
              bop_same_d = bop_same_q + 1; 
            end
          end else begin                                                               // store address is not consecutive -> end interval
            bop_active_d = 1'b0;
            if(bop_count_q > bop_write_size && bop_same_q < bop_count_q)               // add interval to buffer if interval is big enough and is not a memset
              buffer_write_d = 1'b1;
          end
        end
      end else begin
        if(bop_active_q) begin                                                         // if instr is not store, decrement date since last store
          if(bop_date_q != 0)
            bop_date_d = bop_date_q - 1;
          else begin                                                                   // if date = 0, interval timed out
            bop_active_d = 1'b0;
            if(bop_count_q > bop_write_size && bop_same_q < bop_count_q)               // add interval to buffer if interval is big enough and is not a memset
              buffer_write_d = 1'b1;
          end
        end
        // Detecting illegal copying of data
        if(decoded_instr_i.op == ariane_pkg::LB) begin
          if(addr_is_first && bop_count_q > 8) begin                                   // if starts reading saved interval from outside (before)      
            crash_d = 1'b1;
          end
        end
      end
    end 
  end

  // Flip-flops to keep values over multiple ticks
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      bop_active_q <= 1'b0;
      bop_start_q <= 32'b0;
      bop_end_q <= 32'b0;
      bop_load_in_buffer_q <= 1'b0;
      bop_count_q <= 32'b0;
      bop_date_q <= 4'b0;
      buffer_write_q <= 1'b0;
      bop_pc_q <= 32'b0;
      bop_last_reg_q <= 6'b0;
      illegal_double_dereference_q <= 1'b0;
      bop_last_data_q <= 32'b0;
      bop_same_q <= 32'b0;
      crash_q <= 1'b0;
    end else begin
      bop_active_q <= bop_active_d;
      bop_start_q <= bop_start_d;
      bop_end_q <= bop_end_d;
      bop_load_in_buffer_q <= bop_load_in_buffer_d;
      bop_count_q <= bop_count_d;
      bop_date_q <= bop_date_d;
      buffer_write_q <= buffer_write_d;
      bop_pc_q <= bop_pc_d;
      bop_last_reg_q <= bop_last_reg_d;
      illegal_double_dereference_q <= illegal_double_dereference_d;
      bop_last_data_q <= bop_last_data_d;
      bop_same_q <= bop_same_d;
      crash_q <= crash_d;
    end
  end

endmodule
