`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/19/2017 12:51:24 AM
// Design Name:
// Module Name: motor_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Model movement of motor by recording head coordinate on screen and
//              the head will trace for the movement of target. Implemented using
//              a state machine.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 										  Define Module
//                     Port Declarations
// ==============================================================================
module motor_sim(
  CLK100MHZ, reset, vsync,
  ball_x, ball_y, head_x, head_y,
  signal_x, signal_y,
  state
  );
  input                        CLK100MHZ;
  input                        reset;
  input        signed  [10:0]  ball_x;
  input        signed  [10:0]  ball_y;
  input                        vsync;
  output  reg  signed  [10:0]  head_x;
  output  reg  signed  [10:0]  head_y;
  output               [3:0]   signal_x;
  output               [3:0]   signal_y;
  output               [1:0]   state;

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  localparam                   count_wait = 60;
  localparam                   count_freq = 60; // internal = wait freq

  localparam   signed          MAX_DISTANCE = 120;
  localparam   signed          AVG        = MAX_DISTANCE / count_freq;

  reg          signed  [11:0]  d_x;
  reg          signed  [11:0]  d_y;
  reg          signed  [11:0]  d_x_bak;
  reg          signed  [11:0]  d_y_bak;
  reg          signed  [10:0]  speed_x;
  reg          signed  [10:0]  speed_y;

  localparam           [1:0]   State_idle     = 2'b00;
  localparam           [1:0]   State_running  = 2'b01;
  localparam           [1:0]   State_continue = 2'b10;
  localparam           [1:0]   State_init     = 2'b11;
  reg                  [1:0]   STATE;

  reg                          axis_x;  // Is axis_x the longer axis?
  reg          signed  [4:0]   mids;    // Many intervals required before only remainder left to complete the movement

  integer                      counter;
  wire                 [7:0]   count;


// ==============================================================================
// 							              Implementation
// ==============================================================================
  assign state = STATE;
  assign count = (STATE == State_idle ? count_wait : count_freq);

  initial begin
    STATE   <= State_init;
    counter <= 0;
    head_x  <= 0;
    head_y  <= 0;
  end
  motor mot
    (.CLK100MHZ(CLK100MHZ),.reset(reset),.step_x(speed_x),.step_y(speed_y),.signal_x_auto(signal_x),.signal_y_auto(signal_y));

  always @ (posedge vsync) begin
    if (reset) begin
      STATE   <= State_init;
      counter <= 0;
      head_x  <= 0;
      head_y  <= 0;
    end else begin
      counter = counter + 1;
      if (counter >= count) begin
        counter = 0;
        // Initialize movement parameters
        case (STATE)
          State_init: begin
            STATE = State_idle;
          end

          State_idle: begin
            d_x = ball_x - head_x;
            d_y = ball_y - head_y;
            if (d_x > MAX_DISTANCE || d_x < -MAX_DISTANCE) begin
              axis_x = 1'b1;
              mids   = $signed(d_x / MAX_DISTANCE);
              d_x_bak = d_x;
              d_y_bak = d_y;

              STATE = State_continue;
            end else if (d_y > MAX_DISTANCE || d_y < -MAX_DISTANCE) begin
              axis_x = 1'b0;
              mids   = $signed(d_y / MAX_DISTANCE);
              d_x_bak = d_x;
              d_y_bak = d_y;

              STATE = State_continue;
            end else begin
              speed_x = d_x / count_freq;
              speed_y = d_y / count_freq;
              STATE = State_running;
            end
          end

          State_running: begin
            STATE = State_idle;
          end

          State_continue: begin
            if (mids == 0) begin
              STATE = State_running;
            end else begin
              mids = mids - 1;
            end
          end
        endcase
      end else begin // Move
        case (STATE)
          State_init: begin
            counter = count - 1; // Initiate process
          end

          State_running: begin
            speed_x = d_x / $signed(count - counter);
            speed_y = d_y / $signed(count - counter);

            head_x = head_x + speed_x;
            head_y = head_y + speed_y;
            d_x = d_x - speed_x;
            d_y = d_y - speed_y;

            $display("OK1 d_x:%d head_x:%d counter:%d count:%d speed_x:%d",d_x, head_x, counter, count, speed_x);
            $display("OK1 d_y:%d head_y:%d counter:%d count:%d speed_y:%d\n",d_y, head_y, counter, count, speed_y);
          end

          State_continue: begin
            case (axis_x)
              1'b1: begin
                speed_x = AVG;
                if (d_x < 0)
                  speed_x = -speed_x;
                d_x = d_x - speed_x;
                speed_y = d_y_bak * speed_x / d_x_bak;
                head_y = head_y + speed_y;
                d_y = d_y - speed_y;

                $display("continue d_x:%d head_x:%d counter:%d count:%d speed_x:%d",d_x, head_x, counter, count, speed_x);
                $display("continue d_y:%d head_y:%d counter:%d count:%d speed_y:%d\n",d_y, head_y, counter, count, speed_y);
              end

              1'b0: begin
                speed_y   = AVG;
                if (d_y < 0)
                  speed_y   = -speed_y;
                head_y    = head_y + speed_y;
                d_y       = d_y - speed_y;
                speed_x   = d_x_bak * speed_y / d_y_bak;
                head_x    = head_x + speed_x;
                d_x       = d_x - speed_x;

                $display("continue d_x:%d head_x:%d counter:%d count:%d speed_x:%d",d_x, head_x, counter, count, speed_x);
                $display("continue d_y:%d head_y:%d counter:%d count:%d speed_y\n",d_y, head_y, counter, count, speed_y);
              end
            endcase
          end
        endcase
      end
    end
  end
endmodule
