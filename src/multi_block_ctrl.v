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
// Module Name   : multi_block_ctrl
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

module multi_block_ctrl (
    input  wire        clk,
    input  wire        rst,
    // config
    input  wire        cfg_update,     //
    input  wire [31:0] cfg_block_num,  // 总采样块数
    output reg  [31:0] sts_block_num,  // 剩余采样块数
    output reg         sts_block_done,

    input  wire sample_done,
    output reg  sample_en,    //
    output reg  sample_clr    //
);

    // 对采样块进行计数
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sts_block_num <= 0;
        end else begin
            if (cfg_update) begin
                sts_block_num <= cfg_block_num;
            end else if (sample_done) begin
                sts_block_num <= sts_block_num - 1;
            end
        end
    end

    // 在所有块完成前始终使能采样
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_en <= 1'b0;
        end else begin
            sample_en <= (sts_block_num > 1) | ((sts_block_num == 1) & (sample_done == 1'b0));
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sts_block_done <= 1'b0;
        end else begin
            sts_block_done <= (sample_done == 1'b1) && (sts_block_num == 1);
        end
    end

    // 在第一次开始和每次采样完成时清空状态,并更新配置信息
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_clr <= 1'b1;
        end else begin
            sample_clr <= cfg_update | sample_done;
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
