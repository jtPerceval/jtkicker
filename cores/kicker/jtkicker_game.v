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

module jtkicker_game(
    input           rst,
    input           clk,
    input           rst24,
    input           clk24,
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [4:0]  red,
    output   [4:0]  green,
    output   [4:0]  blue,
    output          LHBL_dly,
    output          LVBL_dly,
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
    output reg [21:0] prog_addr,
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

// SDRAM offsets.
localparam GFX_OFFSET  =  `GFX_START>>1;
localparam PCM0_OFFSET =  'hA_0000>>1;
localparam PCM1_OFFSET =  'hC_0000>>1;
localparam PROM_START  =  'h140000;

wire        main_cs, main_ok, gfx_cs, gfx_ok;
wire [15:0] gfx_data;
wire [17:0] gfx_addr;

wire [ 7:0] main_data;
wire [16:0] main_addr;
wire [ 2:0] cen_base;

wire [ 7:0] dipsw_a, dipsw_b;
wire [ 3:0] dipsw_c;
wire        LHBL, LVBL;

wire [13:0] cpu_addr;
wire        gfx_irqn, gfx_romcs, pal_cs;
wire        cpu4_cen, cpu_cen, cpu_rnw, cpu_irqn, cpu_nmin;
wire [ 7:0] gfx_dout, pal_dout, cpu_dout;

assign prog_rd    = 0;
assign dwnld_busy = downloading;
assign { dipsw_c, dipsw_b, dipsw_a } = dipsw[19:0];
assign dip_flip = ~flip;

jtframe_frac_cen #(.W(3)) u_cen (
    .clk    ( clk       ),
    .n      ( 10'd16    ),
    .m      ( 10'd125   ),
    .cen    ( cen_base  ),
    .cenb   (           ) // 180 shifted
);

jtframe_crossclk_cen u_cpu_cen(
    .clk_in     ( clk       ),
    .cen_in     ( pxl_cen   ),
    .clk_out    ( clk24     ),
    .cen_out    ( cpu4_cen  )   // 6MHz
);

jtframe_crossclk_cen u_ti1_cen(
    .clk_in     ( clk       ),
    .cen_in     ( pxl2_cen  ),
    .clk_out    ( clk24     ),
    .cen_out    ( ti1_cen   )   // 3MHz
);

jtframe_crossclk_cen u_ti2_cen(
    .clk_in     ( clk       ),
    .cen_in     (cen_base[2]),
    .clk_out    ( clk24     ),
    .cen_out    ( ti2_cen   )   // 1.5MHz
);

wire [21:0] pre_prog;

assign pxl_cen  = cen_base[0]; // ~6MHz
assign pxl2_cen = cen_base[1]; // ~3MHz

always @(*) begin
    prog_addr = pre_prog;
    if( ioctl_addr > SCR_START && ioctl_addr<OBJ_START ) begin
        prog_addr[0]   = pre_prog[3];
        prog_addr[3:1] = pre_prog[2:0];
    end
end

jtframe_dwnld #(.PROM_START(PROM_START),.SWAB(1))
u_dwnld(
    .clk            ( clk           ),
    .downloading    ( downloading   ),
    .ioctl_addr     ( ioctl_addr    ),
    .ioctl_dout     ( ioctl_dout    ),
    .ioctl_wr       ( ioctl_wr      ),
    .prog_addr      ( pre_addr      ),
    .prog_data      ( prog_data     ),
    .prog_mask      ( prog_mask     ), // active low
    .prog_we        ( prog_we       ),
    .prom_we        ( prom_we       ),
    .sdram_ack      ( sdram_ack     ),
    .header         (               )
);

`ifndef NOMAIN
jtkicker_main u_main(
    .clk            ( clk24         ),        // 24 MHz
    .rst            ( rst24         ),
    .cpu4_cen       ( cpu4_cen      ),
    .cpu_cen        ( cpu_cen       ),
    .ti1_cen        ( ti1_cen       ),
    .ti2_cen        ( ti2_cen       ),
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
    .flip           ( flip          ),
    .gfx_addr       ( cpu_addr      ),
    .cpu_dout       ( cpu_dout      ),
    .cpu_rnw        ( cpu_rnw       ),
    .gfx_irqn       ( cpu_irqn      ),
    .gfx_nmin       ( cpu_nmin      ),
    .gfx_cs         ( gfx_cs        ),
    .pal_cs         ( pal_cs        ),

    .gfx_dout       ( gfx_dout      ),
    .pal_dout       ( pal_dout      ),

    // DIP switches
    .dip_pause      ( dip_pause     ),
    .dipsw_a        ( dipsw_a       ),
    .dipsw_b        ( dipsw_b       ),
    .dipsw_c        ( dipsw_c       ),
    // Sound
    .snd            ( snd           ),
    .sample         ( sample        ),
    .peak           ( game_led      )
);
`else
assign main_cs = 0;
`endif

`ifndef NOVIDEO
jtkicker_video u_video (
    .rst            ( rst           ),
    .clk            ( clk           ),
    .clk24          ( clk24         ),
    .pxl2_cen       ( pxl2_cen      ),
    .pxl_cen        ( pxl_cen       ),
    .LHBL           ( LHBL          ),
    .LVBL           ( LVBL          ),
    .LHBL_dly       ( LHBL_dly      ),
    .LVBL_dly       ( LVBL_dly      ),
    .HS             ( HS            ),
    .VS             ( VS            ),
    .flip           ( flip          ),
    .dip_pause      ( dip_pause     ),
    .start_button   ( &start_button ),
    // PROMs
    .prom_we        ( prom_we       ),
    .prog_addr      ( prog_addr[8:0]),
    .prog_data      ( prog_data[3:0]),
    // GFX - CPU interface
    .gfx_cs         ( gfx_cs        ),
    .cpu_rnw        ( cpu_rnw       ),
    .cpu_cen        ( cpu_cen       ),
    .cpu_addr       ( cpu_addr      ),
    .cpu_dout       ( cpu_dout      ),
    .gfx_dout       ( gfx_dout      ),
    // SDRAM
    .gfx_addr       (  gfx_addr     ),
    .gfx_data       (  gfx_data     ),
    .gfx_ok         (  gfx_ok       ),
    .gfx_romcs      (  gfx_romcs    ),
    // pixels
    .red            ( red           ),
    .green          ( green         ),
    .blue           ( blue          )
    // Test
    //.gfx_en         ( gfx_en        )
);
`endif

jtframe_rom #(
    .SLOT0_AW    ( 18              ),
    .SLOT0_DW    ( 16              ),
    .SLOT0_OFFSET( GFX_OFFSET      ),

    // PCM 0
    .SLOT1_AW    ( 17              ),
    .SLOT1_DW    (  8              ),
    .SLOT1_OFFSET( PCM0_OFFSET     ),

    .SLOT7_AW    ( 17              ),
    .SLOT7_DW    (  8              ),
    .SLOT7_OFFSET(  0              )  // Main
) u_rom (
    .rst         ( rst           ),
    .clk         ( clk           ),

    .slot0_cs    ( gfx1_romcs    ),
    .slot1_cs    ( gfx2_romcs    ),
    .slot2_cs    ( 1'b0          ),
    .slot3_cs    ( 1'b0          ), // unused
    .slot4_cs    ( 1'b0          ), // unused
    .slot5_cs    ( 1'b0          ), // unused
    .slot6_cs    ( 1'b0          ),
    .slot7_cs    ( main_cs       ),
    .slot8_cs    ( 1'b0          ),

    .slot0_ok    ( gfx1_ok       ),
    .slot1_ok    ( pcma_ok       ),
    .slot2_ok    ( pcmb_ok       ),
    .slot3_ok    ( pcmc_ok       ),
    .slot4_ok    ( pcmd_ok       ),
    .slot5_ok    (               ),
    .slot6_ok    (               ),
    .slot7_ok    ( main_ok       ),
    .slot8_ok    (               ),

    .slot0_addr  ( gfx_addr      ),
    .slot1_addr  ( pcma_addr     ),
    .slot2_addr  ( pcmb_addr     ),
    .slot3_addr  ( pcmc_addr     ),
    .slot4_addr  ( pcmd_addr     ),
    .slot5_addr  (               ),
    .slot6_addr  (               ),
    .slot7_addr  ( main_addr     ),
    .slot8_addr  (               ),

    .slot0_dout  ( gfx_data      ),
    .slot1_dout  ( pcma_dout     ),
    .slot2_dout  ( pcmb_dout     ),
    .slot3_dout  ( pcmc_dout     ),
    .slot4_dout  ( pcmd_dout     ),
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