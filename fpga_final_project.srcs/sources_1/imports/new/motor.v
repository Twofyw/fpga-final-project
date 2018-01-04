`timescale 1ns / 1ps
// ==============================================================================
// 										  Define Module
//                     Port Declarations
// ==============================================================================
module motor(
  CLK100MHZ, reset, step_x, step_y, signal_x_auto, signal_y_auto
  );
  input               CLK100MHZ;
  input               reset;
  input signed [10:0] step_x; // pixels per 1/60 seconds
  input signed [10:0] step_y;

  output [3:0] signal_x_auto, signal_y_auto;

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  wire                CLK_VAR_x;
  wire                CLK_VAR_y;

  // Map pixels to degrees
  localparam          FACTOR = 20;

  wire          [8:0] dps_x; // >0
  wire          [8:0] dps_y;

  reg           [8:0] dps_x_reg; // >0
  reg           [8:0] dps_y_reg;

  wire          [1:0] dir_x;
  wire          [1:0] dir_y;
// ==============================================================================
// 							              Implementation
// ==============================================================================
  // Consider conversion factor
  always @ (step_x)
    dps_x_reg = (FACTOR * 9 * (step_x[10] == 0 ? step_x : -step_x)) / 5;
  always @ (step_y)
    dps_y_reg = (FACTOR * 9 * (step_y[10] == 0 ? step_y : -step_y)) / 5;
  assign dps_x = dps_x_reg;
  assign dps_y = dps_y_reg;

  assign dir_x = (step_x[10] == 0 ? 2'b01 : 2'b10);
  assign dir_y = (step_y[10] == 0 ? 2'b01 : 2'b10);

  clock_div clkvar_x (.clk(CLK100MHZ),.new_clk(CLK_VAR_x),.dps(dps_x));
  clock_div clkvar_y (.clk(CLK100MHZ),.new_clk(CLK_VAR_y),.dps(dps_y));

  pmod_step_driver x (.rst(reset),.dir(dir_x),.clk(CLK_VAR_x),.en(~reset),.signal(signal_x_auto));
  pmod_step_driver y (.rst(reset),.dir(dir_y),.clk(CLK_VAR_y),.en(~reset),.signal(signal_y_auto));

endmodule
