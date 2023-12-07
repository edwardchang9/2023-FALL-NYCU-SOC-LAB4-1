
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

module user_proj_axi #(
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
           output reg wbs_ack_o,
           output [31:0] wbs_dat_o,

           // AXI Lite
           input         awready,
           input         wready,
           output          awvalid,
           output   [11:0] awaddr,
           output          wvalid,
           output [31:0] wdata,

           input arready,
           output reg rready,
           output reg arvalid,
           output reg [11:0] araddr,
           input rvalid,
           input [31:0] rdata,

           // AXI stream
           output reg ss_tvalid,
           output reg [31:0] ss_tdata,
           output reg ss_tlast,
           input ss_tready,

           output reg sm_tready,
           input sm_tvalid,
           input [31:0] sm_tdata,
           input sm_tlast

       );
wire clk;
wire rst;
wire enable; //decode address is 0x30
wire ready; // wait over 10 cc
//lite or stream
wire is_lite;
assign is_lite= (wbs_adr_i[7] == 0) ? 1: 0;
//lite mode
reg [31:0]read_data;
reg axi_w_done ,axi_r_done;
always @(posedge clk) begin
    if(!enable)
        read_data<=0;
    else if(rvalid && rready)
        read_data<=rdata;
    else if(sm_tvalid && sm_tready)
        read_data<=sm_tdata;
end
always @(posedge clk) begin
    begin
        if(!enable)
            axi_w_done<=0;
        if(wvalid && wready)
            axi_w_done<=1;
        else if(wbs_ack_o)
            axi_w_done<=0;
    end
end
always @(posedge clk ) begin
    begin
        if(!enable)
            axi_r_done<=0;
        if(arvalid && arready)
            axi_r_done<=1;
        else if(wbs_ack_o)
            axi_r_done<=0;
    end
end
//wishbone
always @(posedge clk) begin
    begin
        if(wbs_ack_o ==1)
            wbs_ack_o<=0;
        else
        begin
            if(is_lite)
            begin
                if(ready && (axi_w_done || axi_r_done))
                    wbs_ack_o<=1;
                else
                    wbs_ack_o<=0;
            end
            else
            begin
                if(ready && (ss_done || sm_done))
                    wbs_ack_o<=1;
                else
                    wbs_ack_o<=0;
            end
        end
    end
end
assign wbs_dat_o= read_data;

//axilite
assign awvalid=enable && is_lite && wbs_we_i && !axi_w_done;
assign awaddr=wbs_adr_i;
assign wvalid=enable && is_lite && wbs_we_i && !axi_w_done;
assign wdata=wbs_dat_i;

always @(*) begin
    rready= enable && is_lite && (!wbs_we_i);
end
always @(*) begin
    arvalid =enable && is_lite && (!wbs_we_i) && !axi_r_done;
end
always @(*) begin
    araddr=wbs_adr_i;
end


//axistream
reg ss_done ,sm_done;
always @(posedge clk) begin
    begin
        if(!enable)
            ss_done<=0;
        if(ss_tvalid && ss_tready)
            ss_done<=1;
        else if(wbs_ack_o)
            ss_done<=0;
    end
end
always @(posedge clk ) begin
    begin
        if(!enable)
            sm_done<=0;
        if(sm_tvalid && sm_tready)
            sm_done<=1;
        else if(wbs_ack_o)
            sm_done<=0;
    end
end

always @(*) begin
    if(enable && !is_lite && wbs_we_i && !ss_done)
        ss_tvalid=1;
    else
        ss_tvalid=0;
end
always @(*) begin
    if(enable && !is_lite && wbs_we_i)
        ss_tdata=wbs_dat_i;
    else
        ss_tdata=0;
end
always @(*) begin
    if(enable && !is_lite && !wbs_we_i && !sm_done)
        sm_tready=1;
    else
        sm_tready=0;
end

// X[n] ready to accept
//Y[n] ready to read stream_y_done==1








endmodule



`default_nettype wire
