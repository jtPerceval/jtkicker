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

// This module captures the logic in
// custom chips 083 and 502
// The line count will change while the chips are
// still rendering the previous line, so the software
// writes some sprites with a -1 position in order
// to compensate. This happens after a certain
// position in the sprite table

// Road Fighter uses two object RAMs selectable
// by a bit called obj_frame. Each table is 1kB long
// but only the lower quarter is readable by
// the sprite hardware. The rest is available to
// the CPU. obj_frame must mean something, but I cannot
// make up what it is

module jtroadf_obj(
    input               rst,
    input               clk,        // 48 MHz
    input               clk24,      // 24 MHz

    input               pxl_cen,

    // CPU interface
    input         [9:0] cpu_addr,
    input         [7:0] cpu_dout,
    input               obj_cs,
    input               obj_frame, // called INTST in the schematics
    input               cpu_rnw,
    output        [7:0] obj_dout,

    // video inputs
    input               hinit,
    input               LHBL,
    input               LVBL,
    input         [8:0] vdump,
    input         [8:0] hdump,
    input               flip,

    // Row scroll
    output reg    [7:0] hpos,
    output reg          scr_we,

    // PROMs
    input         [3:0] prog_data,
    input         [7:0] prog_addr,
    input               prog_en,

    // SDRAM
    output       [13:0] rom_addr,
    input        [31:0] rom_data,
    output              rom_cs,
    input               rom_ok,

    output        [3:0] pxl,
    input         [7:0] debug_bus
);

parameter [7:0] HOFFSET = 8'd6;
localparam [5:0] MAXOBJ = 6'd23;

wire [ 7:0] obj1_dout, obj2_dout,
            rd1_dout, rd2_dout, scan_dout;
wire        obj1_we, obj2_we;
reg  [ 6:0] scan_addr;  // although the DMA bus in the schematics has 8 bits
    // it shouldn't be able to pass sprite count 23, as the line buffers
    // are written at the pixel clock and the table scan count is reset
    // to zero at the beginning of each raster line
reg  [ 9:0] eff_scan;
wire [ 3:0] pal_data;
reg         scr_rd;

assign obj_dout = obj_frame ? obj1_dout : obj2_dout;
assign obj1_we  = obj_cs &  obj_frame & ~cpu_rnw;
assign obj2_we  = obj_cs & ~obj_frame & ~cpu_rnw;
assign scan_dout= obj_frame ? rd2_dout : rd1_dout;

// two sprite tables
jtframe_dual_ram #(.simfile("obj.bin")) u_hi(
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
    .q1     ( rd1_dout      )
);

jtframe_dual_ram #(.simfile("obj.bin")) u_low(
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
    .q1     ( rd2_dout      )
);

// Max sprites drawn before the raster line count moves
localparam [4:0] HALF = 5'd19;

reg        cen2=0;
wire       done;
reg        inzone;
reg        hinit_x;
reg  [2:0] scan_st;

reg  [7:0] dr_attr, dr_xpos;
reg  [8:0] dr_code;
reg  [3:0] dr_v;
reg        dr_start;
wire [7:0] ydiff;
reg  [7:0] dr_y, ypos;
wire [7:0] vdf;
wire       adj;

reg        hflip, vflip;
wire       dr_busy;
wire [3:0] pal;

assign vdf    = vdump[7:0] ^ {8{flip}};
assign ydiff  = vdf-dr_y-8'd1;
assign done   = scan_addr[6:2]==5'h1f;
assign pal    = dr_attr[3:0];
assign adj    = 0;

always @* begin
    eff_scan = { 2'd0, scr_rd, scan_addr};
    hflip = dr_attr[6];
    vflip = dr_attr[7];
    dr_y   = ~ypos + ( adj ? ( flip ? 8'hff : 8'h1 ) : 8'h0 );
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
        scr_rd   <= 0;
        scr_we   <= 0;
    end else if( cen2 ) begin
        dr_start <= 0;
        scr_we   <= 0;
        case( scan_st )
            0: if( hinit_x ) begin
                scr_rd    <= 1;
                scan_addr <= { 1'b1, vdf[7:3], vdump[8] };
                scan_st   <= 6;
            end
            1: if(!dr_busy) begin
                dr_attr   <= scan_dout;
                scan_st   <= 2;
                scan_addr[1:0] <= scan_addr[1:0]+1'd1;
            end
            2: begin
                ypos <= scan_dout;
                scan_st <= 3;
                scan_addr[1:0] <= scan_addr[1:0]+1'd1;
            end
            3: begin
                dr_code   <= { dr_attr[5], scan_dout };
                dr_v      <= ydiff[3:0];
                inzone    <= dr_y>=vdf && dr_y<(vdf+8'h10);
                scan_st   <= 4;
                scan_addr[1:0] <= scan_addr[1:0]+1'd1;
            end
            4: begin
                dr_xpos   <= scan_dout;
                scan_st   <= 5;
                dr_start  <= inzone;
                scan_addr <= { scan_addr[6:2]-5'd1,2'b0};
            end
            5: begin // give time to dr_busy to rise
                dr_start<= 0;
                scan_st <= done ? 0 : 1;
            end
            6: begin // Reads the row scroll value
                scr_we   <= 1;
                hpos     <= scan_dout;
                scr_rd   <= 0;
                scan_addr<= 7'd23<<2;
                scan_st  <= 1;
            end
        endcase
    end
end

jtkicker_objdraw #(
    .BYPASS_PROM    ( 0        ),
    .HOFFSET        ( HOFFSET  )
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

    .debug_bus  ( debug_bus ),
    .pxl        ( pxl       )
);

endmodule