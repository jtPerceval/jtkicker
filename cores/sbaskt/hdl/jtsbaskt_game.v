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

module jtsbaskt_game(
    input           rst,
    input           clk,
    input           rst24,
    input           clk24,
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [3:0]  red,
    output   [3:0]  green,
    output   [3:0]  blue,
    output          LHBL_dly,
    output          LVBL_dly,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 6:0]  joystick1,
    input   [ 6:0]  joystick2,
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
    output reg [21:0] prog_addr,
    output reg [ 7:0] prog_data,
    output reg [ 1:0] prog_mask,
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
    input   [ 3:0]  gfx_en,
    input   [ 7:0]  debug_bus
);

// SDRAM offsets
localparam [21:0] SND_START   =  `SND_START,
                  SCR_START   =  `SCR_START,
                  OBJ_START   =  `OBJ_START,
                  PCM_START   =  `PCM_START;
localparam [24:0] PROM_START  =  `PROM_START;

wire        main_cs, main_ok;

wire [12:0] scr_addr;
wire [13:0] obj_addr;
wire [31:0] scr_data, obj_data;
wire        scr_ok, obj_ok, objrom_cs;
wire [12:0] snd_addr;
wire [ 7:0] snd_data;
wire        snd_ok, snd_cs;

wire [ 7:0] main_data;
wire [15:0] main_addr;
wire [ 3:0] cen_base;

wire [ 7:0] dipsw_a, dipsw_b;
wire        LVBL, V16;

wire [ 3:0] pal_sel;
wire        obj_frame;
wire        cpu_cen, cpu4_cen, ti1_cen, ti2_cen;
wire        cpu_rnw, cpu_irqn, cpu_nmin;
wire        vscr_cs, vram_cs, objram_cs,
            prom_we, flip;
wire [ 7:0] vscr_dout, vram_dout, obj_dout, cpu_dout;
wire        vsync60;
wire        snd_cen, psg_cen;

// PCM
wire [15:0] pcm_addr;
wire [ 7:0] pcm_data;
wire        pcm_ok;

wire        m2s_on, m2s_data;

assign prog_rd    = 0;
assign dwnld_busy = downloading;
assign { dipsw_b, dipsw_a } = dipsw[15:0];
assign dip_flip = flip;
assign vsync60  = status[13];   // high to use a 6MHz pixel clock, instead of 6.144MHz

// Using an integer divider for the 6.144MHz
// cen_base will probably help with the video
// compatibility in MiSTer. MiST seems to be
// doing well with the fractional divider.
jtframe_frac_cen #(.W(4)) u_cen (
    .clk    ( clk       ),
    .n      ( vsync60 ? 10'd1 : 10'd32    ),
    .m      ( vsync60 ? 10'd4 : 10'd125   ),
    .cen    ( cen_base  ),
    .cenb   (           ) // 180 shifted
);

jtframe_crossclk_cen u_cpu_cen(
    .clk_in     ( clk       ),
    .cen_in     ( pxl2_cen  ),
    .clk_out    ( clk24     ),
    .cen_out    ( cpu4_cen  )   // 6MHz
);

jtframe_cen3p57 u_cen3p57(
    .clk      ( clk     ),       // 48 MHz
    .cen_3p57 ( snd_cen ),
    .cen_1p78 ( psg_cen )
);

wire [21:0] pre_addr;
wire [ 7:0] nc, pre_data;
wire [ 1:0] pre_mask;

assign pxl2_cen = cen_base[0]; // ~12MHz
assign pxl_cen  = cen_base[1]; // ~ 6MHz

function [3:0] mirror( input [3:0] a );
    // mirror = { a[0], a[1], a[2], a[3] };
    mirror = { a[3], a[2], a[1], a[0] };
endfunction

always @(*) begin
    prog_addr = pre_addr;
    prog_data = pre_data;
    prog_mask = pre_mask;
    if( ioctl_addr[21:0] >= SCR_START && ioctl_addr[21:0]<PCM_START ) begin
        //prog_mask = {pre_mask[0],pre_mask[1]};
        //prog_data = { mirror(pre_data[3:0]), mirror(pre_data[7:4])};
        prog_data = { mirror(pre_data[3:0]), mirror(pre_data[7:4])};
        // prog_addr[0] = pre_addr[0];
        // prog_addr[1] = pre_addr[1];
        //prog_addr[3:1] =  pre_addr[2:0];
    end
    //if( ioctl_addr[21:0] >= OBJ_START && ioctl_addr[21:0]<PCM_START ) begin
    //    prog_addr[0]   = ~pre_addr[3];
    //    prog_addr[1]   = ~pre_addr[4];
    //    prog_addr[5:2] =  { pre_addr[5], pre_addr[2:0] }; // making [5] explicit for now
    //end
end

`ifndef NOMAIN
jtsbaskt_main u_main(
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

    .vscr_cs        ( vscr_cs       ),
    .vram_cs        ( vram_cs       ),
    .vram_dout      ( vram_dout     ),
    .vscr_dout      ( vscr_dout     ),

    .objram_cs      ( objram_cs     ),
    .obj_dout       ( obj_dout      ),
    .obj_frame      ( obj_frame     ),
    // Sound control
    .snd_data_cs    ( m2s_data      ),
    .snd_on_cs      ( m2s_on        ),
    // GFX configuration
    .pal_sel        ( pal_sel       ),
    .flip           ( flip          ),
    // interrupt triggers
    .LVBL           ( LVBL          ),
    .V16            ( V16           ),
    // DIP switches
    .dip_pause      ( dip_pause     ),
    .dipsw_a        ( dipsw_a       ),
    .dipsw_b        ( dipsw_b       )
);
`else
    assign main_cs = 0;
    assign objram_cs = 0;
    assign snd     = 0;
    assign sample  = 0;
    assign game_led= 0;
    assign pal_sel = 0;
    assign flip    = 0;
    assign pcm_addr= 0;
`endif

`ifndef NOSOUND
jtsbaskt_snd u_sound(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .snd_cen    ( snd_cen   ),    // 3.5MHz
    .psg_cen    ( psg_cen   ),    // 1.7MHz
    // ROM
    .rom_addr   ( snd_addr  ),
    .rom_cs     ( snd_cs    ),
    .rom_data   ( snd_data  ),
    .rom_ok     ( snd_ok    ),
    // From main CPU
    .main_dout  ( cpu_dout  ),
    .m2s_data   ( m2s_data  ),
    .m2s_on     ( m2s_on    ),
    // Sound
    .pcm_addr   ( pcm_addr  ),
    .pcm_data   ( pcm_data  ),
    .pcm_ok     ( pcm_ok    ),

    .snd        ( snd       ),
    .sample     ( sample    ),
    .peak       ( game_led  )
);
`else
    assign snd_cs=0;
    assign snd_addr=0;
    assign pcm_addr=0;
    assign snd=0;
    assign sample=0;
`endif

/* verilator tracing_off */
jtsbaskt_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk24      ( clk24     ),

    .pxl_cen    ( pxl_cen   ),
    .pxl2_cen   ( pxl2_cen  ),

    // configuration
    .pal_sel    ( pal_sel   ),
    .flip       ( flip      ),

    // CPU interface
    .cpu_addr   ( main_addr[10:0]  ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_rnw    ( cpu_rnw   ),
    // Scroll
    .vram_cs    ( vram_cs   ),
    .vscr_cs    ( vscr_cs   ),
    .vram_dout  ( vram_dout ),
    .vscr_dout  ( vscr_dout ),
    // Objects
    .objram_cs  ( objram_cs ),
    .obj_dout   ( obj_dout  ),
    .obj_frame  ( obj_frame ),

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

    .LVBL       ( LVBL      ),
    .V16        ( V16       ),
    .HS         ( HS        ),
    .VS         ( VS        ),
    .LHBL_dly   ( LHBL_dly  ),
    .LVBL_dly   ( LVBL_dly  ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    .gfx_en     ( gfx_en    ),
    .debug_bus  ( debug_bus )
);

jtframe_dwnld #(.PROM_START(PROM_START),.SWAB(1))
u_dwnld(
    .clk            ( clk           ),
    .downloading    ( downloading   ),
    .ioctl_addr     ( ioctl_addr    ),
    .ioctl_dout     ( ioctl_dout    ),
    .ioctl_wr       ( ioctl_wr      ),
    .prog_addr      ( pre_addr      ),
    .prog_data      ( {nc,pre_data} ),
    .prog_mask      ( pre_mask      ), // active low
    .prog_we        ( prog_we       ),
    .prom_we        ( prom_we       ),
    .sdram_ack      ( sdram_ack     ),
    .header         (               )
);

jtframe_rom #(
    .SLOT0_AW    ( 14              ),
    .SLOT0_DW    ( 32              ),
    .SLOT0_OFFSET( SCR_START>>1    ),

    .SLOT1_AW    ( 15              ),
    .SLOT1_DW    ( 32              ),
    .SLOT1_OFFSET( OBJ_START>>1    ),

    .SLOT2_AW    ( 16              ),
    .SLOT2_DW    (  8              ),
    .SLOT2_OFFSET( PCM_START>>1    ),

    .SLOT6_AW    ( 13              ),
    .SLOT6_DW    (  8              ),
    .SLOT6_OFFSET( SND_START>>1    ), // Sound CPU

    .SLOT7_AW    ( 16              ),
    .SLOT7_DW    (  8              ),
    .SLOT7_OFFSET(  0              )  // Main
) u_rom (
    .rst         ( rst           ),
    .clk         ( clk           ),

    .slot0_cs    ( LVBL          ),
    .slot1_cs    ( objrom_cs     ),
    .slot2_cs    ( 1'b1          ),
    .slot3_cs    ( 1'b0          ),
    .slot4_cs    ( 1'b0          ),
    .slot5_cs    ( 1'b0          ),
    .slot6_cs    ( snd_cs        ),
    .slot7_cs    ( main_cs       ),
    .slot8_cs    ( 1'b0          ),

    .slot0_ok    ( scr_ok        ),
    .slot1_ok    ( obj_ok        ),
    .slot2_ok    ( pcm_ok        ),
    .slot3_ok    (               ),
    .slot4_ok    (               ),
    .slot5_ok    (               ),
    .slot6_ok    ( snd_ok        ),
    .slot7_ok    ( main_ok       ),
    .slot8_ok    (               ),

    .slot0_addr  ({scr_addr,1'b0}),
    .slot1_addr  ({obj_addr,1'b0}),
    .slot2_addr  ( pcm_addr      ),
    .slot3_addr  (               ),
    .slot4_addr  (               ),
    .slot5_addr  (               ),
    .slot6_addr  ( snd_addr      ),
    .slot7_addr  ( main_addr     ),
    .slot8_addr  (               ),

    .slot0_dout  ( scr_data      ),
    .slot1_dout  ( obj_data      ),
    .slot2_dout  ( pcm_data      ),
    .slot3_dout  (               ),
    .slot4_dout  (               ),
    .slot5_dout  (               ),
    .slot6_dout  ( snd_data      ),
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