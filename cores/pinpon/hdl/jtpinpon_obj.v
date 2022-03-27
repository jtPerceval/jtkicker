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
    Date: 27-3-2022 */

module jtpinpon_obj(
    input               rst,
    input               clk,        // 48 MHz
    input               clk24,      // 24 MHz

    input               pxl_cen,

    // CPU interface
    input        [10:0] cpu_addr,
    input         [7:0] cpu_dout,
    input               oram_cs,
    input               cpu_rnw,
    output        [7:0] obj_dout,

    // video inputs
    input               hinit,
    input               LHBL,
    input               LVBL,
    input         [7:0] vrender,
    input         [8:0] hdump,

    // PROMs
    input         [3:0] prog_data,
    input         [7:0] prog_addr,
    input               prog_en,

    // SDRAM
    output       [11:0] rom_addr,
    input        [31:0] rom_data,
    output              rom_cs,
    input               rom_ok,

    output        [3:0] pxl,
    input         [7:0] debug_bus
);

parameter [7:0] HOFFSET = 8'd6;
localparam      MAXOBJ  = 6'd23;

wire [ 7:0] obj1_dout, obj2_dout,
            low_dout, hi_dout;
wire        obj1_we, obj2_we;
reg  [ 6:0] scan_addr;  // most games only scan 32 objects, but Mikie scans a bit further
                        // the schematics are a bit blurry, so it isn't clear how it goes
                        // about it. It may well be that it is scanning 32 objects too but
                        // the table has blanks and it spans over more than 32 entries
reg  [ 9:0] eff_scan;
wire [ 3:0] pal_data;
wire        sel;

assign sel      = ~cpu_addr[10];
assign obj_dout = sel ? obj1_dout : obj2_dout;
assign obj1_we  = oram_cs &  sel & ~cpu_rnw;
assign obj2_we  = oram_cs & !sel & ~cpu_rnw;

jtframe_dual_ram #(.simfile("obj2.bin")) u_hi(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[9:0] ),
    .we0    ( obj1_we       ),
    .q0     ( obj1_dout     ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( eff_scan      ),
    .we1    ( 1'b0          ),
    .q1     ( hi_dout       )
);

jtframe_dual_ram #(.simfile("obj1.bin")) u_low(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[9:0] ),
    .we0    ( obj2_we       ),
    .q0     ( obj2_dout     ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( eff_scan      ),
    .we1    ( 1'b0          ),
    .q1     ( low_dout      )
);

// Max sprites drawn before the raster line count moves
localparam [4:0] HALF     = 5'd19;
localparam       REV_SCAN = 1;

reg        cen2=0;
wire       inzone, done;
reg        hinit_x;
reg  [1:0] scan_st;

reg  [7:0] dr_attr, dr_xpos;
reg  [7:0] dr_code;
reg  [3:0] dr_v;
reg        dr_start;
wire [7:0] ydiff;
reg  [7:0] dr_y;
wire       adj;

reg        hflip, vflip;
wire       dr_busy;
wire [4:0] pal;

assign adj    = REV_SCAN ? scan_addr[5:1]<HALF : scan_addr[5:1]>HALF;
assign inzone = dr_y>=vrender && dr_y<(vrender+8'h10);
assign ydiff  = vrender-dr_y-8'd1;
assign done   = REV_SCAN ? scan_addr[6:1]==0 : scan_addr[6:1]==MAXOBJ;

assign pal    = dr_attr[4:0];

always @* begin
    eff_scan = {3'd0,scan_addr};
    hflip = dr_attr[6];
    vflip = dr_attr[7];
    dr_y   = ~low_dout + ( adj ? 8'h1 : 8'h0 );
end

always @(posedge clk) begin
    cen2 <= ~cen2;
    if( hinit ) hinit_x <= 1;
    else if(cen2) hinit_x <= 0;
end

// Table scan
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        scan_st  <= 0;
        dr_start <= 0;
    end else if( cen2 ) begin
        dr_start <= 0;
        case( scan_st )
            0: if( hinit_x ) begin
                scan_addr <= REV_SCAN  ? {MAXOBJ, 1'd0} : 7'd0;
                scan_st   <= 1;
            end
            1: if(!dr_busy) begin
                dr_xpos   <= hi_dout;
                dr_attr   <= low_dout;
                scan_addr[0] <= ~scan_addr[0];
                scan_st   <= 2;
            end
            2: begin
                dr_code   <= hi_dout;
                dr_v      <= ydiff[3:0];
                scan_addr[0] <= 0;
                scan_addr[6:1] <= REV_SCAN ? scan_addr[6:1]-6'd1 : scan_addr[6:1]+6'd1;
                if( inzone ) begin
                    dr_start <= 1;
                end
                scan_st   <= done ? 0 : 3;
            end
            3: scan_st <= 1; // give time to dr_busy to rise
        endcase
    end
end

jtpinpon_objdraw #(
    .HOFFSET    ( HOFFSET   )
) u_draw (
    .rst        ( rst       ),
    .clk        ( clk       ),        // 48 MHz

    .pxl_cen    ( pxl_cen   ),
    .cen2       ( cen2      ),
    // video inputs
    .LHBL       ( LHBL      ),
    .hinit_x    ( hinit_x   ),
    .hdump      ( hdump     ),

    // control
    .draw       ( dr_start  ),
    .busy       ( dr_busy   ),

    // Object table data
    .code       ( dr_code   ),
    .xpos       ( dr_xpos   ),
    .pal        ( pal       ),
    .hflip      ( hflip     ),
    .vflip      ( vflip     ),
    .ysub       ( dr_v      ),

    // PROMs
    .prog_data  ( prog_data ),
    .prog_addr  ( prog_addr ),
    .prog_en    ( prog_en   ),

    // SDRAM
    .rom_cs     ( rom_cs    ),
    .rom_addr   ( rom_addr  ),
    .rom_data   ( rom_data  ),
    .rom_ok     ( rom_ok    ),

    .pxl        ( pxl       )
);

endmodule