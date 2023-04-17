// Authors: Emily Holmes, Cyprien Heusse, Maïlis Dy, Arthur Gautheron, INSA Toulouse
// Date: 17.04.2023
// Description: Buffer overflow protection unit

module bop_unit (
    input  logic                      clk_i,
    input  logic                      rst_ni,
    input  ariane_pkg::fu_data_t      fu_data_i,
    input  ariane_pkg::scoreboard_entry_t         decoded_instr_i,

    output logic [31:0]                           alu_read_out,
    output logic [31:0]                           alu_read_out2,

    output logic       to_crash,
    output logic       data_in_buffer,
    output logic [6:0] load_reg,

    input logic       rst_buf_i,
    input logic       en_crash_i,

    output logic      illegal_load_o,
    output logic      lb_crash
);

    logic [riscv::VLEN-1:0]   vaddr_i;
    riscv::xlen_t             vaddr_xlen;
    
    // INSA: Registers for overflow management (heap)
    parameter   bof_write_size = 16;    // 200 -> crash -- 1000 -> pas crash -> 416 (5*message ?)
    parameter   bof_date_max = 6;

    logic[31:0] bof_start_d;
    logic[31:0] bof_end_d;
    logic       bof_active_d;
    logic       bof_load_in_range_d;
    logic[31:0] bof_count_d;
    logic[31:0] bof_same_d;
    logic[3:0]  bof_date_d;

    logic[31:0] bof_start_q;
    logic[31:0] bof_end_q;
    logic       bof_active_q;
    logic       bof_load_in_range_q;
    logic[31:0] bof_count_q;
    logic[31:0] bof_same_q;
    logic[3:0]  bof_date_q;

    logic[31:0] bof_pc_d;
    logic[31:0] bof_pc_q;
    
    logic       buffer_write_d;
    logic       buffer_write_q;
    logic       addr_in_buffer;
    logic       addr_is_first;

    logic[6:0] bof_last_reg_d;
    logic[6:0] bof_last_reg_q;

    logic[31:0]  bof_last_data_d;
    logic[31:0]  bof_last_data_q;

    logic       illegal_load_d;
    logic       illegal_load_q;

    logic crash_q;
    logic crash_d;
    logic is_big;

    assign vaddr_xlen = $unsigned($signed(fu_data_i.imm) + $signed(fu_data_i.operand_a));
    assign vaddr_i = vaddr_xlen[riscv::VLEN-1:0];

    assign illegal_load_o = illegal_load_q;
    assign lb_crash = crash_q;

    circular_buffer_om insa_buffer_om (
      .clk_i,
      .rst_ni,
      .rst_us           (rst_buf_i),
      .is_big_i         (is_big),
      .en_write_i       (buffer_write_q),
      .addr_first_i     (bof_start_q),   
      .addr_last_i      (bof_end_q),    
      .find_addr_i      (vaddr_i),
      .addr_in_range_o  (addr_in_buffer),
      .addr_is_first_o  (addr_is_first),
      .read_o           (alu_read_out),
      .read2_o          (alu_read_out2)
    );

    assign data_in_buffer = bof_active_q; //debug
    assign to_crash = bof_load_in_range_q;
    assign load_reg = bof_last_reg_q;

    assign is_big = (bof_count_q > 100) ? 1'b1 : 1'b0;

    always_comb begin : heap_safe
      buffer_write_d = 1'b0;

      bof_active_d = bof_active_q;
      bof_start_d = bof_start_q;
      bof_end_d = bof_end_q;
      bof_load_in_range_d = bof_load_in_range_q;
      bof_count_d = bof_count_q;
      bof_date_d = bof_date_q;
      bof_same_d = bof_same_q;
      
      bof_pc_d = bof_pc_q;
      bof_last_data_d = bof_last_data_q;

      bof_last_reg_d = bof_last_reg_q;
      illegal_load_d = illegal_load_q;

      crash_d = crash_q;

      // DETECTING INTERACTIONS WITH SAVED INTERVALS
      if(decoded_instr_i.op == ariane_pkg::LW && decoded_instr_i.rs1 != 2) begin   // if load inside one overflow range, take note 
        if (addr_in_buffer) begin
          bof_load_in_range_d = 1'b1;
          bof_last_reg_d = decoded_instr_i.rd;
        end else if (decoded_instr_i.rs1 == bof_last_reg_q && bof_load_in_range_q) begin // if illegal load in a row
          illegal_load_d = 1'b1;
        end else begin
          bof_load_in_range_d = 1'b0;
          bof_last_reg_d = 0;
        end
      end

      // SAVING INTERVALS
      if (bof_pc_q != decoded_instr_i.pc && en_crash_i) begin 
        bof_pc_d = decoded_instr_i.pc;
        if(decoded_instr_i.op == ariane_pkg::SB) begin
          if(!(decoded_instr_i.rs1 inside {2, 8})) begin
            bof_last_data_d = fu_data_i.operand_b;
            if(~bof_active_q) begin     // start tracking
              bof_active_d = 1'b1;
              bof_start_d = vaddr_i;
              bof_end_d = vaddr_i;
              bof_date_d = bof_date_max;
              bof_count_d = 32'b1;
              bof_same_d = 32'b1;
            end else if(bof_end_q + 1 == vaddr_i) begin    // if store is next to previous one
              bof_end_d = vaddr_i;
              bof_count_d = bof_count_q + 1;
              bof_date_d = bof_date_max;     
              if(fu_data_i.operand_b == bof_last_data_q) begin 
                bof_same_d = bof_same_q + 1; 
              end
            end else begin    // store somewhere new -> add to buffer
              bof_active_d = 1'b0;
              if(bof_count_q > bof_write_size && bof_same_q < bof_count_q) //test  
                buffer_write_d = 1'b1;
            end
          end
        end else begin
          if(bof_active_q) begin    // if not store, decrement date
            if(bof_date_q != 0)
              bof_date_d = bof_date_q - 1;
            else begin              // if date = 0, overflow timed out, writing
              bof_active_d = 1'b0;
              if(bof_count_q > bof_write_size && bof_same_q < bof_count_q)
                buffer_write_d = 1'b1;
            end
          end
          if(decoded_instr_i.op == ariane_pkg::LB) begin
            if(addr_is_first && bof_count_q > 8) begin
              crash_d = 1'b1;
            end
          end
        end
      end 
    end

    // INSA : FLIP FLOP
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (~rst_ni) begin
        bof_active_q <= 1'b0;
        bof_start_q <= 32'b0;
        bof_end_q <= 32'b0;
        bof_load_in_range_q <= 1'b0;
        bof_count_q <= 32'b0;
        bof_date_q <= 4'b0;
        buffer_write_q <= 1'b0;
        bof_pc_q <= 32'b0;
        bof_last_reg_q <= 6'b0;
        illegal_load_q <= 1'b0;
        bof_last_data_q <= 32'b0;
        bof_same_q <= 32'b0;
        crash_q <= 1'b0;
      end else begin
        bof_active_q <= bof_active_d;
        bof_start_q <= bof_start_d;
        bof_end_q <= bof_end_d;
        bof_load_in_range_q <= bof_load_in_range_d;
        bof_count_q <= bof_count_d;
        bof_date_q <= bof_date_d;
        buffer_write_q <= buffer_write_d;
        bof_pc_q <= bof_pc_d;
        bof_last_reg_q <= bof_last_reg_d;
        illegal_load_q <= illegal_load_d;
        bof_last_data_q <= bof_last_data_d;
        bof_same_q <= bof_same_d;
        crash_q <= crash_d;
      end
    end

endmodule
