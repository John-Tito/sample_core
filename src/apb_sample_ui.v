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
// Module Name   : apb_sample_ui
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

module apb_sample_ui #(
    parameter integer C_APB_ADDR_WIDTH = 16,
    parameter integer C_APB_DATA_WIDTH = 32,
    parameter integer C_S_BASEADDR     = 0,
    parameter integer C_S_HIGHADDR     = 255,
    parameter integer TBYTES           = 1
) (
    //
    input  wire                          clk,
    input  wire                          rst,
    //
    input  wire [(C_APB_ADDR_WIDTH-1):0] s_paddr,
    input  wire                          s_psel,
    input  wire                          s_penable,
    input  wire                          s_pwrite,
    input  wire [(C_APB_DATA_WIDTH-1):0] s_pwdata,
    output wire                          s_pready,
    output wire [(C_APB_DATA_WIDTH-1):0] s_prdata,
    output wire                          s_pslverr,
    //
    output wire                          soft_rst,
    output wire                          cfg_update,
    output wire [                  31:0] cfg_block_num,
    output wire [                  31:0] cfg_pre_sample_num,
    output wire [                  31:0] cfg_post_sample_num,
    input  wire                          sts_sample_busy,
    input  wire                          sts_sample_block_done,
    input  wire [                  31:0] sts_sample_block_num
);

    // verilog_format: off
    localparam [7:0] ADDR_ID                = C_S_BASEADDR;                 // 0x0000
    localparam [7:0] ADDR_REVISION          = ADDR_ID               + 8'h4; // 0x0004
    localparam [7:0] ADDR_BUILDTIME         = ADDR_REVISION         + 8'h4; // 0x0008
    localparam [7:0] ADDR_TEST              = ADDR_BUILDTIME        + 8'h4; // 0x000C
    localparam [7:0] ADDR_TBYTES            = ADDR_TEST             + 8'h4; // 0x0010
    localparam [7:0] ADDR_CTRL              = ADDR_TBYTES           + 8'h4; // 0x0014
    localparam [7:0] ADDR_STATE             = ADDR_CTRL             + 8'h4; // 0x0018
    localparam [7:0] ADDR_BLOCK_NUM         = ADDR_STATE            + 8'h4; // 0x002C
    localparam [7:0] ADDR_PRE_SAMPLE_NUM    = ADDR_BLOCK_NUM        + 8'h4; // 0x0020
    localparam [7:0] ADDR_POST_SAMPLE_NUM   = ADDR_PRE_SAMPLE_NUM   + 8'h4; // 0x0024
    localparam [7:0] ADDR_STS_BLOCK_NUM     = ADDR_POST_SAMPLE_NUM  + 8'h4; // 0x0028
    // verilog_format: on

    reg        rst_i = 1;
    reg        soft_rst_i = 1;
    reg [ 1:0] cfg_update_reg;
    reg [31:0] cfg_block_num_reg;
    reg [31:0] cfg_pre_sample_num_reg;
    reg [31:0] cfg_post_sample_num_reg;
    reg [31:0] status_reg;

    //------------------------------------------------------------------------------------

    localparam [31:0] IPIDENTIFICATION = 32'hF7DEC7A5;
    localparam [31:0] REVISION = "V1.1";
    localparam [31:0] BUILDTIME = 32'h20240106;

    reg  [                31:0] test_reg;
    wire                        wr_active;
    wire                        rd_active;

    wire                        user_reg_rreq;
    wire                        user_reg_wreq;
    reg                         user_reg_rack;
    reg                         user_reg_wack;
    wire [C_APB_ADDR_WIDTH-1:0] user_reg_raddr;
    reg  [C_APB_DATA_WIDTH-1:0] user_reg_rdata;
    wire [C_APB_ADDR_WIDTH-1:0] user_reg_waddr;
    wire [C_APB_DATA_WIDTH-1:0] user_reg_wdata;

    assign user_reg_rreq  = ~s_pwrite & s_psel & s_penable;
    assign user_reg_wreq  = s_pwrite & s_psel & s_penable;
    assign s_pready       = user_reg_rack | user_reg_wack;
    assign user_reg_raddr = s_paddr;
    assign user_reg_waddr = s_paddr;
    assign s_prdata       = user_reg_rdata;
    assign user_reg_wdata = s_pwdata;
    assign s_pslverr      = 1'b0;

    assign rd_active      = user_reg_rreq;
    assign wr_active      = user_reg_wreq & user_reg_wack;

    always @(posedge clk, posedge rst_i) begin
        if (rst_i) begin
            user_reg_rack <= 1'b0;
            user_reg_wack <= 1'b0;
        end else begin
            user_reg_rack <= user_reg_rreq & ~user_reg_rack;
            user_reg_wack <= user_reg_wreq & ~user_reg_wack;
        end
    end

    //------------------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            rst_i <= 1'b1;
        end else begin
            rst_i <= rst;
        end
    end

    //-------------------------------------------------------------------------------------------------------------------------------------------
    //Read Register
    //-------------------------------------------------------------------------------------------------------------------------------------------
    always @(posedge clk, posedge rst_i) begin
        if (rst_i) begin
            user_reg_rdata <= 32'd0;
        end else begin
            user_reg_rdata <= 32'd0;
            if (rd_active) begin
                case (user_reg_raddr)
                    ADDR_ID:              user_reg_rdata <= IPIDENTIFICATION;
                    ADDR_REVISION:        user_reg_rdata <= REVISION;
                    ADDR_BUILDTIME:       user_reg_rdata <= BUILDTIME;
                    ADDR_TEST:            user_reg_rdata <= test_reg;
                    ADDR_TBYTES:          user_reg_rdata <= TBYTES;
                    ADDR_CTRL:            user_reg_rdata <= {soft_rst_i, 30'b0, |cfg_update_reg};
                    ADDR_STATE:           user_reg_rdata <= status_reg;
                    ADDR_BLOCK_NUM:       user_reg_rdata <= cfg_block_num_reg;
                    ADDR_PRE_SAMPLE_NUM:  user_reg_rdata <= cfg_pre_sample_num_reg;
                    ADDR_POST_SAMPLE_NUM: user_reg_rdata <= cfg_post_sample_num_reg;
                    ADDR_STS_BLOCK_NUM:   user_reg_rdata <= sts_sample_block_num;
                    default:              user_reg_rdata <= 32'hdeadbeef;
                endcase
            end else begin
                ;
            end
        end
    end

    //-------------------------------------------------------------------------------------------------------------------------------------------
    //Write Register
    //-------------------------------------------------------------------------------------------------------------------------------------------
    assign soft_rst = soft_rst_i;
    always @(posedge clk, posedge rst_i) begin
        if (rst_i) begin
            soft_rst_i <= 1'b1;
        end else begin
            if (wr_active && (user_reg_waddr == ADDR_CTRL)) begin
                soft_rst_i <= user_reg_wdata[31];
            end else begin
                soft_rst_i <= 1'b0;
            end
        end
    end

    always @(posedge clk, posedge soft_rst_i) begin
        if (soft_rst_i) begin
            cfg_update_reg <= 2'b00;
        end else begin
            if (wr_active && (user_reg_waddr == ADDR_CTRL)) begin
                cfg_update_reg <= {1'b0, user_reg_wdata[0]};
            end else begin
                if (cfg_update_reg[0]) begin
                    cfg_update_reg <= 2'b10;
                end else if (cfg_update_reg[1]) begin
                    cfg_update_reg <= 2'b00;
                end else begin
                    ;
                end
            end
        end
    end
    assign cfg_update = cfg_update_reg[1];

    always @(posedge clk, posedge soft_rst_i) begin
        if (soft_rst_i) begin
            test_reg                <= 32'd0;
            cfg_block_num_reg       <= 32'd0;
            cfg_pre_sample_num_reg  <= 32'd0;
            cfg_post_sample_num_reg <= 32'd0;
        end else begin
            if (wr_active) begin
                test_reg                <= test_reg;
                cfg_block_num_reg       <= cfg_block_num_reg;
                cfg_pre_sample_num_reg  <= cfg_pre_sample_num_reg;
                cfg_post_sample_num_reg <= cfg_post_sample_num_reg;
                case (user_reg_waddr)
                    ADDR_TEST:            test_reg <= user_reg_wdata;
                    ADDR_BLOCK_NUM:       cfg_block_num_reg <= user_reg_wdata;
                    ADDR_PRE_SAMPLE_NUM:  cfg_pre_sample_num_reg <= user_reg_wdata;
                    ADDR_POST_SAMPLE_NUM: cfg_post_sample_num_reg <= user_reg_wdata;
                    default:              ;
                endcase
            end else begin
                ;
            end
        end
    end

    always @(posedge clk, posedge soft_rst_i) begin
        if (soft_rst_i) begin
            status_reg <= 0;
        end else begin
            if (wr_active && (user_reg_waddr == ADDR_STATE)) begin
                status_reg <= status_reg & ~user_reg_wdata;
            end else begin
                status_reg[0] = status_reg[0] | sts_sample_block_done;
                status_reg[1] <= sts_sample_busy;
            end
        end
    end

    assign cfg_block_num       = cfg_block_num_reg;
    assign cfg_pre_sample_num  = cfg_pre_sample_num_reg;
    assign cfg_post_sample_num = cfg_post_sample_num_reg;

endmodule

// verilog_format: off
`resetall
// verilog_format: on
