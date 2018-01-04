// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.3 (win64) Build 2018833 Wed Oct  4 19:58:22 MDT 2017
// Date        : Tue Jan  2 03:28:37 2018
// Host        : DESKTOP-777TLCU running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               z:/vivado/fpga_final_project/fpga_final_project.srcs/sources_1/ip/back2/back2_stub.v
// Design      : back2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_0,Vivado 2017.3" *)
module back2(clka, addra, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,addra[17:0],douta[11:0]" */;
  input clka;
  input [17:0]addra;
  output [11:0]douta;
endmodule