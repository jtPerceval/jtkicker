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
    Date: 15-8-2022 */

module jtroc_game(
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
    input      [3:0] gfx_en,
    input      [7:0] debug_bus,
    output reg [7:0] debug_view,
    // Memory ports
    `include "mem_ports.inc"
);

// SDRAM offsets
localparam [21:0] SND_START   =  `SND_START,
                  SCR_START   =  `SCR_START,
                  OBJ_START   =  `OBJ_START;

localparam [24:0] PROM_START  =  `JTFRAME_PROM_START;

wire [10:0] cpu_addr;
wire [ 7:0] st_main;

wire        cpu_cen, cpu4_cen, ti1_cen, ti2_cen;
wire        cpu_rnw, cpu_irqn, cpu_nmin;
wire        vram_cs, objram_cs, flip;
wire [ 7:0] vram_dout, obj_dout, cpu_dout;

// Sound
wire [ 7:0] snd_latch;
wire        mute, snd_on;

wire        m2s_on;
reg  [24:0] dwn_addr;

assign dip_flip   = ~flip;

always @(*) begin
    case( debug_bus[1:0])
        0: debug_view = 0;
        1: debug_view = st_main;
        2: debug_view = snd_latch;
        3: debug_view = st_snd;
    endcase
end

always @(*) begin
    post_addr = prog_addr;
    if( ioctl_addr[21:0] >= SCR_START && ioctl_addr[21:0]<OBJ_START ) begin
        post_addr[0]   = ~prog_addr[3];
        post_addr[3:1] =  prog_addr[2:0];
    end
    if( ioctl_addr[21:0] >= OBJ_START && ioctl_addr[21:0]<PROM_START ) begin
        post_addr[0]   = ~prog_addr[3];
        post_addr[1]   = ~prog_addr[4];
        post_addr[5:2] =  { prog_addr[5], prog_addr[2:0] }; // making [5] explicit for now
    end
end

jtkicker_clocks u_clocks(
    .status     ( status    ),
    // 24 MHz domain
    .clk24      ( clk24     ),
    .cpu4_cen   ( cpu4_cen  ),
    .snd_cen    (           ),
    .psg_cen    (           ),
    .ti1_cen    (           ),
    .ti2_cen    (           ),
    // 48 MHz domain
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .pxl2_cen   ( pxl2_cen  )
);

`ifndef NOMAIN
jtroc_main u_main(
    .rst            ( rst24         ),
    .clk            ( clk24         ),        // 24 MHz
    .cpu4_cen       ( cpu4_cen      ),
    .cpu_cen        ( cpu_cen       ),
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

    .bus_addr       ( cpu_addr      ),
    .vram_cs        ( vram_cs       ),
    .vram_dout      ( vram_dout     ),

    .objram_cs      ( objram_cs     ),
    .obj_dout       ( obj_dout      ),
    // Sound control
    .snd_latch      ( snd_latch     ),
    .snd_on         ( snd_on        ),
    .mute           ( mute          ),
    // GFX configuration
    .flip           ( flip          ),
    // interrupt triggers
    .LVBL           ( LVBL          ),
    // DIP switches
    .dip_pause      ( dip_pause     ),
    .dipsw          ( dipsw[23:0]   ),
    .st_dout        ( st_main       )
);
`else
    assign objram_cs = 0;
    assign vram_cs   = 0;
    assign cpu_rnw   = 1;
    assign cpu_addr  = 0;
    assign cpu_dout  = 0;
    assign flip      = 1;
`endif

`ifndef NOSOUND
jtroc_snd u_sound(
    .rst        ( rst24     ),
    .clk        ( clk24     ),
    // ROM
    .rom_addr   ( snd_addr  ),
    .rom_cs     ( snd_cs    ),
    .rom_data   ( snd_data  ),
    .rom_ok     ( snd_ok    ),
    // From main CPU
    .main_latch ( snd_latch ),
    .snd_on     ( snd_on    ),
    .mute       ( mute      ),
    // Sound
    .snd        ( snd       ),
    .sample     ( sample    ),
    .peak       ( game_led  ),
    .st_dout    ( st_snd    )
);
`else
    assign snd_cs=0;
    assign snd_addr=0;
    assign snd=0;
    assign st_snd=0;
    assign sample=0;
    assign game_led=0;
`endif

jtroc_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk24      ( clk24     ),

    .pxl_cen    ( pxl_cen   ),
    .pxl2_cen   ( pxl2_cen  ),

    // configuration
    .flip       ( flip      ),

    // CPU interface
    .cpu_addr   ( cpu_addr[10:0]  ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_rnw    ( cpu_rnw   ),
    // Scroll
    .vram_cs    ( vram_cs   ),
    .vram_dout  ( vram_dout ),
    // Objects
    .objram_cs  ( objram_cs ),
    .obj_dout   ( obj_dout  ),

    // PROMs
    .prog_data  ( prog_data ),
    .prog_addr  ( post_addr[9:0] ),
    .prom_en    ( prom_we   ),

    // Scroll
    .scr_addr   ( scr_addr  ),
    .scr_data   ( scr_data  ),
    .scr_ok     ( scr_ok    ),
    // Objects
    .obj_addr   ( objrom_addr ),
    .obj_data   ( objrom_data ),
    .obj_cs     ( objrom_cs ),
    .obj_ok     ( objrom_ok ),

    .HS         ( HS        ),
    .VS         ( VS        ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    .gfx_en     ( gfx_en    ),
    .debug_bus  ( debug_bus )
);

endmodule