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
    Date: 14-11-2021 */

module jtkicker_scroll(
    input               clk,        // 48 MHz
    input               clk24,      // 24 MHz

    input               pxl_cen,
    input         [2:0] pal_sel,

    // CPU interface
    input        [10:0] cpu_addr,
    input         [7:0] cpu_din,
    input               vram_we,
    output        [7:0] vram_dout,

    // video inputs
    input               LHBL,
    input               LVBL,
    input         [7:0] vdump,
    input         [7:0] hdump,
    input               flip,

    // PROMs
    input         [3:0] prog_data,
    input         [7:0] prog_addr,
    input               prog_en,

    // SDRAM
    output   reg [11:0] rom_addr,
    input        [31:0] rom_data,
    input               rom_ok,

    output        [3:0] pxl,
);

wire [7:0] code, attr, vram_high, vram_low;
wire [3:0] pal_msb;
reg  [9:0] rd_addr;
reg  [7:0] vdf, hdf;
wire       vram_we_low, vram_high;
wire       vflip;

assign vram_we_low  = vram_we & ~cpu_addr[10];
assign vram_we_high = vram_we &  cpu_addr[10];
assign vram_dout    = cpu_addr[10] ? vram_high : vram_low;

assign vflip = attr[5];
assign hflip = attr[4];
assign code_msb = attr[7:6];
assign pal_msb  = attr[3:0];

always @(*) begin
    vdf = {8{flip}} ^ vdump;
    hdf = {8{flip}} ^ hdump;
end

jtframe_dual_ram u_low(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[9:0] ),
    .we0    ( vram_we_low   ),
    .q0     ( vram_low      ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( rd_addr       ),
    .we1    ( 1'b0          ),
    .q1     ( code          )
);

jtframe_dual_ram u_high(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[9:0] ),
    .we0    ( vram_we_high  ),
    .q0     ( vram_high     ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( rd_addr       ),
    .we1    ( 1'b0          ),
    .q1     ( attr          )
);

jtframe_prom #(
    .dw ( 4     ),
    .aw ( 8     )
//    simfile = "477j10.a12",
) u_palette(
    .clk    ( clk       ),
    .cen    ( pxl_cen   ),
    .data   ( prog_data ),
    .wr_addr( prog_addr ),
    .we     ( prog_en   ),

    .rd_addr( pal_addr  ),
    .q      ( raw[3:0]  )
);

endmodule