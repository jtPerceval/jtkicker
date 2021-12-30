/*  This file is part of JTKICKER.
    JTKICKER program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTKICKER program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTKICKER.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 30-12-2021 */

module jtsbaskt_obj(
    input               rst,
    input               clk,        // 48 MHz
    input               clk24,      // 24 MHz

    input               pxl_cen,

    // CPU interface
    input         [9:0] cpu_addr,
    input         [7:0] cpu_dout,
    input               obj_cs,
    input               cpu_rnw,
    output        [7:0] obj_dout,
    input               obj_frame,

    // video inputs
    input               hinit,
    input               LHBL,
    input               LVBL,
    input         [7:0] vrender,
    input         [8:0] hdump,
    input               flip,

    // PROMs
    input         [3:0] prog_data,
    input         [7:0] prog_addr,
    input               prog_en,

    // SDRAM
    output reg   [13:0] rom_addr,
    input        [31:0] rom_data,
    output reg          rom_cs,
    input               rom_ok,

    output        [3:0] pxl,
    input         [7:0] debug_bus
);

parameter [7:0] HOFFSET = 8'd6;

reg fr; // write frame

wire        obj_we;
wire [ 9:0] scan_addr;
wire [ 7:0] scan_dout, tbl_dout;
wire        fr_we;
reg         div_cen;

// wire [ 7:0] pal_addr;
// wire [ 3:0] pal_data;

assign obj_we    = obj_cs & ~cpu_rnw;
assign scan_addr = { 1'b0, obj_frame, hdump[7:0] };
assign fr_we     = vrender == 8'h40 && pxl_cen && LHBL;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        fr <= 0;
        div_cen <= 0;
    end else begin
        if( vrender==8 && hinit && pxl_cen ) fr <= ~fr;
        div_cen <= ~div_cen;
    end
end

// even address
jtframe_dual_ram #(.aw(10),.simfile("obj.bin")) u_hi(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr      ),
    .we0    ( obj_we        ),
    .q0     ( obj_dout      ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( scan_addr     ),
    .we1    ( 1'b0          ),
    .q1     ( scan_dout     )
);

// frame buffer for 64 sprites (256 bytes)
wire [8:0] rd_addr;

jtframe_dual_ram #(.aw(9)) u_low(
    // Port 0, write
    .clk0   ( clk           ),
    .data0  ( cpu_dout      ),
    .addr0  ({ fr,hdump[7:0]^8'h3}), // reorder: y,x,attr,code
    .we0    ( fr_we         ),
    .q0     (               ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( rd_addr       ),
    .we1    ( 1'b0          ),
    .q1     ( tbl_dout      )
);

// scan the current frame
reg  [5:0] obj_cnt;
reg  [1:0] sub;
reg  [7:0] xpos, code, attr;
reg  [3:0] ysub;
wire [7:0] ydiff;
reg  [1:0] rd_st;

wire       inzone;
reg        busy=0;
reg        done, draw;

assign rd_addr = { ~fr, obj_cnt, sub };
assign ydiff   = vrender-tbl_dout;
assign inzone  = ydiff < 8'h10;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        done    <= 0;
        obj_cnt <= 0;
        sub     <= 0;
        rd_st   <= 0;
        draw    <= 0;
    end else if( div_cen ) begin
        draw <= 0;
        if( hinit ) begin
            done <= 0;
            obj_cnt <= 0;
            sub <= 0;
            rd_st <= 0;
        end else if( !done ) begin
            rd_st <= rd_st + 2'd1;
            case( rd_st )
                0: begin
                    if( inzone ) begin
                        sub  <= 1;
                        ysub <= ydiff[3:0];
                    end else begin
                        obj_cnt <= obj_cnt + 6'd1;
                        if( &obj_cnt ) done <= 1;
                        rd_st <= 0;
                    end
                end
                1: begin
                    xpos <= tbl_dout;
                    sub  <= 2;
                end
                2: begin
                    code <= tbl_dout;
                    sub <= 3;
                end
                3: if( !busy ) begin
                    attr <= tbl_dout;
                    sub <= 0;
                    obj_cnt <= obj_cnt + 6'd1;
                    if( &obj_cnt ) done <= 1;
                    draw <= 1;
                end
            endcase
        end
    end
end

endmodule