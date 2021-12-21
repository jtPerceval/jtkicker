../../../kicker/hdl/jtkicker_game.v
../../../kicker/hdl/jtkicker_obj.v
../../../kicker/hdl/jtkicker_scroll.v
../../../kicker/hdl/jtkicker_vtimer.v
../../hdl/jtyiear_main.v
../../hdl/jtyiear_video.v
../../hdl/jtyiear_colmix.v

${JTFRAME}/hdl/cpu/jtframe_z80wait.v

# Clocking
${JTFRAME}/hdl/clocking/jtframe_frac_cen.v
${JTFRAME}/hdl/clocking/jtframe_crossclk_cen.v

# Other
${JTFRAME}/hdl/jtframe_ff.v
${JTFRAME}/hdl/jtframe_sh.v
${JTFRAME}/hdl/ram/jtframe_ram.v
${JTFRAME}/hdl/ram/jtframe_prom.v
${JTFRAME}/hdl/sdram/jtframe_dwnld.v
${JTFRAME}/hdl/sdram/jtframe_rom.v

# Video
${JTFRAME}/hdl/video/jtframe_vtimer.v
${JTFRAME}/hdl/ram/jtframe_obj_buffer.v
${JTFRAME}/hdl/video/jtframe_blank.v

# Sound
${JTFRAME}/hdl/sound/jtframe_mixer.v

-F ${JTFRAME}/hdl/sdram/jtframe_sdram64.f
