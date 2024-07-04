// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Top module auto-generated by `reggen`

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"
`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module axi_vga_reg_top #(
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic,
  parameter int AW = 7
) (
  input logic clk_i,
  input logic rst_ni,
  input  reg_req_t reg_req_i,
  output reg_rsp_t reg_rsp_o,
  // To HW
  output axi_vga_reg_pkg::axi_vga_reg2hw_t reg2hw, // Write


  // Config
  input devmode_i // If 1, explicit error return for unmapped register access
);

  import axi_vga_reg_pkg::* ;

  localparam int DW = 32;
  localparam int DBW = DW/8;                    // Byte Width

  // register signals
  logic           reg_we;
  logic           reg_re;
  logic [AW-1:0]  reg_addr;
  logic [DW-1:0]  reg_wdata;
  logic [DBW-1:0] reg_be;
  logic [DW-1:0]  reg_rdata;
  logic           reg_error;

  logic          addrmiss, wr_err;

  logic [DW-1:0] reg_rdata_next;

  // Below register interface can be changed
  reg_req_t  reg_intf_req;
  reg_rsp_t  reg_intf_rsp;


  assign reg_intf_req = reg_req_i;
  assign reg_rsp_o = reg_intf_rsp;


  assign reg_we = reg_intf_req.valid & reg_intf_req.write;
  assign reg_re = reg_intf_req.valid & ~reg_intf_req.write;
  assign reg_addr = reg_intf_req.addr;
  assign reg_wdata = reg_intf_req.wdata;
  assign reg_be = reg_intf_req.wstrb;
  assign reg_intf_rsp.rdata = reg_rdata;
  assign reg_intf_rsp.error = reg_error;
  assign reg_intf_rsp.ready = 1'b1;

  assign reg_rdata = reg_rdata_next ;
  assign reg_error = (devmode_i & addrmiss) | wr_err;


  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic control_enable_qs;
  logic control_enable_wd;
  logic control_enable_we;
  logic control_hsync_pol_qs;
  logic control_hsync_pol_wd;
  logic control_hsync_pol_we;
  logic control_vsync_pol_qs;
  logic control_vsync_pol_wd;
  logic control_vsync_pol_we;
  logic [7:0] clk_div_qs;
  logic [7:0] clk_div_wd;
  logic clk_div_we;
  logic [31:0] hori_visible_size_qs;
  logic [31:0] hori_visible_size_wd;
  logic hori_visible_size_we;
  logic [31:0] hori_front_porch_size_qs;
  logic [31:0] hori_front_porch_size_wd;
  logic hori_front_porch_size_we;
  logic [31:0] hori_sync_size_qs;
  logic [31:0] hori_sync_size_wd;
  logic hori_sync_size_we;
  logic [31:0] hori_back_porch_size_qs;
  logic [31:0] hori_back_porch_size_wd;
  logic hori_back_porch_size_we;
  logic [31:0] vert_visible_size_qs;
  logic [31:0] vert_visible_size_wd;
  logic vert_visible_size_we;
  logic [31:0] vert_front_porch_size_qs;
  logic [31:0] vert_front_porch_size_wd;
  logic vert_front_porch_size_we;
  logic [31:0] vert_sync_size_qs;
  logic [31:0] vert_sync_size_wd;
  logic vert_sync_size_we;
  logic [31:0] vert_back_porch_size_qs;
  logic [31:0] vert_back_porch_size_wd;
  logic vert_back_porch_size_we;
  logic [31:0] start_addr_low_qs;
  logic [31:0] start_addr_low_wd;
  logic start_addr_low_we;
  logic [31:0] start_addr_high_qs;
  logic [31:0] start_addr_high_wd;
  logic start_addr_high_we;
  logic [31:0] frame_size_qs;
  logic [31:0] frame_size_wd;
  logic frame_size_we;
  logic [7:0] burst_len_qs;
  logic [7:0] burst_len_wd;
  logic burst_len_we;
  
    logic [7:0] offset_qs;
  logic [7:0] offset_wd;
  logic offset_we;
  
  logic [31:0] fifo_depth_qs;
  logic [31:0] fifo_depth_wd;
  logic fifo_depth_we;

  // Register instances
  // R[control]: V(False)

  //   F[enable]: 0:0
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_control_enable (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (control_enable_we),
    .wd     (control_enable_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.control.enable.q ),

    // to register interface (read)
    .qs     (control_enable_qs)
  );


  //   F[hsync_pol]: 1:1
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h1)
  ) u_control_hsync_pol (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (control_hsync_pol_we),
    .wd     (control_hsync_pol_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.control.hsync_pol.q ),

    // to register interface (read)
    .qs     (control_hsync_pol_qs)
  );


  //   F[vsync_pol]: 2:2
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h1)
  ) u_control_vsync_pol (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (control_vsync_pol_we),
    .wd     (control_vsync_pol_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.control.vsync_pol.q ),

    // to register interface (read)
    .qs     (control_vsync_pol_qs)
  );


  // R[clk_div]: V(False)

  prim_subreg #(
    .DW      (8),
    .SWACCESS("RW"),
    .RESVAL  (8'h1)
  ) u_clk_div (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (clk_div_we),
    .wd     (clk_div_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.clk_div.q ),

    // to register interface (read)
    .qs     (clk_div_qs)
  );


  // R[hori_visible_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_hori_visible_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hori_visible_size_we),
    .wd     (hori_visible_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hori_visible_size.q ),

    // to register interface (read)
    .qs     (hori_visible_size_qs)
  );


  // R[hori_front_porch_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_hori_front_porch_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hori_front_porch_size_we),
    .wd     (hori_front_porch_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hori_front_porch_size.q ),

    // to register interface (read)
    .qs     (hori_front_porch_size_qs)
  );


  // R[hori_sync_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_hori_sync_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hori_sync_size_we),
    .wd     (hori_sync_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hori_sync_size.q ),

    // to register interface (read)
    .qs     (hori_sync_size_qs)
  );


  // R[hori_back_porch_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_hori_back_porch_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (hori_back_porch_size_we),
    .wd     (hori_back_porch_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.hori_back_porch_size.q ),

    // to register interface (read)
    .qs     (hori_back_porch_size_qs)
  );


  // R[vert_visible_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_vert_visible_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (vert_visible_size_we),
    .wd     (vert_visible_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.vert_visible_size.q ),

    // to register interface (read)
    .qs     (vert_visible_size_qs)
  );


  // R[vert_front_porch_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_vert_front_porch_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (vert_front_porch_size_we),
    .wd     (vert_front_porch_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.vert_front_porch_size.q ),

    // to register interface (read)
    .qs     (vert_front_porch_size_qs)
  );


  // R[vert_sync_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_vert_sync_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (vert_sync_size_we),
    .wd     (vert_sync_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.vert_sync_size.q ),

    // to register interface (read)
    .qs     (vert_sync_size_qs)
  );


  // R[vert_back_porch_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h1)
  ) u_vert_back_porch_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (vert_back_porch_size_we),
    .wd     (vert_back_porch_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.vert_back_porch_size.q ),

    // to register interface (read)
    .qs     (vert_back_porch_size_qs)
  );


  // R[start_addr_low]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_start_addr_low (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (start_addr_low_we),
    .wd     (start_addr_low_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.start_addr_low.q ),

    // to register interface (read)
    .qs     (start_addr_low_qs)
  );


  // R[start_addr_high]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_start_addr_high (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (start_addr_high_we),
    .wd     (start_addr_high_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.start_addr_high.q ),

    // to register interface (read)
    .qs     (start_addr_high_qs)
  );


  // R[frame_size]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_frame_size (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (frame_size_we),
    .wd     (frame_size_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.frame_size.q ),

    // to register interface (read)
    .qs     (frame_size_qs)
  );


  // R[burst_len]: V(False)

  prim_subreg #(
    .DW      (8),
    .SWACCESS("RW"),
    .RESVAL  (8'h0)
  ) u_burst_len (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (burst_len_we),
    .wd     (burst_len_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.burst_len.q ),

    // to register interface (read)
    .qs     (burst_len_qs)
  );


  // R[offset]: V(False)

  prim_subreg #(
    .DW      (8),
    .SWACCESS("RW"),
    .RESVAL  (8'h0)
  ) u_offset (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (offset_we),
    .wd     (offset_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.offset.q ),

    // to register interface (read)
    .qs     (offset_qs)
  );

  // R[fifo_depth]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_fifo_depth (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (fifo_depth_we),
    .wd     (fifo_depth_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.fifo_depth.q ),

    // to register interface (read)
    .qs     (fifo_depth_qs)
  );

  logic [15:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    addr_hit[ 0] = (reg_addr == AXI_VGA_CONTROL_OFFSET);
    addr_hit[ 1] = (reg_addr == AXI_VGA_CLK_DIV_OFFSET);
    addr_hit[ 2] = (reg_addr == AXI_VGA_HORI_VISIBLE_SIZE_OFFSET);
    addr_hit[ 3] = (reg_addr == AXI_VGA_HORI_FRONT_PORCH_SIZE_OFFSET);
    addr_hit[ 4] = (reg_addr == AXI_VGA_HORI_SYNC_SIZE_OFFSET);
    addr_hit[ 5] = (reg_addr == AXI_VGA_HORI_BACK_PORCH_SIZE_OFFSET);
    addr_hit[ 6] = (reg_addr == AXI_VGA_VERT_VISIBLE_SIZE_OFFSET);
    addr_hit[ 7] = (reg_addr == AXI_VGA_VERT_FRONT_PORCH_SIZE_OFFSET);
    addr_hit[ 8] = (reg_addr == AXI_VGA_VERT_SYNC_SIZE_OFFSET);
    addr_hit[ 9] = (reg_addr == AXI_VGA_VERT_BACK_PORCH_SIZE_OFFSET);
    addr_hit[10] = (reg_addr == AXI_VGA_START_ADDR_LOW_OFFSET);
    addr_hit[11] = (reg_addr == AXI_VGA_START_ADDR_HIGH_OFFSET);
    addr_hit[12] = (reg_addr == AXI_VGA_FRAME_SIZE_OFFSET);
    addr_hit[13] = (reg_addr == AXI_VGA_BURST_LEN_OFFSET);
    addr_hit[14] = (reg_addr == AXI_VGA_OFFSET_OFFSET);
    addr_hit[15] = (reg_addr == AXI_VGA_FIFO_DEPTH_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = (reg_we &
              ((addr_hit[ 0] & (|(AXI_VGA_PERMIT[ 0] & ~reg_be))) |
               (addr_hit[ 1] & (|(AXI_VGA_PERMIT[ 1] & ~reg_be))) |
               (addr_hit[ 2] & (|(AXI_VGA_PERMIT[ 2] & ~reg_be))) |
               (addr_hit[ 3] & (|(AXI_VGA_PERMIT[ 3] & ~reg_be))) |
               (addr_hit[ 4] & (|(AXI_VGA_PERMIT[ 4] & ~reg_be))) |
               (addr_hit[ 5] & (|(AXI_VGA_PERMIT[ 5] & ~reg_be))) |
               (addr_hit[ 6] & (|(AXI_VGA_PERMIT[ 6] & ~reg_be))) |
               (addr_hit[ 7] & (|(AXI_VGA_PERMIT[ 7] & ~reg_be))) |
               (addr_hit[ 8] & (|(AXI_VGA_PERMIT[ 8] & ~reg_be))) |
               (addr_hit[ 9] & (|(AXI_VGA_PERMIT[ 9] & ~reg_be))) |
               (addr_hit[10] & (|(AXI_VGA_PERMIT[10] & ~reg_be))) |
               (addr_hit[11] & (|(AXI_VGA_PERMIT[11] & ~reg_be))) |
               (addr_hit[12] & (|(AXI_VGA_PERMIT[12] & ~reg_be))) |
               (addr_hit[13] & (|(AXI_VGA_PERMIT[13] & ~reg_be))) |
               (addr_hit[14] & (|(AXI_VGA_PERMIT[14] & ~reg_be))) |
               (addr_hit[15] & (|(AXI_VGA_PERMIT[15] & ~reg_be)))));
  end

  assign control_enable_we = addr_hit[0] & reg_we & !reg_error;
  assign control_enable_wd = reg_wdata[0];

  assign control_hsync_pol_we = addr_hit[0] & reg_we & !reg_error;
  assign control_hsync_pol_wd = reg_wdata[1];

  assign control_vsync_pol_we = addr_hit[0] & reg_we & !reg_error;
  assign control_vsync_pol_wd = reg_wdata[2];

  assign clk_div_we = addr_hit[1] & reg_we & !reg_error;
  assign clk_div_wd = reg_wdata[7:0];

  assign hori_visible_size_we = addr_hit[2] & reg_we & !reg_error;
  assign hori_visible_size_wd = reg_wdata[31:0];

  assign hori_front_porch_size_we = addr_hit[3] & reg_we & !reg_error;
  assign hori_front_porch_size_wd = reg_wdata[31:0];

  assign hori_sync_size_we = addr_hit[4] & reg_we & !reg_error;
  assign hori_sync_size_wd = reg_wdata[31:0];

  assign hori_back_porch_size_we = addr_hit[5] & reg_we & !reg_error;
  assign hori_back_porch_size_wd = reg_wdata[31:0];

  assign vert_visible_size_we = addr_hit[6] & reg_we & !reg_error;
  assign vert_visible_size_wd = reg_wdata[31:0];

  assign vert_front_porch_size_we = addr_hit[7] & reg_we & !reg_error;
  assign vert_front_porch_size_wd = reg_wdata[31:0];

  assign vert_sync_size_we = addr_hit[8] & reg_we & !reg_error;
  assign vert_sync_size_wd = reg_wdata[31:0];

  assign vert_back_porch_size_we = addr_hit[9] & reg_we & !reg_error;
  assign vert_back_porch_size_wd = reg_wdata[31:0];

  assign start_addr_low_we = addr_hit[10] & reg_we & !reg_error;
  assign start_addr_low_wd = reg_wdata[31:0];

  assign start_addr_high_we = addr_hit[11] & reg_we & !reg_error;
  assign start_addr_high_wd = reg_wdata[31:0];

  assign frame_size_we = addr_hit[12] & reg_we & !reg_error;
  assign frame_size_wd = reg_wdata[31:0];

  assign burst_len_we = addr_hit[13] & reg_we & !reg_error;
  assign burst_len_wd = reg_wdata[7:0];
  
  assign offset_we = addr_hit[14] & reg_we & !reg_error;
  assign offset_wd = reg_wdata[7:0];
  
  assign fifo_depth_we = addr_hit[15] & reg_we & !reg_error;
  assign fifo_depth_wd = reg_wdata[31:0];

  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[0] = control_enable_qs;
        reg_rdata_next[1] = control_hsync_pol_qs;
        reg_rdata_next[2] = control_vsync_pol_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[7:0] = clk_div_qs;
      end

      addr_hit[2]: begin
        reg_rdata_next[31:0] = hori_visible_size_qs;
      end

      addr_hit[3]: begin
        reg_rdata_next[31:0] = hori_front_porch_size_qs;
      end

      addr_hit[4]: begin
        reg_rdata_next[31:0] = hori_sync_size_qs;
      end

      addr_hit[5]: begin
        reg_rdata_next[31:0] = hori_back_porch_size_qs;
      end

      addr_hit[6]: begin
        reg_rdata_next[31:0] = vert_visible_size_qs;
      end

      addr_hit[7]: begin
        reg_rdata_next[31:0] = vert_front_porch_size_qs;
      end

      addr_hit[8]: begin
        reg_rdata_next[31:0] = vert_sync_size_qs;
      end

      addr_hit[9]: begin
        reg_rdata_next[31:0] = vert_back_porch_size_qs;
      end

      addr_hit[10]: begin
        reg_rdata_next[31:0] = start_addr_low_qs;
      end

      addr_hit[11]: begin
        reg_rdata_next[31:0] = start_addr_high_qs;
      end

      addr_hit[12]: begin
        reg_rdata_next[31:0] = frame_size_qs;
      end

      addr_hit[13]: begin
        reg_rdata_next[7:0] = burst_len_qs;
      end
      
      addr_hit[14]: begin
        reg_rdata_next[7:0] = offset_qs;
      end
      
      addr_hit[15]: begin
        reg_rdata_next[31:0] = fifo_depth_qs;
      end
      
      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Unused signal tieoff

  // wdata / byte enable are not always fully used
  // add a blanket unused statement to handle lint waivers
  logic unused_wdata;
  logic unused_be;
  assign unused_wdata = ^reg_wdata;
  assign unused_be = ^reg_be;

  // Assertions for Register Interface
  `ASSERT(en2addrHit, (reg_we || reg_re) |-> $onehot0(addr_hit))

endmodule

module axi_vga_reg_top_intf
#(
  parameter int AW = 6,
  localparam int DW = 32
) (
  input logic clk_i,
  input logic rst_ni,
  REG_BUS.in  regbus_slave,
  // To HW
  output axi_vga_reg_pkg::axi_vga_reg2hw_t reg2hw, // Write
  // Config
  input devmode_i // If 1, explicit error return for unmapped register access
);
 localparam int unsigned STRB_WIDTH = DW/8;


  // Define structs for reg_bus
  typedef logic [AW-1:0] addr_t;
  typedef logic [DW-1:0] data_t;
  typedef logic [STRB_WIDTH-1:0] strb_t;
  `REG_BUS_TYPEDEF_ALL(reg_bus, addr_t, data_t, strb_t)

  reg_bus_req_t s_reg_req;
  reg_bus_rsp_t s_reg_rsp;
  
  // Assign SV interface to structs
  `REG_BUS_ASSIGN_TO_REQ(s_reg_req, regbus_slave)
  `REG_BUS_ASSIGN_FROM_RSP(regbus_slave, s_reg_rsp)

  

  axi_vga_reg_top #(
    .reg_req_t(reg_bus_req_t),
    .reg_rsp_t(reg_bus_rsp_t),
    .AW(AW)
  ) i_regs (
    .clk_i,
    .rst_ni,
    .reg_req_i(s_reg_req),
    .reg_rsp_o(s_reg_rsp),
    .reg2hw, // Write
    .devmode_i
  );
  
endmodule


