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
    Date: 15-11-2021 */

// This module captures the logic in
// custom chips 083 and 502

module jtkicker_obj(
    input               rst,
    input               clk,        // 48 MHz
    input               clk24,      // 24 MHz

    input               pxl_cen,

    // CPU interface
    input        [10:0] cpu_addr,
    input         [7:0] cpu_dout,
    input               obj1_cs,
    input               obj2_cs,
    input               cpu_rnw,
    output        [7:0] obj_dout,

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

parameter BYPASS_PROM=0, LARGE_ROM=0;
parameter [7:0] HOFFSET = 8'd6;

wire [ 7:0] obj1_dout, obj2_dout, pal_addr,
            low_dout, hi_dout;
wire        obj1_we, obj2_we;
reg  [ 5:0] scan_addr;
wire [ 3:0] pal_data;

assign obj_dout = obj1_cs ? obj1_dout : obj2_dout;
assign obj1_we  = obj1_cs & ~cpu_rnw;
assign obj2_we  = obj2_cs & ~cpu_rnw;

// Mapped at 0x3000
jtframe_dual_ram u_hi(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[9:0] ),
    .we0    ( obj1_we       ),
    .q0     ( obj1_dout     ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ({4'd0,scan_addr}),
    .we1    ( 1'b0          ),
    .q1     ( hi_dout       )
);

// Mapped at 0x2800
jtframe_dual_ram u_low(
    // Port 0, CPU
    .clk0   ( clk24         ),
    .data0  ( cpu_dout      ),
    .addr0  ( cpu_addr[9:0] ),
    .we0    ( obj2_we       ),
    .q0     ( obj2_dout     ),
    // Port 1
    .clk1   ( clk           ),
    .data1  (               ),
    .addr1  ({4'd0,scan_addr}),
    .we1    ( 1'b0          ),
    .q1     ( low_dout      )
);

wire [3:0] buf_in;
reg  [7:0] buf_a;
reg        buf_we;
reg        cen2=0;
wire       inzone, done;
reg        hinit_x;
reg  [1:0] scan_st;

reg  [7:0] dr_attr, dr_code, dr_xpos;
reg  [3:0] dr_v;
reg        dr_start, dr_busy;
wire [7:0] ydiff, dr_y;

assign dr_y   = ~low_dout;
assign inzone = dr_y>=vrender && dr_y<(vrender+8'h10) && dr_y<8'hfe;
assign ydiff  = vrender-dr_y-4'd1;
assign done   = scan_addr[5:1]==23;

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
                scan_addr <= 0;
                scan_st   <= 1;
            end
            1: if(!dr_busy) begin
                dr_xpos   <= hi_dout;
                dr_attr   <= low_dout;
                scan_addr <= scan_addr+6'd1;
                scan_st   <= 2;
            end
            2: begin
                dr_code   <= hi_dout;
                dr_v      <= ydiff[3:0];
                scan_addr <= scan_addr+6'd1;
                if( inzone ) begin
                    dr_start <= 1;
                end
                scan_st   <= done ? 0 : 3;
            end
            3: scan_st <= 1; // give time to dr_busy to rise
        endcase
    end
end

// Draw
reg  [31:0] pxl_data;
reg  [ 2:0] dr_cnt;
wire        hflip, vflip;

assign pal_addr = { dr_attr[3:0], pxl_data[3:0] };
assign hflip    = dr_attr[6];
assign vflip    = dr_attr[7];

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        dr_busy  <= 0;
        rom_cs   <= 0;
        rom_addr <= 0;
        pxl_data <= 0;
        buf_we   <= 0;
        buf_a    <= 0;
        dr_cnt   <= 0;
    end else if( cen2 ) begin
        if( dr_start && !dr_busy ) begin
            rom_addr <= { LARGE_ROM ? dr_attr[0] : 1'b0, dr_code, dr_v^{4{vflip}}, 1'b0 };
            rom_cs   <= 1;
            dr_cnt   <= 7;
            buf_a    <= dr_xpos + (hflip ? 8'd15 : 8'h0) + HOFFSET;
            dr_busy  <= 1;
        end
        if( dr_busy && (!rom_cs || rom_ok) ) begin
            if( dr_cnt==7 && rom_cs ) begin
                pxl_data <= {
                    rom_data[27], rom_data[31], rom_data[19], rom_data[23],
                    rom_data[26], rom_data[30], rom_data[18], rom_data[22],
                    rom_data[25], rom_data[29], rom_data[17], rom_data[21],
                    rom_data[24], rom_data[28], rom_data[16], rom_data[20],
                    rom_data[11], rom_data[15], rom_data[ 3], rom_data[ 7],
                    rom_data[10], rom_data[14], rom_data[ 2], rom_data[ 6],
                    rom_data[ 9], rom_data[13], rom_data[ 1], rom_data[ 5],
                    rom_data[ 8], rom_data[12], rom_data[ 0], rom_data[ 4]
                };
                buf_we <= 1;
                rom_cs <= 0;
            end else begin
                pxl_data <= pxl_data>>4;
                buf_a  <= hflip ? buf_a-8'd1 : buf_a+8'd1;
                dr_cnt <= dr_cnt - 3'd1;
            end
            if( !dr_cnt ) begin
                if( rom_addr[0] ) begin
                    buf_we  <= 0;
                    dr_busy <= 0;
                    rom_cs  <= 0;
                end else begin
                    rom_addr[0] <= 1;
                    rom_cs      <= 1;
                end
            end
        end
    end
end

wire buf_clr;

assign buf_clr = pxl_cen & LHBL;

jtframe_obj_buffer #(.AW(8),.DW(4), .ALPHA(0)) u_buffer(
    .clk    ( clk       ),
    .LHBL   ( LHBL      ),
    // New data writes
    .wr_data( buf_in    ),
    .wr_addr( buf_a     ),
    .we     ( buf_we    ),
    // Old data reads (and erases)
    .rd_addr( hdump[7:0]),
    .rd     ( buf_clr   ),  // data will be erased after the rd event
    .rd_data( pxl       )
);

generate
    if( BYPASS_PROM ) begin
        assign buf_in = pal_addr[3:0];
    end else begin
        jtframe_prom #(
            .dw     ( 4         ),
            .aw     ( 8         )
        //    simfile = "477j08.f16",
        ) u_palette(
            .clk    ( clk       ),
            .cen    ( 1'b1      ),
            .data   ( prog_data ),
            .wr_addr( prog_addr ),
            .we     ( prog_en   ),

            .rd_addr( pal_addr  ),
            .q      ( buf_in    )
        );
    end
endgenerate


endmodule