// ---------------------------------------------------------------------------------------
// Copyright (c) 2024 john_tito All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ---------------------------------------------------------------------------------------
// +FHEADER-------------------------------------------------------------------------------
// Author        : john_tito
// Module Name   : sample_wrapper
// ---------------------------------------------------------------------------------------
// Revision      : 1.0
// Description   : File Created
// ---------------------------------------------------------------------------------------
// Synthesizable : Yes
// Clock Domains : clk
// Reset Strategy: sync reset
// -FHEADER-------------------------------------------------------------------------------

// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sample_warper #(
    parameter integer TBYTES           = 1,
    parameter integer C_APB_DATA_WIDTH = 32,
    parameter integer C_APB_ADDR_WIDTH = 16
) (
    //
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_apb:s_axis:m_axis:m_pkt_axis , ASSOCIATED_RESET rst" *)
    input wire clk,  //  (required)

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input wire rst,  //  (required)

    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PADDR" *)
    input  wire [31:0] s_paddr,    // Address (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PSEL" *)
    input  wire        s_psel,     // Slave Select (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PENABLE" *)
    input  wire        s_penable,  // Enable (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PWRITE" *)
    input  wire        s_pwrite,   // Write Control (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PWDATA" *)
    input  wire [31:0] s_pwdata,   // Write Data (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PREADY" *)
    output wire        s_pready,   // Slave Ready (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PRDATA" *)
    output wire [31:0] s_prdata,   // Read Data (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PSLVERR" *)
    output wire        s_pslverr,  // Slave Error Response (required)

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis  TDATA" *)
    input  wire [TBYTES*8-1:0] s_tdata,   //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis  TVALID" *)
    input  wire                s_tvalid,  //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis  TREADY" *)
    output wire                s_tready,  //

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis  TDATA" *)
    output wire [TBYTES*8-1:0] m_tdata,   //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis  TVALID" *)
    output wire                m_tvalid,  //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis  TREADY" *)
    input  wire                m_tready,  //
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis  TLAST" *)
    output wire                m_tlast,   //

    input  wire trig_in,
    output wire trig_out
);

    wire                soft_rst;
    wire                cfg_update;
    wire [        31:0] cfg_block_num;
    wire [        31:0] cfg_pre_sample_num;
    wire [        31:0] cfg_post_sample_num;
    wire                sts_sample_busy;
    wire [        31:0] sts_sample_block_num;
    wire                sts_sample_block_done;

    wire                sample_done;
    wire                sample_en;
    wire                sample_clr;
    wire                sample_busy;

    wire [TBYTES*8-1:0] tdata_i;
    wire                tvalid_i;
    wire                tready_i;
    wire                tlast_i;

    apb_sample_ui #(
        .TBYTES          (TBYTES),
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH)
    ) apb_sample_ui_inst (
        .clk                  (clk),
        .rst                  (rst),
        .s_paddr              (s_paddr),
        .s_psel               (s_psel),
        .s_penable            (s_penable),
        .s_pwrite             (s_pwrite),
        .s_pwdata             (s_pwdata),
        .s_pready             (s_pready),
        .s_prdata             (s_prdata),
        .s_pslverr            (s_pslverr),
        .soft_rst             (soft_rst),
        .cfg_update           (cfg_update),
        .cfg_block_num        (cfg_block_num),
        .cfg_pre_sample_num   (cfg_pre_sample_num),
        .cfg_post_sample_num  (cfg_post_sample_num),
        .sts_sample_busy      (sts_sample_busy),
        .sts_sample_block_done(sts_sample_block_done),
        .sts_sample_block_num (sts_sample_block_num)
    );

    multi_block_ctrl multi_block_ctrl_inst (
        .clk           (clk),
        .rst           (soft_rst),
        .cfg_update    (cfg_update),
        .cfg_block_num (cfg_block_num),
        .sts_block_num (sts_sample_block_num),
        .sts_block_done(sts_sample_block_done),
        .sample_done   (sample_done),
        .sample_en     (sample_en),
        .sample_clr    (sample_clr)
    );

    sample_core #(
        .TBYTES(TBYTES)
    ) sample_core_inst (
        .clk                (clk),
        .rst                (soft_rst),
        .cfg_pre_sample_num (cfg_pre_sample_num),
        .cfg_post_sample_num(cfg_post_sample_num),
        .sample_clr         (sample_clr),
        .sample_en          (sample_en),
        .sample_busy        (sts_sample_busy),
        .sample_done        (sample_done),
        .trig_in            (trig_in),
        .trig_out           (trig_out),
        .s_tdata            (s_tdata),
        .s_tvalid           (s_tvalid),
        .s_tready           (s_tready),
        .m_tdata            (m_tdata),
        .m_tvalid           (m_tvalid),
        .m_tready           (m_tready),
        .m_tlast            (m_tlast)
    );

endmodule

// verilog_format: off
`resetall
// verilog_format: on
