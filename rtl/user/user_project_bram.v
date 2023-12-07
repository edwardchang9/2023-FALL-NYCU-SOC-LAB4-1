
`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_proj_bram
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_bram #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
	input clk,
	input rst,
	input enable,
	input ready,
    // Wishbone Slave ports (WB MI A)
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o
);
    wire clk;
    wire rst;
	wire enable;
    wire ready;

    // set valid, ready and delay signal
    wire [3:0] wstrb;

    // WB MI A
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
	assign wbs_ack_o = ready;

    bram user_bram (
        .CLK(clk),
        .WE0(wstrb),
        .EN0(enable),
        .Di0(wbs_dat_i),
        .Do0(wbs_dat_o),
        .A0(wbs_adr_i)
    );

endmodule



`default_nettype wire