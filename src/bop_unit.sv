// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 09.05.2017
// Description: Branch target calculation and comparison

module bop_unit (
    input  logic                      clk_i,
    input  logic                      rst_ni,
    input  ariane_pkg::fu_data_t      fu_data_i,
    input  ariane_pkg::scoreboard_entry_t         decoded_instr_i,

    output logic [31:0]                           alu_read_out,
    output logic [31:0]                           alu_read_out2,

    output logic       to_crash,
    output logic       illegal_load,
    output logic       data_in_buffer,
    output logic [6:0] load_reg,

    input logic       rst_buf_i,
    input logic       en_crash_i
);

    logic [riscv::VLEN-1:0]   vaddr_i;
    riscv::xlen_t             vaddr_xlen;
    
    // INSA: Registers for overflow management (heap)
    parameter   bof_write_size = 32;    // 200 -> crash -- 1000 -> pas crash -> 416 (5*message ?)
    parameter   bof_date_max = 10;

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

    logic[6:0] bof_last_reg_d;
    logic[6:0] bof_last_reg_q;

    logic[31:0]  bof_last_data_d;
    logic[31:0]  bof_last_data_q;

    logic       illegal_load_d;
    logic       illegal_load_q;

    assign vaddr_xlen = $unsigned($signed(fu_data_i.imm) + $signed(fu_data_i.operand_a));
    assign vaddr_i = vaddr_xlen[riscv::VLEN-1:0];

    circular_buffer_om insa_buffer_om (
      .clk_i,
      .rst_ni,
      .rst_us           (rst_buf_i),
      .en_write_i       (buffer_write_q),
      .addr_first_i     (bof_start_q),   
      .addr_last_i      (bof_end_q),    
      .find_addr_i      (vaddr_i),
      .addr_in_range_o  (addr_in_buffer),
      .read_o           (alu_read_out),
      .read2_o          (alu_read_out2)
      //.fullo
    );

    assign data_in_buffer = bof_active_q; //debug
    assign to_crash = bof_load_in_range_q;
    assign load_reg = bof_last_reg_q;
    assign illegal_load = illegal_load_q;

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

      // DETECTING INTERACTIONS WITH SAVED INTERVALS
      if(decoded_instr_i.op == ariane_pkg::LW && !(decoded_instr_i.rs1 inside {2, 8})) begin   // if load inside one overflow range, take note 
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
      end
    end

endmodule
