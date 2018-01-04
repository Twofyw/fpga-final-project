`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent
// Engineer: Kaitlyn Franz
//
// Create Date: 01/23/2016 03:44:35 PM
// Design Name: Claw
// Module Name: clock_div
// Project Name: Claw_game
// Target Devices: Basys3
// Tool Versions: 2015.4
// Description: This is a clock divider. It takes the system clock
// and divides that down to a slower clock. It counts at the rate of the
// system clock to define_speed and toggles the output clock signal.
//
// Dependencies:
//
// Revision: 1
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module clock_div(
    input clk,
    input [8:0] dps, // Desired degrees per second
    output reg new_clk
    );
    // The constant that defines the clock speed.
    // Since the system clock is 100MHZ,
    // define_speed = 100MHz/(2*desired_clock_frequency)
    // localparam define_speed = 26'd5_000_000;

    // Count value that counts to define_speed
    reg [26:0] count;
    reg [26:0] define_speed;

    assign rst = (dps == 0);

    always @ (dps) begin
      define_speed = 27'b101_0101_1101_0100_1010_1000_0000 / dps; // Calculated magic number
    end

    // Run on the positive edge of the clk and rst signals
    always @ (posedge(clk),posedge(rst))
    begin
        // When rst is high set count and new_clk to 0
        if (rst == 1'b1)
        begin
            count = 27'b0;
            new_clk = 1'b0;
        end
        // When the count has reached the constant
        // reset count and toggle the output clock
        else if (count >= define_speed - 1)
        begin
            count = 27'b0;
            new_clk = ~new_clk;
        end
        // increment the clock and keep the output clock
        // the same when the constant hasn't been reached
        else
        begin
            count = count + 1'b1;
            new_clk = new_clk;
        end
    end
endmodule
