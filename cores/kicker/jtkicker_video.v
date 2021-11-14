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
    Date: 11-11-2021 */

module jtkicker_video(
    input               rst,
    input               clk,        // 48 MHz

    input               pxl_cen,
    input               pxl2_cen,
    // VRAM             

    output              LVBL,
    output              V16,
    output              LVBL_dly,
    output              HVBL_dly
);

wire       LHBL;
wire [8:0] vdump, vrender, hdump;

assign V16 = vdump[4];

// The original counter keeps hdump[7] high
// while hdump[8] is hight (i.e. during HBLANK)
// The rest of the count should match quite well
// the original, particularly VBLANK, H period
// and V period
jtframe_vtimer #(
    .VB_START   (  9'd236   ),
    .VB_END     (  9'd019   ),
    .VCNT_END   (  9'd263   ),
    .VS_START   (  9'd254   ),
    .VS_END     (  9'd2     ),
    .HB_END     (  9'd383   ),
    .HB_START   (  9'd255   ),
    .HCNT_END   (  9'd383   ),
    .HS_START   (  9'd320   ),
    .HS_END     (  9'd338   )
) u_vtimer(
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .vdump      ( vdump     ),
    .vrender    ( vrender   ),
    .vrender1   (           ),
    .H          ( hdump     ),
    .Hinit      (           ),
    .Vinit      (           ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .HS         (           ),
    .VS         (           )
);

endmodule