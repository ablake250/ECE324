set_property SRC_FILE_INFO {cfile:{c:/Users/Axelb/Documents/School/WSU Spring 2019/ECE 324/Lab10/Lab10.srcs/sources_1/ip/videoClk108MHz/videoClk108MHz.xdc} rfile:../../../Lab10.srcs/sources_1/ip/videoClk108MHz/videoClk108MHz.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports CLK100MHZ]] 0.1
