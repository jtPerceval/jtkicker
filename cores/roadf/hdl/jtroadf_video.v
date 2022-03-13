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
    Date: 12-3-2022 */

module jtroadf_video(
    input               rst,
    input               clk,        // 48 MHz
    input               clk24,      // 24 MHz

    input               pxl_cen,
    input               pxl2_cen,

    // configuration
    input               flip,

    // CPU interface
    input        [11:0] cpu_addr,
    input         [7:0] cpu_dout,
    input               cpu_rnw,

    input               vram_cs,
    output        [7:0] vram_dout,

    input               objram_cs,
    output        [7:0] obj_dout,
    input               obj_frame,

    // PROMs
    input         [7:0] prog_data,
    input        [10:0] prog_addr,
    input               prom_en,

    // Scroll
    output       [12:0] scr_addr,
    input        [31:0] scr_data,
    input               scr_ok,

    // Objects
    output       [13:0] obj_addr,
    input        [31:0] obj_data,
    output              obj_cs,
    input               obj_ok,

    output              HS,
    output              VS,
    output              LVBL,
    output              LHBL_dly,
    output              LVBL_dly,
    output        [3:0] red,
    output        [3:0] green,
    output        [3:0] blue,
    input         [3:0] gfx_en,
    input         [7:0] debug_bus
);

localparam LAYOUT=4;

wire       LHBL, hinit;
wire [8:0] vdump, vrender, hdump;
wire       vscr_cs=0;
wire [3:0] obj_pxl, scr_pxl;
reg  [3:0] prom_we;

always @* begin
    prom_we = 0;
    prom_we[ prog_addr[9:8] ] = prom_en;
    if( prom_we[0] && prog_addr[7:5]!=0 ) prom_we = 0;
end

jtkicker_vtimer #(.LAYOUT(LAYOUT)) u_vtimer(
    .clk    ( clk       ),
    .pxl_cen( pxl_cen   ),
    .vdump  ( vdump     ),
    .vrender( vrender   ),
    .hdump  ( hdump     ),
    .hinit  ( hinit     ),
    .LHBL   ( LHBL      ),
    .LVBL   ( LVBL      ),
    .HS     ( HS        ),
    .VS     ( VS        )
);

wire [ 7:0] vdumpx = vdump[7:0]+8'd1;
wire [10:0] vscr_addr = { cpu_addr[11:6], cpu_addr[4:0] }; // bit 5 is always low for video output
    // the memory at bit 5 is considered normal RAM and handled in main

jtkicker_scroll #(.LAYOUT(LAYOUT),.NOSCROLL(1)) u_scroll(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk24      ( clk24     ),

    .pxl_cen    ( pxl_cen   ),

    // CPU interface
    .cpu_addr   ( vscr_addr ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_rnw    ( cpu_rnw   ),
    .vram_cs    ( vram_cs   ),
    .vscr_cs    ( vscr_cs   ),
    .vram_dout  ( vram_dout ),
    .vscr_dout  (           ),

    // video inputs
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .vdump      ( vdumpx    ),
    .hdump      ( hdump     ),
    .flip       ( flip      ),

    // PROMs
    .prog_data  ( prog_data[3:0] ),
    .prog_addr  ( prog_addr[7:0] ),
    .prog_en    ( prom_we[2]),

    // SDRAM
    .rom_addr   ( scr_addr  ),
    .rom_data   ( scr_data  ),
    .rom_ok     ( scr_ok    ),

    .prio       (           ),
    .pxl        ( scr_pxl   ),
    .debug_bus  ( debug_bus )
);

jtroadf_obj u_obj(
    .rst        ( rst       ),
    .clk        ( clk       ),      // 48 MHz
    .clk24      ( clk24     ),      // 24 MHz

    .pxl_cen    ( pxl_cen   ),

    // CPU interface
    .cpu_addr   ( cpu_addr[9:0] ),
    .cpu_dout   ( cpu_dout  ),
    .obj_cs     ( objram_cs ),
    .cpu_rnw    ( cpu_rnw   ),
    .obj_dout   ( obj_dout  ),
    .obj_frame  ( obj_frame ),

    // video inputs
    .hinit      ( hinit     ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .vrender    (vrender[7:0]),
    .hdump      ( hdump     ),
    .flip       ( flip      ),

    // PROMs
    .prog_data  ( prog_data[3:0] ),
    .prog_addr  ( prog_addr[7:0] ),
    .prog_en    ( prom_we[1]),

    // SDRAM
    .rom_cs     ( obj_cs    ),
    .rom_addr   ( obj_addr  ),
    .rom_data   ( obj_data  ),
    .rom_ok     ( obj_ok    ),
    .debug_bus  ( debug_bus ),

    .pxl        ( obj_pxl   )
);

jtyiear_colmix u_colmix(
    .clk        ( clk       ),

    .pxl_cen    ( pxl_cen   ),

    // video inputs
    .obj_pxl    ( obj_pxl   ),
    .scr_pxl    ( scr_pxl   ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),

    // PROMs
    .prog_data  (prog_data  ),
    .prog_addr  (prog_addr[4:0]),
    .prog_en    (prom_we[0] ),

    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    .LHBL_dly   ( LHBL_dly  ),
    .LVBL_dly   ( LVBL_dly  ),
    .gfx_en     ( gfx_en    )
);

endmodule