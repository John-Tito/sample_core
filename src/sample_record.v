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
// Module Name   : sample_record
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

module sample_record #(
    parameter TBYTES = 32
) (
    input wire        clk,
    input wire        rst,
    // config
    input wire [31:0] cfg_pre_sample_num,
    input wire [31:0] cfg_post_sample_num,

    input wire [31:0] cfg_block_base_addr,
    input wire [31:0] cfg_block_end_addr,
    input wire [31:0] cfg_block_size,
    input wire [31:0] current_addr,

    input wire cfg_update,
    input wire trig,
    input wire sample_done,
    input wire sample_block_done,

    output reg [31:0] sample_start_addr1,
    output reg [31:0] sample_start_addr2,
    output reg [31:0] sample_trig_addr,
    output reg [31:0] sample_end_addr
);

    reg [31:0] sample_num;
    reg [31:0] pre_sample_num;
    reg [31:0] post_sample_num;
    reg [31:0] block_size;
    reg [31:0] block_base_addr;
    reg [31:0] block_end_addr;

    always @(posedge clk or posedge rst) begin
        if (rst | cfg_update) begin
            block_base_addr <= cfg_block_base_addr;
            block_end_addr  <= cfg_block_end_addr;
            pre_sample_num  <= cfg_pre_sample_num;
            post_sample_num <= cfg_post_sample_num;
            block_size      <= cfg_block_end_addr - cfg_block_base_addr + 1;
            sample_num      <= cfg_pre_sample_num + cfg_post_sample_num;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst | (cfg_update & ~sample_block_done)) begin
            sample_trig_addr <= cfg_block_base_addr;
        end else begin
            if (trig) begin
                sample_trig_addr <= current_addr;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst | (cfg_update & ~sample_block_done)) begin
            sample_end_addr <= cfg_block_base_addr;
        end else begin
            if (sample_done) begin
                sample_end_addr <= current_addr;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst | (cfg_update & ~sample_block_done)) begin
            sample_start_addr1 <= cfg_block_base_addr;
            sample_start_addr2 <= cfg_block_base_addr;
        end else begin
            if (sample_done) begin
                // 若结束点的地址小于 起始地址加上数据长度则表明地址回滚过
                if (current_addr + 1 < block_base_addr + sample_num * TBYTES) begin
                    sample_start_addr1 <= (block_size) + 1 + current_addr - sample_num * TBYTES;
                    sample_start_addr2 <= (block_size) + 1 + sample_trig_addr - pre_sample_num * TBYTES;
                end else begin
                    sample_start_addr1 <= current_addr + 1 - sample_num * TBYTES;
                    sample_start_addr2 <= sample_trig_addr + 1 - pre_sample_num * TBYTES;
                end
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
