// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */
`define MPRJ_IO_PADS_1 19	/* number of user GPIO pads on user1 side */
`define MPRJ_IO_PADS_2 19	/* number of user GPIO pads on user2 side */
`define MPRJ_IO_PADS (`MPRJ_IO_PADS_1 + `MPRJ_IO_PADS_2)
module user_project_wrapper #(
           parameter BITS = 32,
           parameter DELAYS=10
       ) (
`ifdef USE_POWER_PINS
           inout vdda1,	// User area 1 3.3V supply
           inout vdda2,	// User area 2 3.3V supply
           inout vssa1,	// User area 1 analog ground
           inout vssa2,	// User area 2 analog ground
           inout vccd1,	// User area 1 1.8V supply
           inout vccd2,	// User area 2 1.8v supply
           inout vssd1,	// User area 1 digital ground
           inout vssd2,	// User area 2 digital ground
`endif

           // Wishbone Slave ports (WB MI A)
           input wb_clk_i,
           input wb_rst_i,
           input wbs_stb_i,
           input wbs_cyc_i,
           input wbs_we_i,
           input [3:0] wbs_sel_i,
           input [31:0] wbs_dat_i,
           input [31:0] wbs_adr_i,
           output wbs_ack_o,
           output [31:0] wbs_dat_o,

           // Logic Analyzer Signals
           input  [127:0] la_data_in,
           output [127:0] la_data_out,
           input  [127:0] la_oenb,

           // IOs
           input  [`MPRJ_IO_PADS-1:0] io_in,
           output [`MPRJ_IO_PADS-1:0] io_out,
           output [`MPRJ_IO_PADS-1:0] io_oeb,

           // Analog (direct connection to GPIO pad---use with caution)
           // Note that analog I/O is not available on the 7 lowest-numbered
           // GPIO pads, and so the analog_io indexing is offset from the
           // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
           inout [`MPRJ_IO_PADS-10:0] analog_io,

           // Independent clock (on independent integer divider)
           input   user_clock2,

           // User maskable interrupt signals
           output  [2:0] user_irq

       );



// IRQ
assign user_irq = 3'b000;	// Unused

// LA

// IO
assign io_out = count;
assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

reg [3:0] count;
reg ready;


// Assuming LA probes [65:64] are for controlling the count clk & reset
wire clk;
wire rst;
assign clk = wb_clk_i;
assign rst = wb_rst_i;

wire user_project_bram_enable;
wire axi_enable;
assign user_project_bram_enable = wbs_cyc_i && wbs_stb_i && (wbs_adr_i[31:20] == 12'h380) ? 1'b1: 1'b0;
assign axi_enable 				= wbs_cyc_i && wbs_stb_i && (wbs_adr_i[31:20] == 12'h300) ? 1'b1: 1'b0;

wire valid;
assign valid = wbs_cyc_i && wbs_stb_i && (user_project_bram_enable | axi_enable);

always @(posedge clk) begin
    if (rst) begin
        ready <= 1'b0;
        count <= 16'b0;
    end else begin
        ready <= 1'b0;
        if (valid && !ready) begin
            if (count == DELAYS) begin
                count <= 16'b0;
                ready <= 1'b1;
            end else begin
                count <= count + 1;
            end
        end
        else if(!(user_project_bram_ack || axi_ack ) && ready)
            ready <= 1'b1;
        
    end
end

//wbs_ack_mux
wire user_project_bram_ack,axi_ack;
wire [31:0]user_project_bram_dat,axi_dat;
assign wbs_ack_o= (user_project_bram_enable) ? user_project_bram_ack :
       (axi_enable) ? axi_ack : 0 ;
assign wbs_dat_o= (user_project_bram_enable) ? user_project_bram_dat :
       (axi_enable) ? axi_dat : 0 ;

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

user_proj_bram mprj_bram (
`ifdef USE_POWER_PINS
                   .vccd1(vccd1),	// User area 1 1.8V power
                   .vssd1(vssd1),	// User area 1 digital ground
`endif
                   .clk(clk),
                   .rst(rst),
                   .enable(user_project_bram_enable),
                   .ready(ready),

                   // MGMT SoC Wishbone Slave

                   .wbs_cyc_i(wbs_cyc_i),
                   .wbs_stb_i(wbs_stb_i),
                   .wbs_we_i(wbs_we_i),
                   .wbs_sel_i(wbs_sel_i),
                   .wbs_adr_i(wbs_adr_i),
                   .wbs_dat_i(wbs_dat_i),
                   .wbs_ack_o(user_project_bram_ack),
                   .wbs_dat_o(user_project_bram_dat)

               );


endmodule	// user_project_wrapper

`default_nettype wire
