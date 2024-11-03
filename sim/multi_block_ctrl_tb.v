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
// Module Name   : multi_block_ctrl_tb
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

module multi_block_ctrl_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;
    localparam integer TBYTES = 1;
    localparam integer PACK_SAMPLES = 1024;  // 采样点数
    localparam integer PRE_SAMPLES = 32;  // 采样点数
    localparam integer POST_SAMPLES = 32;  // 采样点数

    localparam integer CFG_BLOCK_SAMPLES = 1024;
    localparam integer CFG_BLOCK_BASE_ADDR = 0;
    localparam integer CFG_BLOCK_NUM = 32;

    localparam integer CFG_BLOCK_BYTES = TBYTES * CFG_BLOCK_SAMPLES;
    localparam integer PACK_BYTES = PACK_SAMPLES * TBYTES;  // 字节数

    // Ports
    reg                clk = 0;
    reg                rstn = 0;
    reg                cfg_update = 0;
    reg [        31:0] cfg_block_base_addr = 0;
    reg [        31:0] cfg_block_size = 0;
    reg [        31:0] cfg_block_num = 0;
    reg [        31:0] cfg_pre_sample_num = 0;
    reg [        31:0] cfg_post_sample_num = 0;

    reg [TBYTES*8-1:0] s_tdata = 0;
    reg                s_tvalid = 0;
    reg                trig_in = 1'b0;

    sample_warper #(
        .TBYTES          (TBYTES),
        .PACK_BYTES      (PACK_BYTES),
        .C_APB_DATA_WIDTH(32),
        .C_APB_ADDR_WIDTH(16)
    ) sample_warper_inst (
        .clk         (clk),
        .rst         (~rstn),
        .s_paddr     (0),
        .s_psel      (0),
        .s_penable   (0),
        .s_pwrite    (0),
        .s_pwdata    (0),
        .s_pstrb     (0),
        .s_pready    (),
        .s_prdata    (),
        .s_pslverr   (),
        .s_tdata     (s_tdata),
        .s_tvalid    (s_tvalid),
        .m_tdata     (),
        .m_tvalid    (),
        .m_tlast     (),
        .m_pkt_tdata (),
        .m_pkt_tvalid(),
        .trig_in     (trig_in),
        .trig_out    ()
    );

    always @(posedge clk) begin
        if (~rstn) begin
            s_tdata  <= 0;
            s_tvalid <= 1'b0;
        end else begin
            s_tdata  <= s_tdata + 1;
            s_tvalid <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            trig_in <= 1'b0;
        end else begin
            trig_in <= 1'b1;
        end
    end

    initial begin
        begin
            wait (rstn);
            #100;
            cfg_pre_sample_num  = PRE_SAMPLES;
            cfg_post_sample_num = POST_SAMPLES;
            cfg_block_base_addr = CFG_BLOCK_BASE_ADDR;
            cfg_block_size      = CFG_BLOCK_BYTES;
            cfg_block_num       = CFG_BLOCK_NUM;
            #100;
            @(posedge clk);
            cfg_update <= 1'b1;
            @(posedge clk);
            cfg_update <= 1'b0;
            #100000;
            $finish;
        end
    end

    always #5 clk = !clk;

    // reset block
    initial begin
        rstn = 1'b0;
        #(TIMEPERIOD * 32);
        rstn = 1'b1;
    end

    // record block
    initial begin
        $dumpfile("sim/test_tb.vcd");
        $dumpvars(0, multi_block_ctrl_tb);
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
