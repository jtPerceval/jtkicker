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

module jtsbaskt_main(
    input               rst,
    input               clk,        // 24 MHz
    input               cpu4_cen,   // 6 MHz
    output              cpu_cen,    // Q clock
    // ROM
    output      [15:0]  rom_addr,
    output reg          rom_cs,
    input       [ 7:0]  rom_data,
    input               rom_ok,
    // cabinet I/O
    input       [ 1:0]  start_button,
    input       [ 1:0]  coin_input,
    input       [ 6:0]  joystick1,
    input       [ 6:0]  joystick2,
    input               service,

    // GFX
    output              cpu_rnw,
    output      [ 7:0]  cpu_dout,
    output reg          vscr_cs,
    output reg          vram_cs,
    output reg          obj1_cs,
    output reg          obj2_cs,

    // configuration
    output reg  [ 2:0]  pal_sel,
    output reg          flip,

    // interrupt triggers
    input               LVBL,
    input               V16,

    input      [7:0]    vram_dout,
    input      [7:0]    vscr_dout,  // output from Konami 085 custom chip
    input      [7:0]    obj_dout,
    // DIP switches
    input               dip_pause,
    input      [7:0]    dipsw_a,
    input      [7:0]    dipsw_b
);

reg  [ 7:0] cabinet, cpu_din;
wire [15:0] A;
wire        RnW, irq_n, nmi_n;
wire        irq_trigger, nmi_trigger;
reg         nmi_clrn, irq_clrn;
reg         ior_cs, in5_cs, in6_cs,
            intshow_cs,
            color_cs, iow_cs;
// reg         afe_cs; // watchdog
wire        VMA;

assign irq_trigger = ~LVBL & dip_pause;
assign nmi_trigger =  V16;
assign cpu_rnw     = RnW;
assign rom_addr    = A;

always @(*) begin
    rom_cs  = VMA && A[15:13]>2 && RnW && VMA; // ROM = 4000 - FFFF
    iow_cs     = 0;
    // afe_cs     = 0;
    intshow_cs = 0;
    ti2_cs     = 0;
    ti1_cs     = 0;
    in5_cs    = 0;
    in6_cs    = 0;
    ior_cs     = 0;
    color_cs   = 0;
    vscr_cs    = 0;
    obj1_cs    = 0;
    obj2_cs    = 0;
    vram_cs    = 0;
    if( VMA && A[15:13]==1 ) begin // 2???
        case( A[12:11] )
            0: obj1_cs    = 1;
            1: obj2_cs    = 1;
            2: vram_cs    = 1;
            3: if( A[10] )
                case( A[9:7] )
                    0: case(6:4)
                        // 0: watchdog
                        1: int_cs = 1;
                        2: colorset_cs = 1;
                        3: intshow_cs = 1;
                        default:;
                    endcase
                    1: iow_cs      = 1;
                    2: snd_data_cs = 1;
                    3: snd_on_cs   = 1;
                    4: ior_cs      = 1;
                    5: in5_cs      = 1;
                    6: in6_cs      = 1;
                    7: vgap_cs     = 1;
                endcase
                3: color_cs   = 1;
                4: vscr_cs    = 1;  // vertical scroll position
        endcase
    end
end

always @(posedge clk) begin
    case( A[6:5] )
        0: cabinet <= { ~3'd0, start_button, service, coin_input };
        1: cabinet <= {2'b11, joystick1[5:4], joystick1[2], joystick1[3], joystick1[0], joystick1[1]};
        2: cabinet <= {2'b11, joystick2[5:4], joystick2[2], joystick2[3], joystick2[0], joystick2[1]};
        3: cabinet <= 8'hff;
    endcase
    cpu_din <= rom_cs  ? rom_data  :
               vram_cs ? vram_dout :
               intshow_cs ? vscr_dout :
               (obj1_cs | obj2_cs) ? obj_dout  :
               ior_cs  ? cabinet :
               in6_cs  ? dipsw_a :
               in5_cs  ? dipsw_b : 8'hff;
end

always @(posedge clk) begin
    if( rst ) begin
        nmi_clrn <= 0;
        irq_clrn <= 0;
        flip     <= 0;
        pal_sel  <= 0;
    end else if(cpu_cen) begin
        if( iow_cs && !RnW ) begin
            nmi_clrn <= cpu_dout[1];
            irq_clrn <= cpu_dout[2];
            flip     <= cpu_dout[0];
        end
        if( color_cs ) pal_sel <= cpu_dout[2:0];
    end
end

jtframe_ff u_irq(
    .rst      ( rst         ),
    .clk      ( clk         ),
    .cen      ( 1'b1        ),
    .din      ( 1'b1        ),
    .q        (             ),
    .qn       ( irq_n       ),
    .set      (             ),    // active high
    .clr      ( ~irq_clrn   ),    // active high
    .sigedge  ( irq_trigger )     // signal whose edge will trigger the FF
);

jtframe_sys6809 #(.RAM_AW(0)) u_cpu(
    .rstn       ( ~rst      ),
    .clk        ( clk       ),
    .cen        ( cpu4_cen  ),   // This is normally the input clock to the CPU
    .cpu_cen    ( cpu_cen   ),   // 1/4th of cen -> 3MHz

    // Interrupts
    .nIRQ       ( irq_n     ),
    .nFIRQ      ( 1'b1      ),
    .nNMI       ( 1'b1      ),
    .irq_ack    (           ),
    // Bus sharing
    .bus_busy   ( 1'b0      ),
    .waitn      (           ),
    // memory interface
    .A          ( A         ),
    .RnW        ( RnW       ),
    .VMA        ( VMA       ),
    .ram_cs     ( 1'b0      ),
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    ),
    // Bus multiplexer is external
    .ram_dout   (           ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_din    ( cpu_din   )
);

endmodule
