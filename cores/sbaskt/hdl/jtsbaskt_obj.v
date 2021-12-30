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

wire [ 7:0] obj1_dout, obj2_dout,
            low_dout, hi_dout;
wire        obj1_we, obj2_we;
wire [ 8:0] scan_addr;
wire        even_cs, odd_cs;

// wire [ 7:0] pal_addr;
// wire [ 3:0] pal_data;

assign odd_cs   = obj_cs & cpu_addr[0];
assign even_cs  = obj_cs & ~cpu_addr[0];
assign obj_dout = cpu_addr[0] ? obj1_dout : obj2_dout;
assign obj1_we  = odd_cs  & ~cpu_rnw;
assign obj2_we  = even_cs & ~cpu_rnw;
assign scan_addr = 0;

// even address
jtframe_dual_ram #(.aw(9),.simfile("obj2.bin")) u_hi(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[8:0] ),
    .we0    ( obj1_we       ),
    .q0     ( obj1_dout     ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( scan_addr     ),
    .we1    ( 1'b0          ),
    .q1     ( hi_dout       )
);

// odd address
jtframe_dual_ram #(.aw(9),.simfile("obj1.bin")) u_low(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[8:0] ),
    .we0    ( obj2_we       ),
    .q0     ( obj2_dout     ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( scan_addr     ),
    .we1    ( 1'b0          ),
    .q1     ( low_dout      )
);



endmodule