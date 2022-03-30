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

    output        [3:0] pxl
);

parameter  [7:0] HOFFSET = 8'd6;
localparam [4:0] MAXOBJ  = 5'd24; // 24*16=384 objects x pixels per object = pixels per line
// Max sprites drawn before the raster line count moves
localparam [4:0] HALF     = 5'd19;

wire [ 7:0] scan_dout;
wire        obj_we;
reg  [ 6:0] scan_addr;
reg  [10:0] eff_scan;
wire [ 3:0] pal_data;
wire        sel;

assign obj_we  = oram_cs & ~cpu_rnw;

jtframe_dual_ram #(.aw(11),.simfile("oram.bin")) u_hi(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr      ),
    .we0    ( obj_we        ),
    .q0     ( obj_dout      ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ( eff_scan      ),
    .we1    ( 1'b0          ),
    .q1     ( scan_dout     )
);

reg        cen2=0;
reg        inzone;
wire       done;
reg        hinit_x;
reg  [2:0] scan_st;

reg  [7:0] dr_attr, dr_xpos;
reg  [7:0] dr_code;
reg  [3:0] dr_v;
reg        dr_start;
wire [7:0] ydiff;
reg  [7:0] dr_y;
// It doesn't seem to need the 1 pixel adjustment, I need to check the PCB video output...
//wire       adj;

reg        hflip, vflip;
wire       dr_busy;
wire [4:0] pal;

//assign adj    = REV_SCAN ? scan_addr[5:1]<HALF : scan_addr[5:1]>HALF;
assign ydiff  = vrender-dr_y-8'd1;
assign done   = scan_addr[6:2]==0;

assign pal    = dr_attr[4:0];

always @* begin
    // The original count is done with H256&H128,~H256,H64,H32,H16
    // So it
    eff_scan = {4'd0,scan_addr};
    hflip = dr_attr[6];
    vflip = dr_attr[7];
    dr_y   = ~scan_dout;// + ( adj ? 8'h1 : 8'h0 );
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
                scan_addr <= {MAXOBJ, 2'd0};
                scan_st   <= 1;
            end
            1: begin
                dr_v   <= ydiff[3:0];
                inzone <= dr_y>=vrender && dr_y<(vrender+8'h10);
                scan_st <= scan_st+3'd1;
                scan_addr[1:0] <= scan_addr[1:0] + 2'd1;
            end
            2: begin
                dr_code   <= scan_dout;
                scan_st <= scan_st+3'd1;
                scan_addr[1:0] <= scan_addr[1:0] + 2'd1;
            end
            3: begin
                dr_xpos <= scan_dout;
                scan_addr[1:0] <= scan_addr[1:0] + 2'd1;
                // The PCB has a design flaw where the attribute is
                // latched for 16 pixels, that makes the hardware read
                // the previous object data instead of the current!
                // They got around it with a software change
                scan_addr[6:2] <= scan_addr[6:2]-5'd1;
                scan_st <= scan_st+3'd1;
            end
            4: if(!dr_busy) begin
                dr_start <= inzone;
                dr_attr  <= scan_dout;
                scan_addr[1:0] <= 0;
                scan_st  <= done ? 0 : 5;
            end
            5: scan_st <= 1; // give time to dr_busy to rise
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