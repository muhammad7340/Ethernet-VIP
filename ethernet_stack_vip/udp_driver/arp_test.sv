
`timescale 1ps / 1ps
`include "packet_generator.sv"
module arp_test ();
	reg clk, rst;
	
	//Test bench driver/observer - let TB drive stimulus & capture/observe DUT response/output

	// Ethernet source
	reg s_eth_hdr_valid, s_eth_hdr_ready;
	reg [47:0] s_eth_dest_mac, s_eth_src_mac;
	reg [15:0] s_eth_type;
	reg [8-1:0] s_eth_payload_axis_tdata;
	reg [1-1:0] s_eth_payload_axis_tkeep;
	reg s_eth_payload_axis_tvalid, s_eth_payload_axis_tready;
	reg s_eth_payload_axis_tlast, s_eth_payload_axis_tuser;

	// Ethernet destination
	reg m_eth_hdr_valid, m_eth_hdr_ready;
	reg [47:0] m_eth_dest_mac, m_eth_src_mac;
	reg [15:0] m_eth_type;
	reg [8-1:0] m_eth_payload_axis_tdata;
	reg [1-1:0] m_eth_payload_axis_tkeep;
	reg m_eth_payload_axis_tvalid, m_eth_payload_axis_tready;
	reg m_eth_payload_axis_tlast, m_eth_payload_axis_tuser;

	// ARP
	reg arp_request_valid, arp_request_ready;
	reg [31:0] arp_request_ip;
	reg arp_response_valid, arp_response_ready, arp_response_error;
	reg [47:0] arp_response_mac;

	reg [47:0]            local_mac;
	reg [31:0]            local_ip;
	reg [31:0]            gateway_ip;
	reg [31:0]            subnet_mask;
	reg                   clear_cache;
    assign arp_request_valid = s_eth_payload_axis_tvalid; //whenever an Ethernet frame payload is marked valid, DUT should also treat it as an ARP request (arp_request_valid=1)


	// 2. DUT instantiation with port mapping
	arp dut(
			.clk(clk),
			.rst(rst),

			//source ethernet stream (Stimulus (TB drives) -> Dut)
			.s_eth_hdr_valid(s_eth_hdr_valid),
			.s_eth_hdr_ready(s_eth_hdr_ready),
			.s_eth_dest_mac(s_eth_dest_mac),
			.s_eth_src_mac(s_eth_src_mac),
			.s_eth_type(s_eth_type),
			.s_eth_payload_axis_tdata(s_eth_payload_axis_tdata),
			.s_eth_payload_axis_tkeep(s_eth_payload_axis_tkeep),
			.s_eth_payload_axis_tvalid(s_eth_payload_axis_tvalid),
			.s_eth_payload_axis_tready(s_eth_payload_axis_tready),
			.s_eth_payload_axis_tlast(s_eth_payload_axis_tlast),
			.s_eth_payload_axis_tuser(s_eth_payload_axis_tuser),

			//destination ethernet stream (Dut (drives) -> Sink (TB observe/monitor)
			.m_eth_hdr_valid(m_eth_hdr_valid),
			.m_eth_hdr_ready(m_eth_hdr_ready),
			.m_eth_dest_mac(m_eth_dest_mac),
			.m_eth_src_mac(m_eth_src_mac),
			.m_eth_type(m_eth_type),
			.m_eth_payload_axis_tdata(m_eth_payload_axis_tdata),
			.m_eth_payload_axis_tkeep(m_eth_payload_axis_tkeep),
			.m_eth_payload_axis_tvalid(m_eth_payload_axis_tvalid),
			.m_eth_payload_axis_tready(m_eth_payload_axis_tready),
			.m_eth_payload_axis_tlast(m_eth_payload_axis_tlast),
			.m_eth_payload_axis_tuser(m_eth_payload_axis_tuser),//Source drives (tdata,tkeep,tvalid,tlast,tuser) → Sink accepts when tready=1 → AXIS handshake ensures reliable packet transfer.

            // ARP requests (by DUT) /response (by TB)
			.arp_request_valid(arp_request_valid),
			.arp_request_ready(arp_request_ready),
			.arp_request_ip(arp_request_ip),
			.arp_response_valid(arp_response_valid),
			.arp_response_ready(arp_response_ready),
			.arp_response_error(arp_response_error),
			.arp_response_mac(arp_response_mac),
			
			// DUT configuration for its own identity + routing.
			.local_mac(local_mac),
			.local_ip(local_ip),
			.gateway_ip(gateway_ip),
			.subnet_mask(subnet_mask),
			.clear_cache(clear_cache)
	);

	ARP arp_source, arp_sink; //class handles ARP protocol
	ETH eth_source, eth_sink;
	bit [7:0] data_in [28]; //input data for ARP request
	byte data_out [28];
	//4. Clock & Reset generation
	always #4 clk = ~clk;

    // 5&6. Driver/Monitor for headers
	always@(*) begin
	// m_eth_hdr_ready = 1'b1;
	// TX Driver: If TB drives a valid Ethernet header (s_eth_hdr_valid=1), it assigns eth_source’s header fields (dst/src MAC, eth_type) onto DUT’s input signals
		if(s_eth_hdr_valid)begin 
			s_eth_dest_mac       = eth_source.dst_mac;
			s_eth_src_mac        = eth_source.src_mac;
			s_eth_type           = eth_source.eth_type;
		end

	// RX Monitor: If DUT outputs a valid Ethernet header (m_eth_hdr_valid=1), it captures those signals into eth_sink fields for observation/checking
		if (m_eth_hdr_valid) begin
			eth_sink.dst_mac     = m_eth_dest_mac;
			eth_sink.src_mac     = m_eth_src_mac;
			eth_sink.eth_type    = m_eth_type;
		end
	end
	int i = 0; //i indexes TX bytes sent to DUT; 
	int j = 0; //j indexes RX bytes collected from DUT.

    // 3. Stimulus generation (Driver)
	initial begin
		clk = 0;
		#4 //4ns delay
		clk =1; // 1st rising edge
		s_eth_hdr_valid = 1'b0; //condition met from always block
		arp_source = new(); // Create TB objects
		arp_sink = new();
		eth_source = new();
		eth_sink = new();
		#100;
		
		//4. reset logic: reset DUT synchronously at +ve edge clk at 108ps instead of 104ps
		@(posedge clk);
		rst = 1;
		@(posedge clk);
		rst = 0;
		@(posedge clk);
		#100;
		//delay of 2 more cycles : 236ps
		@(posedge clk);
		@(posedge clk);

		//Configure DUT identity
		local_mac     = 48'hDAD1_D2D3_D4D5;
		local_ip      = 32'hC0A8_0165;
		gateway_ip    = 32'hC0A8_0101;
		subnet_mask   = 32'hFFFF_FF00;
		arp_request_ip = 32'hC0A8_0165;
		arp_response_ready = 1'b1;
		clear_cache = 1'b0;
		@(posedge clk);


		$display("test 1: ARP request");
        // Build an ARP request
		eth_source.dst_mac = 48'hFFFFFFFFFFFF; //creates a broadcast frame to DUT.
		eth_source.src_mac = 48'h5A5152535455;
		eth_source.eth_type = 16'h0806;
		arp_source.htype = 16'h0001;
		arp_source.ptype = 16'h0800;
		arp_source.hlen  = 8'd6;
		arp_source.plen  = 8'd4;
		arp_source.oper  = 16'h0001;
		arp_source.sha   = '{8'h5A, 8'h51, 8'h52, 8'h53, 8'h54, 8'h55};
		arp_source.spa   = '{8'hC0, 8'hA8, 8'h01, 8'h64};
		arp_source.tha   = '{8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
		arp_source.tpa   = '{8'hC0, 8'hA8, 8'h01, 8'h65};
		
		//Start header + handshakes
		s_eth_hdr_valid = 1'b1;//presents Ethernet header to DUT

		arp_source.pack(data_in); //serializes ARP payload into data_in[0..27] by passing parameters into .pack func with output  to avoid return
		m_eth_hdr_ready = 1'b1;  //tell DUT the TB can accept output header/payload.
		m_eth_payload_axis_tready = 1'b1;

		#500;
		// 7. Scoreboard/Checker.
		$display("--------------slkfs%d",j);
		arp_sink.parse(data_out);
		arp_sink.print();
		foreach(data_out[k])
			$display("data_out = %h ",data_out[k]);
		#1 $stop;
	end
	

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			i                         <= 0;
			s_eth_payload_axis_tvalid <= 1'b0;
			s_eth_payload_axis_tdata  <= 8'd0;
			s_eth_payload_axis_tkeep  <= 1'b1; // for 8-bit width, always 1
			s_eth_payload_axis_tuser  <= 1'b0; // error flag, set only if needed
			s_eth_payload_axis_tlast  <= 1'b0;
		end
		else begin

			// 5. TX Driver: Stream TX payload (to DUT) using AXI-Stream handshake (tvalid/tready).
			if (i < 28) begin
				if (s_eth_payload_axis_tready) begin //drive signals to dut
					s_eth_payload_axis_tvalid <= 1'b1;
					s_eth_payload_axis_tkeep  <= 1'b1; // 1 byte valid
					s_eth_payload_axis_tuser  <= 1'b0; // no error
					s_eth_payload_axis_tdata  <= data_in[i];

					// Mark last byte
					if (i == 27)

						s_eth_payload_axis_tlast <= 1'b1;//Assert tlast when i==27
					else
						s_eth_payload_axis_tlast <= 1'b0;

					i <= i + 1;
				end
			end
			else begin
				// No more data
				// i <= 0;
				s_eth_payload_axis_tvalid <= 1'b0;
				s_eth_payload_axis_tlast  <= 1'b0;
			end
			// 6. RX Monitor/Scoreboarding: Collect RX payload (from DUT)
			if(j<28)begin
				if(m_eth_payload_axis_tvalid)begin
					data_out[j] <= m_eth_payload_axis_tdata; //capture m_eth_payload_axis_tdata into data_out[j]
					j <= j + 1;                             //increment j until 28 bytes.

				end
			end
		end
	end
endmodule