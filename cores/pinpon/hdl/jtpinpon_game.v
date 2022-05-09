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
    Date: 26-3-2022 */

module jtpinpon_game(
    input           rst,
    input           clk,
    input           rst24,
    input           clk24,
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [3:0]  red,
    output   [3:0]  green,
    output   [3:0]  blue,
    output          LHBL,
    output          LVBL,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 5:0]  joystick1,
    input   [ 5:0]  joystick2,
    // SDRAM interface
    input           downloading,
    output          dwnld_busy,
    output          sdram_req,
    output  [21:0]  sdram_addr,
    input   [15:0]  data_read,
    input           data_dst,
    input           data_rdy,
    input           sdram_ack,
    // ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_dout,
    input           ioctl_wr,
    output  [21:0]  prog_addr,
    output  [ 7:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output          prog_we,
    output          prog_rd,
    // DIP switches
    input   [31:0]  status,     // only bits 31:16 are looked at
    input   [31:0]  dipsw,
    input           dip_pause,
    input           service,
    inout           dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB
    // Sound output
    output  signed [15:0] snd,
    output          sample,
    output          game_led,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input   [ 3:0]  gfx_en
);

// SDRAM offsets
localparam [21:0] SCR_START   =  `SCR_START,
                  OBJ_START   =  `OBJ_START;
localparam [24:0] PROM_START  =  `PROM_START;

wire        main_cs, main_ok;

wire [11:0] scr_addr;
wire [11:0] obj_addr;
wire [15:0] scr_data;
wire [31:0] obj_data;
wire        scr_ok, obj_ok, objrom_cs;

wire [ 7:0] main_data;
wire [14:0] main_addr;

wire [ 7:0] dipsw_a, dipsw_b;
wire [ 2:0] dipsw_c; // The bit 3 is not connected on the board
wire        V16;

wire        cpu_cen, cpu4_cen, ti1_cen, ti2_cen;
wire        cpu_rnw, cpu_irqn, cpu_nmin;
wire        vram_cs, oram_cs,
            prom_we, flip;
wire [ 7:0] vram_dout, obj_dout, cpu_dout;
wire        vsync60;

assign prog_rd    = 0;
assign dwnld_busy = downloading;
assign { dipsw_c, dipsw_b, dipsw_a } = dipsw[18:0];
assign dip_flip = flip;
assign game_led= 0;

reg  [24:0] post_addr;
wire [ 7:0] nc;
wire        is_char = ioctl_addr[21:0] >= SCR_START && ioctl_addr[21:0]<OBJ_START;
wire        is_obj  = ioctl_addr[21:0] >= OBJ_START && ioctl_addr[21:0]<PROM_START[21:0];

always @(*) begin
    post_addr = ioctl_addr;
    if( is_char ) begin
        post_addr[0]   =  ioctl_addr[3];
        post_addr[3:1] =  ioctl_addr[2:0]^3'd1;
    end
    if( is_obj ) begin
        post_addr[0]   = ~ioctl_addr[3];
        post_addr[1]   = ~ioctl_addr[4];
        post_addr[5:2] =  { ioctl_addr[5], ioctl_addr[2:0] }; // making [5] explicit for now
    end
end

jtkicker_clocks u_clocks(
    .status     ( status    ),
    // 24 MHz domain
    .clk24      ( clk24     ),
    .cpu4_cen   ( cpu4_cen  ),
    .snd_cen    (           ),
    .psg_cen    (           ),
    .ti1_cen    ( ti1_cen   ),
    .ti2_cen    ( ti2_cen   ),
    // 48 MHz domain
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .pxl2_cen   ( pxl2_cen  )
);

jtframe_dwnld #(.PROM_START(PROM_START),.SWAB(1))
u_dwnld(
    .clk            ( clk           ),
    .downloading    ( downloading   ),
    .ioctl_addr     ( post_addr     ),
    .ioctl_dout     ( ioctl_dout    ),
    .ioctl_wr       ( ioctl_wr      ),
    .prog_addr      ( prog_addr     ),
    .prog_data      ( {nc,prog_data}),
    .prog_mask      ( prog_mask     ), // active low
    .prog_we        ( prog_we       ),
    .prom_we        ( prom_we       ),
    .sdram_ack      ( sdram_ack     ),
    .header         (               )
);

`ifndef NOMAIN
assign snd[4:0]=0;

jtpinpon_main u_main(
    .rst            ( rst24         ),
    .clk            ( clk24         ),        // 24 MHz
    .cpu_cen        ( cpu_cen       ),
    .ti1_cen        ( ti1_cen       ),
    // ROM
    .rom_addr       ( main_addr     ),
    .rom_cs         ( main_cs       ),
    .rom_data       ( main_data     ),
    .rom_ok         ( main_ok       ),
    // cabinet I/O
    .start_button   ( start_button  ),
    .coin_input     ( coin_input    ),
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    .service        ( service       ),
    // GFX
    .cpu_dout       ( cpu_dout      ),
    .cpu_rnw        ( cpu_rnw       ),

    .vram_cs        ( vram_cs       ),
    .vram_dout      ( vram_dout     ),

    .oram_cs        ( oram_cs       ),
    .obj_dout       ( obj_dout      ),
    // GFX configuration
    .flip           ( flip          ),
    // interrupt triggers
    .LVBL           ( LVBL          ),
    .V16            ( V16           ),
    // DIP switches
    .dip_pause      ( dip_pause     ),
    .dipsw_a        ( dipsw_a       ),
    .dipsw_b        ( dipsw_b       ),
    .dipsw_c        ( dipsw_c       ),
    .dip_test       ( dip_test      ),
    // Sound
    .snd            ( snd[15:5]     ),
    .sample         ( sample        )
);
`else
    assign main_cs   = 0;
    assign main_addr = 0;
    assign cpu_rnw   = 1;
    assign cpu_dout  = 0;
    assign vram_cs   = 0;
    assign oram_cs   = 0;
    assign snd       = 0;
    assign sample    = 0;
    assign flip      = 0;
`endif

jtpinpon_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk24      ( clk24     ),

    .pxl_cen    ( pxl_cen   ),
    .pxl2_cen   ( pxl2_cen  ),

    // configuration
    .flip       ( flip      ),

    // CPU interface
    .cpu_addr   ( main_addr[10:0]  ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_rnw    ( cpu_rnw   ),
    // Scroll
    .vram_cs    ( vram_cs   ),
    .vram_dout  ( vram_dout ),
    // Objects
    .oram_cs    ( oram_cs   ),
    .obj_dout   ( obj_dout  ),

    // PROMs
    .prog_data  ( prog_data ),
    .prog_addr  ( prog_addr[10:0] ),
    .prom_en    ( prom_we   ),

    // Scroll
    .scr_addr   ( scr_addr  ),
    .scr_data   ( scr_data  ),
    .scr_ok     ( scr_ok    ),
    // Objects
    .obj_addr   ( obj_addr  ),
    .obj_data   ( obj_data  ),
    .obj_cs     ( objrom_cs ),
    .obj_ok     ( obj_ok    ),

    .V16        ( V16       ),
    .HS         ( HS        ),
    .VS         ( VS        ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    .gfx_en     ( gfx_en    )
);


jtframe_rom #(
    .SLOT0_AW    ( 12              ),
    .SLOT0_DW    ( 16              ), // contrary to other cores in this repo.
    .SLOT0_OFFSET( SCR_START>>1    ),

    .SLOT1_AW    ( 12              ),
    .SLOT1_DW    ( 32              ),
    .SLOT1_OFFSET( OBJ_START>>1    ),

    .SLOT7_AW    ( 15              ),
    .SLOT7_DW    (  8              ),
    .SLOT7_OFFSET(  0              )  // Main
) u_rom (
    .rst         ( rst           ),
    .clk         ( clk           ),

    .slot0_cs    ( LVBL          ),
    .slot1_cs    ( objrom_cs     ),
    .slot2_cs    ( 1'b0          ),
    .slot3_cs    ( 1'b0          ),
    .slot4_cs    ( 1'b0          ),
    .slot5_cs    ( 1'b0          ),
    .slot6_cs    ( 1'b0          ),
    .slot7_cs    ( main_cs       ),
    .slot8_cs    ( 1'b0          ),

    .slot0_ok    ( scr_ok        ),
    .slot1_ok    ( obj_ok        ),
    .slot2_ok    (               ),
    .slot3_ok    (               ),
    .slot4_ok    (               ),
    .slot5_ok    (               ),
    .slot6_ok    (               ),
    .slot7_ok    ( main_ok       ),
    .slot8_ok    (               ),

    .slot0_addr  ( scr_addr      ),
    .slot1_addr  ( obj_addr      ),
    .slot2_addr  (               ),
    .slot3_addr  (               ),
    .slot4_addr  (               ),
    .slot5_addr  (               ),
    .slot6_addr  (               ),
    .slot7_addr  (main_addr[14:0]),
    .slot8_addr  (               ),

    .slot0_dout  ( scr_data      ),
    .slot1_dout  ( obj_data      ),
    .slot2_dout  (               ),
    .slot3_dout  (               ),
    .slot4_dout  (               ),
    .slot5_dout  (               ),
    .slot6_dout  (               ),
    .slot7_dout  ( main_data     ),
    .slot8_dout  (               ),

    // SDRAM interface
    .sdram_req   ( sdram_req     ),
    .sdram_ack   ( sdram_ack     ),
    .data_dst    ( data_dst      ),
    .data_rdy    ( data_rdy      ),
    .downloading ( downloading   ),
    .sdram_addr  ( sdram_addr    ),
    .data_read   ( data_read     )
);

endmodule