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
// Module Name   : ring_core
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

module ring_core #(
    parameter PACK_SIZE = 4096,
    parameter TBYTES    = 32
) (
    input wire clk,
    input wire rst,

    input  wire        cfg_update,
    input  wire [31:0] cfg_base_addr,
    input  wire [31:0] cfg_end_addr,
    output reg  [31:0] current_addr,

    input  wire [TBYTES*8-1:0] s_tdata,
    input  wire                s_tvalid,
    input  wire                s_tlast,
    output wire                s_tready,

    output wire [TBYTES*8-1:0] m_tdata,
    output wire                m_tvalid,
    output wire                m_tlast,
    input  wire                m_tready,

    output reg [63:0] m_pkt_tdata,
    output reg        m_pkt_tvalid
);

    wire [ 2:0] pack_case;
    reg  [31:0] next_addr;
    reg  [31:0] data_cnt;
    wire [31:0] next_cnt;

    assign pack_case[0] = ((s_tvalid == 1'b1) && ((next_addr + data_cnt == cfg_end_addr)));  // 到达缓冲区最大地址
    assign pack_case[1] = ((s_tvalid == 1'b1) && ((s_tlast == 1'b1)));  // 采样结束
    assign pack_case[2] = ((s_tvalid == 1'b1) && ((next_cnt == PACK_SIZE)));  // 达到数据包缓冲数量时

    assign m_tvalid     = s_tvalid;
    assign m_tdata      = s_tdata;
    assign m_tlast      = |pack_case;
    assign s_tready     = m_tready;

    // 记录的下个数据包的起始地址
    always @(posedge clk or posedge rst) begin
        if (rst | cfg_update) begin
            next_addr <= cfg_base_addr;
        end else begin
            if (pack_case[1] | pack_case[0]) begin
                // 在到达缓冲区最大地址时和采样结束时重置地址
                next_addr <= cfg_base_addr;
            end else if (pack_case[2]) begin
                // 在达到数据包缓冲数量时地址步进, 增量为数据数量
                next_addr <= next_addr + next_cnt;
            end
        end
    end

    // 记录下一个被写入的数据的地址
    always @(posedge clk or posedge rst) begin
        if (rst | cfg_update) begin
            current_addr <= cfg_base_addr;
        end else begin
            if (pack_case[1] | pack_case[0]) begin
                // 在到达缓冲区最大地址时和采样结束时重置地址
                current_addr <= cfg_base_addr;
            end else if (s_tvalid) begin
                // 每来一个新数据时地址步进, 增量为数据字节数
                current_addr <= current_addr + TBYTES;
            end
        end
    end

    // 缓存数据计数
    always @(posedge clk or posedge rst) begin
        if (rst | cfg_update) begin
            data_cnt <= 0;
        end else begin
            if (|pack_case) begin
                // 所有事件都会重置计数器
                data_cnt <= 0;
            end else if (s_tvalid) begin
                // 每来一个新数据时计数器步进, 增量为数据字节数
                if (next_cnt < PACK_SIZE) begin
                    data_cnt <= next_cnt;
                end else begin
                    data_cnt <= 0;
                end
            end
        end
    end
    assign next_cnt = data_cnt + TBYTES;

    // 生成数据包信息
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_pkt_tdata  <= 0;
            m_pkt_tvalid <= 1'b0;
        end else begin
            if (m_tlast) begin
                m_pkt_tdata  <= {next_addr, next_cnt};
                m_pkt_tvalid <= 1'b1;
            end else begin
                m_pkt_tdata  <= 0;
                m_pkt_tvalid <= 1'b0;
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
