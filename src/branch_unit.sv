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

module branch_unit (
    input  logic                      clk_i,
    input  logic                      rst_ni,
    input  logic                      debug_mode_i,
    input  ariane_pkg::fu_data_t      fu_data_i,              // DATA WITH VALUE OF REGISTERS
    input  logic [riscv::VLEN-1:0]    pc_i,                   // PC of instruction
    input  logic                      is_compressed_instr_i,
    input  logic                      fu_valid_i,             // any functional unit is valid, check that there is no accidental mis-predict
    input  logic                      branch_valid_i,
    input  logic                      branch_comp_res_i,      // branch comparison result from ALU
    output logic [riscv::VLEN-1:0]    branch_result_o,

    input  ariane_pkg::branchpredict_sbe_t        branch_predict_i,       // this is the address we predicted
    output ariane_pkg::bp_resolve_t               resolved_branch_o,      // this is the actual address we are targeting
    output logic                      resolve_branch_o,       // to ID to clear that we resolved the branch and we can
                                                              // accept new entries to the scoreboard
    output ariane_pkg::exception_t    branch_exception_o,      // branch exception out

    // INSA
    input  ariane_pkg::scoreboard_entry_t         decoded_instr_i,     // INSA -> JE CROIS QUE C'EST BON
    input  riscv::priv_lvl_t                      priv_lvl_i,
    input logic [19:0]                            alu_read_index,
    output logic [31:0]                           alu_read_out,
    output logic [31:0]                           alu_read_out2,
    //output logic[2:0] led
    output logic       to_crash,
    output logic       data_in_buffer,
    //debug
    input logic       rst_buf_i,
    input logic       en_crash_i
);

    //parameter   buffer_size = 6;
    //logic       buffer_write_i;
    //logic       buffer_data_in_memory;

    //logic[1:0]  buffer_debug_leds;

    logic [riscv::VLEN-1:0] target_address;
    //logic [riscv::VLEN-1:0] target_address_bis;
    logic [riscv::VLEN-1:0] next_pc;

    logic [riscv::VLEN-1:0]   vaddr_i;
    riscv::xlen_t             vaddr_xlen;

    // // INSA
    // circular_buffer #(
    //   .N        (buffer_size)
    // ) lsu_i (
    //   .clk_i,
    //   .rst_ni,
    //   .write    (buffer_write_i),
    //   .find_in  (vaddr_i),
    //   .data_in  (vaddr_i),
    //   .data_in_memory (buffer_data_in_memory),
    //   .read_index (alu_read_index),
    //   .read_out (alu_read_out)
    //   //.led (buffer_debug_leds)
    // );
    
    // INSA: Registers for overflow management (heap)
    parameter   bof_write_size = 32;
    parameter   bof_date_max = 10;

    logic[31:0] bof_start_d;
    logic[31:0] bof_end_d;
    logic       bof_active_d;
    logic       bof_load_in_range_d;
    logic[31:0] bof_count_d;
    logic[3:0]  bof_date_d;

    logic[31:0] bof_start_q;
    logic[31:0] bof_end_q;
    logic       bof_active_q;
    logic       bof_load_in_range_q;
    logic[31:0] bof_count_q;
    logic[3:0]  bof_date_q;

    logic[31:0]  bof_store_size;
    
    logic       buffer_write_d;
    logic       buffer_write_q;
    logic       addr_in_buffer;

    assign vaddr_xlen = $unsigned($signed(fu_data_i.imm) + $signed(fu_data_i.operand_a));
    assign vaddr_i = vaddr_xlen[riscv::VLEN-1:0];

    logic crash;

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
      // base values for each signal

    always_comb begin : store_size
      case(fu_data_i.operator)
        ariane_pkg::SW: bof_store_size = 4;
        ariane_pkg::SH: bof_store_size = 2;
        ariane_pkg::SB: bof_store_size = 1;
        default:        bof_store_size = 0;
      endcase
    end

    always_comb begin : heap_safe
      buffer_write_d = 1'b0;
      crash = 1'b0;

      bof_active_d = bof_active_q;
      bof_start_d = bof_start_q;
      bof_end_d = bof_end_q;
      bof_load_in_range_d = bof_load_in_range_q;
      bof_count_d = bof_count_q;
      bof_date_d = bof_date_q;

      if(fu_data_i.operator inside {ariane_pkg::SW, ariane_pkg::SH, ariane_pkg::SB}) begin
        if(!(fu_data_i.rs1 inside {2, 8})) begin
          if(~bof_active_q) begin     // start tracking
            bof_active_d = 1'b1;
            bof_start_d = vaddr_i;
            bof_end_d = vaddr_i;
            bof_date_d = bof_date_max;
            bof_count_d = 32'b0;
          end else if(bof_end_q + bof_store_size == vaddr_i) begin    // if next store is next to previous one
            bof_end_d = vaddr_i;
            bof_count_d = bof_count_q + bof_store_size;
            bof_date_d = bof_date_max;
          end else begin    // store somewhere new -> add to buffer
            bof_active_d = 1'b0;
            if(bof_count_q > bof_write_size)  
              buffer_write_d = 1'b1;
          end
        end
      end else begin
        if(bof_active_q) begin    // if not store, decrement date
          if(bof_date_q != 0)
            bof_date_d = bof_date_q - 1;
          else begin              // if date = 0, overflow timed out, writing
            bof_active_d = 1'b0;
            if(bof_count_q > bof_write_size) 
              buffer_write_d = 1'b1;
          end
        end
        if(fu_data_i.operator == ariane_pkg::LW) begin   // if load inside one overflow range, take note 
          bof_load_in_range_d = (addr_in_buffer || (bof_active_q && vaddr_i inside {[bof_start_q:bof_end_q]}));
        end else if(fu_data_i.operator == ariane_pkg::JALR) begin  // if call after lw in range, crash
          //if(bof_load_in_range_d)
          //  crash = 1'b1;
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
      end else begin
        bof_active_q <= bof_active_d;
        bof_start_q <= bof_start_d;
        bof_end_q <= bof_end_d;
        bof_load_in_range_q <= bof_load_in_range_d;
        bof_count_q <= bof_count_d;
        bof_date_q <= bof_date_d;
        buffer_write_q <= buffer_write_d;
      end
    end

    //assign resolved_branch_o.target_address = (~crash) ? target_address_bis : {riscv::VLEN{1'b0}};

   // here we handle the various possibilities of mis-predicts
    always_comb begin : mispredict_handler
        // set the jump base, for JALR we need to look at the register, for all other control flow instructions we can take the current PC
        automatic logic [riscv::VLEN-1:0] jump_base;
        // TODO(zarubaf): The ALU can be used to calculate the branch target
        jump_base = (fu_data_i.operator == ariane_pkg::JALR) ? fu_data_i.operand_a[riscv::VLEN-1:0] : pc_i;

        target_address                   = {riscv::VLEN{1'b0}};
        resolve_branch_o                 = 1'b0;
        resolved_branch_o.target_address = {riscv::VLEN{1'b0}};
        //target_address_bis               = {riscv::VLEN{1'b0}};
        resolved_branch_o.is_taken       = 1'b0;
        resolved_branch_o.valid          = branch_valid_i;
        resolved_branch_o.is_mispredict  = 1'b0;
        resolved_branch_o.cf_type        = branch_predict_i.cf;
        resolved_branch_o.is_crash       = 1'b0;    // INSA
        // calculate next PC, depending on whether the instruction is compressed or not this may be different
        // TODO(zarubaf): We already calculate this a couple of times, maybe re-use?
        next_pc                          = pc_i + ((is_compressed_instr_i) ? {{riscv::VLEN-2{1'b0}}, 2'h2} : {{riscv::VLEN-3{1'b0}}, 3'h4});
        // calculate target address simple 64 bit addition
        target_address                   = $unsigned($signed(jump_base) + $signed(fu_data_i.imm[riscv::VLEN-1:0]));
        // on a JALR we are supposed to reset the LSB to 0 (according to the specification)
        if (fu_data_i.operator == ariane_pkg::JALR) target_address[0] = 1'b0;
        // we need to put the branch target address into rd, this is the result of this unit

        // INSA -> We want to perform security checks only on the applicative (user) level
        // INSA -> Check if should be moved to if(branch_valid_i)
        // if (priv_lvl_i == riscv::PRIV_LVL_U) begin
        // INSA -> RAJOUTER LE TEST DE X0 et aussi on peut vérifier decoded_instr_i.rs1 == 1 pour être bien sur que c'est un ret de con
        if (fu_data_i.operator == ariane_pkg::JALR | (decoded_instr_i.op == ariane_pkg::JAL & decoded_instr_i.rd == 1)) begin
          branch_result_o = {1'b0,next_pc[30:0] ^ (31'h73fa06c2)};
          //branch_result_o = next_pc + (1 << (riscv::VLEN - 2));
          if ((fu_data_i.operator == ariane_pkg::JALR & decoded_instr_i.rd == 0 & decoded_instr_i.rs1 == 1) | target_address[riscv::VLEN-1] == 1'b0) // target_address[riscv::VLEN-2] == 1'b1
            target_address = {1'b1,target_address[30:0] ^ (31'h73fa06c2)};
            //target_address = target_address - (1 << (riscv::VLEN - 2));
        end
        else
          branch_result_o = next_pc;

        if (crash & en_crash_i)
          target_address = {riscv::VLEN{1'b0}};
  
        // INSA -> SW LIFO 
        // to_crash        = 1'b0;
        // buffer_write_i  = 1'b0;
        // if(pc_i inside {[32'h800001e4:32'h800025d8]}) begin
        //   if (decoded_instr_i.op inside {ariane_pkg::SW, ariane_pkg::SH, ariane_pkg::SB}) begin
        //       if (decoded_instr_i.rs1 == 8)  // Is the STORE using sp or fp ?
        //           buffer_write_i = 1'b1;
        //       else if (decoded_instr_i.rs1 != 8 & buffer_data_in_memory)         //Crash
        //           to_crash = 1'b1;
        //   end
        // end

        resolved_branch_o.pc = pc_i;
        // There are only two sources of mispredicts:
        // 1. Branches
        // 2. Jumps to register addresses
        if (branch_valid_i) begin
            // write target address which goes to PC Gen
            resolved_branch_o.target_address = (branch_comp_res_i) ? target_address : next_pc;
            //target_address_bis = (branch_comp_res_i) ? target_address : next_pc;
            resolved_branch_o.is_taken = branch_comp_res_i;
            // check the outcome of the branch speculation
            if (ariane_pkg::op_is_branch(fu_data_i.operator) && branch_comp_res_i != (branch_predict_i.cf == ariane_pkg::Branch)) begin
                // we mis-predicted the outcome
                // if the outcome doesn't match we've got a mis-predict
                resolved_branch_o.is_mispredict  = 1'b1;
                resolved_branch_o.cf_type = ariane_pkg::Branch;
            end
            if (fu_data_i.operator == ariane_pkg::JALR
                // check if the address of the jump register is correct and that we actually predicted
                && (branch_predict_i.cf == ariane_pkg::NoCF || target_address != branch_predict_i.predict_address)) begin
                resolved_branch_o.is_mispredict  = 1'b1;
                // update BTB only if this wasn't a return
                if (branch_predict_i.cf != ariane_pkg::Return) resolved_branch_o.cf_type = ariane_pkg::JumpR;
            end
            // to resolve the branch in ID
            resolve_branch_o = 1'b1;
        end
    end
    
    // use ALU exception signal for storing instruction fetch exceptions if
    // the target address is not aligned to a 2 byte boundary
    always_comb begin : exception_handling
        branch_exception_o.cause = riscv::INSTR_ADDR_MISALIGNED;
        branch_exception_o.valid = 1'b0;
        branch_exception_o.tval  = {{riscv::XLEN-riscv::VLEN{pc_i[riscv::VLEN-1]}}, pc_i};
        // only throw exception if this is indeed a branch
        if (branch_valid_i && target_address[0] != 1'b0) branch_exception_o.valid = 1'b1;
    end
endmodule
