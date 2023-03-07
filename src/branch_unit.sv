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

    parameter   buffer_size = 6;
    logic       buffer_write_i;
    logic       buffer_data_in_memory;

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
  
    
    logic       insa_active_d;
    logic       insa_last_instr_is_load_d;
    logic[3:0]  insa_timer_d;     // up to 8 instr
    logic[31:0] insa_first_d;
    logic[31:0] insa_last_d;

    logic       insa_active_q;
    logic       insa_last_instr_is_load_q;
    logic[3:0]  insa_timer_q;
    logic[31:0] insa_first_q;
    logic[31:0] insa_last_q;

    logic       buffer_om_en_write_i;
    logic       buffer_om_addr_in_range;

    assign vaddr_xlen = $unsigned($signed(fu_data_i.imm) + $signed(fu_data_i.operand_a));
    assign vaddr_i = vaddr_xlen[riscv::VLEN-1:0];

    logic crash;

    circular_buffer_om insa_buffer_om (
      .clk_i,
      .rst_ni,
      .rst_us           (rst_buf_i),
      .en_write_i       (buffer_om_en_write_i),
      .addr_first_i     (insa_first_q),   
      .addr_last_i      (insa_last_q),    
      .find_addr_i      (vaddr_i),
      .addr_in_range_o  (buffer_om_addr_in_range),
      .read_o           (alu_read_out),
      .read2_o          (alu_read_out2)
      //.fullo
    );

    assign data_in_buffer = insa_active_q; //debug

    always_comb begin : heap_safe
      buffer_om_en_write_i = 1'b0;

      to_crash = 1'b0;
      crash = 1'b0;

      //emily

      insa_last_instr_is_load_d = insa_last_instr_is_load_q;

      insa_active_d = insa_active_q;
      insa_timer_d  = insa_timer_q;
      insa_first_d  = insa_first_q;
      insa_last_d   = insa_last_q;

      case (decoded_instr_i.op)
        // check if addr to LOAD is in buffer
        ariane_pkg::LW: begin
          insa_last_instr_is_load_d = buffer_om_addr_in_range || (insa_active_q && vaddr_i inside {[insa_first_q:insa_last_q]});
        end
        // store 
        ariane_pkg::SW, ariane_pkg::SH, ariane_pkg::SB: begin
          if(decoded_instr_i.rs1 != 2) begin                  // if STORE doesn't use sp
            if(~insa_active_q) begin                          // if heap_safe OFF, activate it
              insa_active_d = 1'b1;
              insa_timer_d  = 4'd10;                          // emily - reset timer
              insa_first_d  = vaddr_i;                        // new interval starts at current STORE addr
              insa_last_d   = vaddr_i;
            end else if((decoded_instr_i.op == ariane_pkg::SW && vaddr_i == insa_last_q+4) ||
                        (decoded_instr_i.op == ariane_pkg::SH && vaddr_i == insa_last_q+2) ||
                        (decoded_instr_i.op == ariane_pkg::SB && vaddr_i == insa_last_q+1)) begin
              insa_timer_d = 4'd10;                            // emily - reset insa_timer
              insa_last_d  = vaddr_i;                          // if active and writing adjacent addr, extend interval
            end else begin
              // insa_active_d = 1'b1;                        // emily - keep active, unneeded?
              insa_active_d = 1'b0;                           // emily - disable insa_active // interval one too small?
              // save into buffer
              if (insa_last_q - insa_first_q > 32'd32) begin    // we write further away, this interval is done, store it 
                buffer_om_en_write_i = 1'b1;
              end                       
            end
          end
        end
        // jump
        ariane_pkg::JAL, ariane_pkg::JALR: begin
          if (insa_last_instr_is_load_q)              // if crash is where we jmp, crash
            crash = 1'b1;
        end
        // other instructions 
        default: begin                                        // TODO: rewrite to decrease timer on load and jmp
          if (insa_active_q) begin
            if (insa_timer_q > 0) begin
              insa_timer_d  = insa_timer_q - 1;               // decrease time since last store instruction
            end else begin
              insa_active_d = 1'b0;                            // if time is over and we have an interval, write it
            end 
            if (insa_last_q - insa_first_q > 32'd32) begin
              buffer_om_en_write_i = 1'b1;
            end
          end
        end
      endcase
    end 

    // INSA : FLIP FLOP
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (~rst_ni) begin
        insa_last_instr_is_load_q  <= '0;
        insa_active_q <= 'b0;
        insa_timer_q  <= 'b0;
        insa_first_q  <= 'b0;
        insa_last_q   <= 'b0;
      end else begin
        insa_last_instr_is_load_q  <= insa_last_instr_is_load_d;
        insa_active_q <= insa_active_d;
        insa_timer_q  <= insa_timer_d;
        insa_first_q  <= insa_first_d;
        insa_last_q   <= insa_last_d;
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
          branch_result_o = {0,next_pc[30:0] ^ (31'h73fa06c2)};
          //branch_result_o = next_pc + (1 << (riscv::VLEN - 2));
          if ((fu_data_i.operator == ariane_pkg::JALR & decoded_instr_i.rd == 0 & decoded_instr_i.rs1 == 1) | target_address[riscv::VLEN-1] == 1'b0) // target_address[riscv::VLEN-2] == 1'b1
            target_address = {1,target_address[30:0] ^ (31'h73fa06c2)};
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
