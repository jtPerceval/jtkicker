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

module jtsbaskt_snd(
    input               rst,
    input               clk,
    input               snd_cen,    // 3.5MHz
    input               psg_cen,    // 1.7MHz
    // ROM
    output      [12:0]  rom_addr,
    output reg          rom_cs,
    input       [ 7:0]  rom_data,
    input               rom_ok,
    // From main CPU
    input       [ 7:0]  main_dout,
    input               m2s_data,
    input               m2s_on,
    // Sound
    output     [15:0]   pcm_addr,
    input      [ 7:0]   pcm_data,
    input               pcm_ok,

    output signed [15:0] snd,
    output               sample,
    output               peak
);

localparam CNTW=11;

reg  [ 7:0] latch, psg_data, vlm_data, din;
wire [ 7:0] ram_dout, vlm_mux, dout;
wire        irq_ack, int_n;
wire [ 2:0] pcm_nc;
wire        vlm_ceng, vlm_me_b;
wire [10:0] psg_snd;
reg         ram_cs;
wire        mreq_n, iorq_n;
wire [15:0] A;
reg  [ 2:0] snd_en;
wire        rdy1;
reg         vlm_rst, vlm_st, vlm_sel;
wire        vlm_bsy;
reg         psgdata_cs, vlm_data_cs, vlm_ctrl_cs;
reg         latch_cs, cnt_cs, rdac_cs, psg_cs;
reg [CNTW-1:0] cnt;
wire signed
         [9:0] vlm_snd;

assign vlm_mux = vlm_sel ? vlm_data :
               ~vlm_me_b ? pcm_data : 8'hff;
assign pcm_addr[15:13]=0;
assign irq_ack = ~iorq_n & ~mreq_n;
assign vlm_ceng = snd_cen & ( vlm_me_b | pcm_ok );
assign rom_addr = A[12:0];

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        latch    <= 0;
        psg_data <= 0;
        cnt      <= 0;
        snd_en   <= 0;
        vlm_rst  <= 1;
        vlm_st   <= 0;
        vlm_sel  <= 0;
    end else begin
        if( psg_cen     ) cnt<=cnt+1'd1;
        if( m2s_data    ) latch <= main_dout;
        if( psgdata_cs  ) psg_data <= dout;
        if( vlm_data_cs ) vlm_data <= dout;
        if( vlm_ctrl_cs ) { snd_en, vlm_rst, vlm_st, vlm_sel } <= A[8:3];
    end
end

always @* begin
    rom_cs      = 0;
    ram_cs      = 0;
    latch_cs    = 0;
    cnt_cs      = 0;
    vlm_data_cs = 0;
    vlm_ctrl_cs = 0;
    rdac_cs     = 0;
    psgdata_cs  = 0;
    psg_cs      = 0;
    if( !mreq_n ) begin
        case(A[15:13])
            0: rom_cs = 1;
            2: ram_cs = 1;
            3: latch_cs = 1;
            4: cnt_cs = 1;
            5: vlm_data_cs = 1;
            6: vlm_ctrl_cs = 1;
            7: case( A[2:0] )
                0: rdac_cs = 1;
                1: psgdata_cs = 1;
                2: psg_cs = 1;
                default:;
            endcase
        endcase
    end
end

always @(posedge clk) begin
    din  <= rom_cs   ? rom_data :
            ram_cs   ? ram_dout :
            cnt_cs   ? { 5'h1f, cnt[CNTW-1:CNTW-2], vlm_bsy }  :
            latch_cs ? latch    :
            8'hff;
end

jt89 u_psg(
    .rst    ( rst           ),
    .clk    ( clk           ),
    .clk_en ( psg_cen       ),
    .wr_n   ( rdy1          ),
    .cs_n   ( ~psg_cs       ),
    .din    ( psg_data      ),
    .sound  ( psg_snd       ),
    .ready  ( rdy1          )
);

vlm5030_gl u_vlm(
    .i_rst   ( vlm_rst      ),
    .i_clk   ( clk          ),
    .i_oscen ( vlm_ceng     ),
    .i_start ( vlm_st       ),
    .i_vcu   ( 1'b0         ),
    .i_tst1  ( 1'b0         ),
    .o_tst2  (              ),
    .o_tst4  (              ),
    .i_d     ( vlm_mux      ),
    .o_a     ( { pcm_nc, pcm_addr[12:0] } ),
    .o_me_l  ( vlm_me_b     ),
    .o_mte   (              ),
    .o_bsy   ( vlm_bsy      ),

    .o_dao   (              ),
    .o_audio ( vlm_snd      )
);

jtframe_mixer #(.W0(11),.W1(10)) u_mixer(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( psg_cen   ),
    // input signals
    .ch0    ( psg_snd   ),
    .ch1    ( vlm_snd   ),
    .ch2    ( 16'd0     ),
    .ch3    ( 16'd0     ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( 8'h18     ),
    .gain1  ( 8'h18     ),
    .gain2  ( 8'h00     ),
    .gain3  ( 8'h00     ),
    .mixed  ( snd       ),
    .peak   ( peak      )
);

jtframe_ff u_irq(
    .rst      ( rst         ),
    .clk      ( clk         ),
    .cen      ( 1'b1        ),
    .din      ( 1'b1        ),
    .q        (             ),
    .qn       ( int_n       ),
    .set      (             ),
    .clr      ( irq_ack     ),
    .sigedge  ( m2s_on      )
);

jtframe_sysz80 #(.RAM_AW(10)) u_cpu(
    .rst_n      ( ~rst        ),
    .clk        ( clk         ),
    .cen        ( snd_cen     ),
    .cpu_cen    (             ),
    .int_n      ( int_n       ),
    .nmi_n      ( 1'b1        ),
    .busrq_n    ( 1'b1        ),
    .m1_n       (             ),
    .mreq_n     ( mreq_n      ),
    .iorq_n     ( iorq_n      ),
    .rd_n       (             ),
    .wr_n       (             ),
    .rfsh_n     (             ),
    .halt_n     (             ),
    .busak_n    (             ),
    .A          ( A           ),
    .cpu_din    ( din         ),
    .cpu_dout   ( dout        ),
    .ram_dout   ( ram_dout    ),
    // manage access to ROM data from SDRAM
    .ram_cs     ( ram_cs      ),
    .rom_cs     ( rom_cs      ),
    .rom_ok     ( rom_ok      )
);


endmodule
