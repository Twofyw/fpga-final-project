`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/08/2017 11:19:47 PM
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description: This is the top module mainly responsible for display signal generation
//              and submodules are connected here.
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module top(
      CLK100MHZ,
      vga_out_red, vga_out_green, vga_out_blue, vga_out_hsync, vga_out_vsync,
      switch, reset, reset_game,
      MISO,SCLK,MOSI,SS,
      SEG, AN
    );

// ==============================================================================
// 										  Define Module
//                     Port Declarations
// ==============================================================================
  input  [1:0] switch; // select what to display
  input        CLK100MHZ;
  output [3:0] vga_out_red, vga_out_green, vga_out_blue;
  output       vga_out_hsync, vga_out_vsync;
  input MISO;
  output SCLK, MOSI, SS; // SPI signals

  // Seven segment display
  output [6:0] SEG;
  output [7:0] AN;

  input reset, reset_game; // Reset components such as clocks, reset_game to put cursor at center of screen

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  wire CLK65MHZ, locked; // VGA pixel clock

  // generate basic XVGA video signals
  wire [10:0] hcount, vcount;
  wire hsync,vsync;

  // feed XVGA signals to control module
  wire [11:0] pixel, pixel_gameBoard;
  wire phsync,pvsync,pblank;

  // Accelerometer
  wire signed [11:0] ACCEL_X, ACCEL_Y;
  wire signed [7:0] ACCEL_X_8, ACCEL_Y_8;
  wire Data_Ready;

  wire [3:0] raw_speed, pspeed; // pspeed is raw_speed synchronized with CLK65MHZ

// ==============================================================================
// 							  		   Implementation
// ==============================================================================

  // generate VGA pixel clock
  clk_wiz_0 CLK65 (.clk_out1(CLK65MHZ),.reset(reset),.clk_in1(CLK100MHZ),.locked(locked));
  xvga xvga1(.vclock(CLK65MHZ),.hcount(hcount),.vcount(vcount),
             .hsync(hsync),.vsync(vsync));

  // Connect to game logic to update what shows on game board

  assign raw_speed = 4'b0111;
  display_8hex hex_display (CLK100MHZ, pspeed, SEG, AN);
  game gm(.vclock(CLK65MHZ),.reset(reset_game),.hcount(hcount),.vcount(vcount),.hsync(hsync),
          .vsync(vsync),.phsync(phsync),.pvsync(pvsync),.pixel(pixel_gameBoard),.pspeed(pspeed));

          // entity AccelArithmetics is
          // generic
          // (
          //    SYSCLK_FREQUENCY_HZ : integer := 100000000;
          //    ACC_X_Y_MAX         : STD_LOGIC_VECTOR (9 downto 0) := "01" & X"FF"; -- 511 pixels, corresponding to +1g
          //    ACC_X_Y_MIN         : STD_LOGIC_VECTOR (9 downto 0) := (others => '0') -- corresponding to -1g
          // );
          // port
          // (
          //  SYSCLK     : in STD_LOGIC; -- System Clock
          //  RESET      : in STD_LOGIC;
          //
          //  -- Accelerometer data input signals
          //  ACCEL_X_IN    : in STD_LOGIC_VECTOR (11 downto 0);
          //  ACCEL_Y_IN    : in STD_LOGIC_VECTOR (11 downto 0);
          //  ACCEL_Z_IN    : in STD_LOGIC_VECTOR (11 downto 0);
          //  Data_Ready    : in STD_LOGIC;
          //
          //  -- Accelerometer data output signals to be sent to the VGA display
          //  ACCEL_X_OUT    : out STD_LOGIC_VECTOR (8 downto 0);
          //  ACCEL_Y_OUT    : out STD_LOGIC_VECTOR (8 downto 0);
          //  ACCEL_MAG_OUT  : out STD_LOGIC_VECTOR (11 downto 0)
          // );
          // end AccelArithmetics;
  ADXL362Ctrl accel (.SYSCLK(CLK100MHZ),.RESET(reset),.ACCEL_Z(ACCEL_Z),.Data_Ready(Data_Ready),
                      .MISO(MISO),.SCLK(SCLK),.MOSI(MOSI),.SS(SS));
  AccelArithmetics aa (.SYSCLK(CLK100MHZ),.RESET(reset),.ACCEL_X_IN(ACCEL_X),.ACCEL_X_OUT(ACCEL_X_8),.Data_Ready(Data_Ready));

  // Because pspeed is provided by modules driven by 100MHZ clock which might cause synchronization problem with
  // game input, it needs to be synchronized first.
  // module synchronize #(parameter NSYNC = 2)  // number of sync flops.  must be >= 2
  //                    (input clk,in,
  //                     output reg out);
  genvar i;
  generate begin
    for (i = 0; i < 4; i=i+1)
      synchronize sync_speed (.clk(CLK65MHZ),.in(raw_speed[i]),.out(pspeed[i]));
    end
  endgenerate

  // Alpha-blend pixels from gameBoard and dashBoard, and send to VGA output
  // But before implementing dashBoard, output gameBoard alone is fine
  // assign pixel = pixel_gameBoard;
  blend #(2,3) background2 (pixel_gameBoard, { vcount[8:5] + hcount[9:6], hcount[8:5], hcount[3:0] }, pixel);

  // switch[1:0] selects which video generator to use:
  //  00: the game
  //  01: 1 pixel outline of active video area (adjust screen controls)
  //  10: color bars
  reg [11:0] rgb;
  wire border = (hcount==0 | hcount==1023 | vcount==0 | vcount== 767);

  reg hs,vs; // hsync pipeline
  always @(posedge CLK65MHZ) begin
    hs <= phsync;
    vs <= pvsync;
    case (switch[1:0])
      2'b01: rgb <= { 11{border} };
      2'b10: rgb <= { vcount[4:1] + hcount[9:6], hcount[8:5], hcount[3:0] };
      2'b00: rgb <= pixel;
    endcase
  end

  assign vga_out_red = rgb[11:8];
  assign vga_out_green = rgb[7:4];
  assign vga_out_blue = rgb[3:0];
  assign vga_out_hsync = hs;
  assign vga_out_vsync = vs;

endmodule

////////////////////////////////////////////////////////////////////////////////
//
// xvga: Generate XVGA display signals (1024 x 768 @ 60Hz)
//
////////////////////////////////////////////////////////////////////////////////
module xvga(input vclock,
            output reg [10:0] hcount,    // pixel number on current line
            output reg [10:0] vcount,	 // line number
            output reg vsync,hsync);

   // horizontal: 1344 pixels total
   // display 1024 pixels per line
   wire hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount == 1023);
   assign hsyncon = (hcount == 1047);
   assign hsyncoff = (hcount == 1183);
   assign hreset = (hcount == 1343);

   // vertical: 806 lines total
   // display 768 lines
   wire vsyncon,vsyncoff,vreset;
   assign vsyncon = hreset & (vcount == 767); // typo? 767?
   assign vsyncoff = hreset & (vcount == 782);
   assign vreset = hreset & (vcount == 805);

   // sync and blanking
   always @(posedge vclock) begin
      hcount <= hreset ? 0 : hcount + 1;
      hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;  // active low

      vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
      vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;  // active low
   end
endmodule
