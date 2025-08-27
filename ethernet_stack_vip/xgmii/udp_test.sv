`timescale 1ps / 1ps
`include "packet_generator.sv"

module udp_test;
    reg clk, rst;
    
    //Test bench driver/observer - let TB drive stimulus & capture/observe DUT response/output

    // Declare all the required signals as reg (for inputs) and wire (for outputs) in the testbench from DUT
    // Ethernet input (source to DUT)
    reg s_eth_hdr_valid;
    wire s_eth_hdr_ready;
    reg [47:0] s_eth_dest_mac, s_eth_src_mac;
    reg [15:0] s_eth_type;
    reg [63:0] s_eth_payload_axis_tdata;
    reg [7:0]  s_eth_payload_axis_tkeep;
    reg s_eth_payload_axis_tvalid;
    wire s_eth_payload_axis_tready;
    reg s_eth_payload_axis_tlast, s_eth_payload_axis_tuser;

    // Ethernet output (DUT to sink)
    wire m_eth_hdr_valid;
    reg  m_eth_hdr_ready;
    wire [47:0] m_eth_dest_mac, m_eth_src_mac;
    wire [15:0] m_eth_type;
    wire [63:0] m_eth_payload_axis_tdata;
    wire [7:0]  m_eth_payload_axis_tkeep;
    wire m_eth_payload_axis_tvalid;
    reg  m_eth_payload_axis_tready;
    wire m_eth_payload_axis_tlast, m_eth_payload_axis_tuser;

    // UDP input (source to DUT)
    reg s_udp_hdr_valid;
    wire s_udp_hdr_ready;
    reg [5:0]  s_udp_ip_dscp;
    reg [1:0]  s_udp_ip_ecn;
    reg [7:0]  s_udp_ip_ttl;
    reg [31:0] s_udp_ip_source_ip, s_udp_ip_dest_ip;
    reg [15:0] s_udp_source_port, s_udp_dest_port, s_udp_length, s_udp_checksum;
    reg [63:0] s_udp_payload_axis_tdata;
    reg [7:0]  s_udp_payload_axis_tkeep;
    reg s_udp_payload_axis_tvalid;
    wire s_udp_payload_axis_tready;
    reg s_udp_payload_axis_tlast, s_udp_payload_axis_tuser;

    // UDP output (DUT to sink)
    wire m_udp_hdr_valid;
    reg  m_udp_hdr_ready;
    wire [47:0] m_udp_eth_dest_mac, m_udp_eth_src_mac;
    wire [15:0] m_udp_eth_type;
    wire [3:0]  m_udp_ip_version, m_udp_ip_ihl;
    wire [5:0]  m_udp_ip_dscp;
    wire [1:0]  m_udp_ip_ecn;
    wire [15:0] m_udp_ip_length, m_udp_ip_identification;
    wire [2:0]  m_udp_ip_flags;
    wire [12:0] m_udp_ip_fragment_offset;
    wire [7:0]  m_udp_ip_ttl, m_udp_ip_protocol;
    wire [15:0] m_udp_ip_header_checksum;
    wire [31:0] m_udp_ip_source_ip, m_udp_ip_dest_ip;
    wire [15:0] m_udp_source_port, m_udp_dest_port, m_udp_length, m_udp_checksum;
    wire [63:0] m_udp_payload_axis_tdata;
    wire [7:0]  m_udp_payload_axis_tkeep;
    wire m_udp_payload_axis_tvalid;
    reg  m_udp_payload_axis_tready;
    wire m_udp_payload_axis_tlast, m_udp_payload_axis_tuser;

    // Configuration
    reg [47:0] local_mac;
    reg [31:0] local_ip, gateway_ip, subnet_mask;
    reg clear_arp_cache;

        // DUT instantiation
    udp_complete_64 dut (
        .clk(clk),
        .rst(rst),

        // Ethernet frame input
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

        // Ethernet frame output
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
        .m_eth_payload_axis_tuser(m_eth_payload_axis_tuser),

        // UDP input
        .s_udp_hdr_valid(s_udp_hdr_valid),
        .s_udp_hdr_ready(s_udp_hdr_ready),
        .s_udp_ip_dscp(s_udp_ip_dscp),
        .s_udp_ip_ecn(s_udp_ip_ecn),
        .s_udp_ip_ttl(s_udp_ip_ttl),
        .s_udp_ip_source_ip(s_udp_ip_source_ip),
        .s_udp_ip_dest_ip(s_udp_ip_dest_ip),
        .s_udp_source_port(s_udp_source_port),
        .s_udp_dest_port(s_udp_dest_port),
        .s_udp_length(s_udp_length),
        .s_udp_checksum(s_udp_checksum),
        .s_udp_payload_axis_tdata(s_udp_payload_axis_tdata),
        .s_udp_payload_axis_tkeep(s_udp_payload_axis_tkeep),
        .s_udp_payload_axis_tvalid(s_udp_payload_axis_tvalid),
        .s_udp_payload_axis_tready(s_udp_payload_axis_tready),
        .s_udp_payload_axis_tlast(s_udp_payload_axis_tlast),
        .s_udp_payload_axis_tuser(s_udp_payload_axis_tuser),

        // UDP output
        .m_udp_hdr_valid(m_udp_hdr_valid),
        .m_udp_hdr_ready(m_udp_hdr_ready),
        .m_udp_eth_dest_mac(m_udp_eth_dest_mac),
        .m_udp_eth_src_mac(m_udp_eth_src_mac),
        .m_udp_eth_type(m_udp_eth_type),
        .m_udp_ip_version(m_udp_ip_version),
        .m_udp_ip_ihl(m_udp_ip_ihl),
        .m_udp_ip_dscp(m_udp_ip_dscp),
        .m_udp_ip_ecn(m_udp_ip_ecn),
        .m_udp_ip_length(m_udp_ip_length),
        .m_udp_ip_identification(m_udp_ip_identification),
        .m_udp_ip_flags(m_udp_ip_flags),
        .m_udp_ip_fragment_offset(m_udp_ip_fragment_offset),
        .m_udp_ip_ttl(m_udp_ip_ttl),
        .m_udp_ip_protocol(m_udp_ip_protocol),
        .m_udp_ip_header_checksum(m_udp_ip_header_checksum),
        .m_udp_ip_source_ip(m_udp_ip_source_ip),
        .m_udp_ip_dest_ip(m_udp_ip_dest_ip),
        .m_udp_source_port(m_udp_source_port),
        .m_udp_dest_port(m_udp_dest_port),
        .m_udp_length(m_udp_length),
        .m_udp_checksum(m_udp_checksum),
        .m_udp_payload_axis_tdata(m_udp_payload_axis_tdata),
        .m_udp_payload_axis_tkeep(m_udp_payload_axis_tkeep),
        .m_udp_payload_axis_tvalid(m_udp_payload_axis_tvalid),
        .m_udp_payload_axis_tready(m_udp_payload_axis_tready),
        .m_udp_payload_axis_tlast(m_udp_payload_axis_tlast),
        .m_udp_payload_axis_tuser(m_udp_payload_axis_tuser),

        // Configuration
        .local_mac(local_mac),
        .local_ip(local_ip),
        .gateway_ip(gateway_ip),
        .subnet_mask(subnet_mask),
        .clear_arp_cache(clear_arp_cache)
    );
    
    // Clock generation (period = 8 time units, 4ns high/low for 1ps timescale)
    always #4 clk = ~clk;

    // Create UDP and ETH class objects
    UDP udp_source, udp_sink;
    ETH eth_source, eth_sink;
    byte udp_data[];
    byte eth_data[];
    int udp_len;
    int eth_len;
    int result;








    // Testbench variables
    int k;
    int i;
    byte rx_data[16];
    int rx_count;
    int tx_count;
    int payload_len = 16;
    int tx_state;
    int rx_state;

    // Initial block: reset, config, header, and UDP header generation
    initial begin
        clk = 0;
        rst = 0;

        s_eth_hdr_valid = 0;
        s_eth_dest_mac = 0;
        s_eth_src_mac = 0;
        s_eth_type = 0;
        s_eth_payload_axis_tdata = 0;
        s_eth_payload_axis_tkeep = 0;
        s_eth_payload_axis_tvalid = 0;
        s_eth_payload_axis_tlast = 0;
        s_eth_payload_axis_tuser = 0;

        s_udp_hdr_valid = 0;
        s_udp_ip_dscp = 0;
        s_udp_ip_ecn = 0;
        s_udp_ip_ttl = 0;
        s_udp_ip_source_ip = 0;
        s_udp_ip_dest_ip = 0;
        s_udp_source_port = 0;
        s_udp_dest_port = 0;
        s_udp_length = 0;
        s_udp_checksum = 0;
        s_udp_payload_axis_tdata = 0;
        s_udp_payload_axis_tkeep = 0;
        s_udp_payload_axis_tvalid = 0;
        s_udp_payload_axis_tlast = 0;
        s_udp_payload_axis_tuser = 0;

        m_eth_hdr_ready = 0;
        m_eth_payload_axis_tready = 0;
        m_udp_hdr_ready = 1;
        m_udp_payload_axis_tready = 1;

        // Configuration
        local_mac     = 48'hDAD1_D2D3_D4D5;
        local_ip      = 32'hC0A8_0165;
        gateway_ip    = 32'hC0A8_0101;
        subnet_mask   = 32'hFFFF_FF00;
        clear_arp_cache = 1'b0;

        #20;
        clk = 1;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // --- UDP Packet Generation using DPI-C and Class ---
        udp_data = new[8];
        udp_len = 1;
        result = call_create_udp_header(1234, 5678, payload_len, udp_data, udp_len);
        if (result != -1) begin
            udp_source = new();
            udp_source.parse(udp_data);
            $display("Generated UDP header:");
            udp_source.print();
        end else begin
            $display("UDP header generation failed!");
        end

        // Drive UDP header fields
        s_udp_ip_dscp      = 0;
        s_udp_ip_ecn       = 0;
        s_udp_ip_ttl       = 8'd64;
        s_udp_ip_source_ip = 32'hC0A80101;
        s_udp_ip_dest_ip   = 32'hC0A80102;
        s_udp_source_port  = udp_source.src_port;
        s_udp_dest_port    = udp_source.dst_port;
        s_udp_length       = udp_source.length;
        s_udp_checksum     = udp_source.checksum;
        s_udp_hdr_valid    = 1'b1;
        tx_count = 0;
        tx_state = 0;
        rx_count = 0;
        rx_state = 0;
    end

    // TX Driver: drive UDP payload using AXI-Stream handshake
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_udp_payload_axis_tvalid <= 0;
            s_udp_payload_axis_tlast  <= 0;
            s_udp_payload_axis_tdata  <= 0;
            s_udp_payload_axis_tkeep  <= 0;
            s_udp_payload_axis_tuser  <= 0;
            tx_count <= 0;
            tx_state <= 0;
        end else begin
            // Drive UDP header valid until handshake
            if (s_udp_hdr_valid && s_udp_hdr_ready) begin
                s_udp_hdr_valid <= 0;
                tx_state <= 1;
            end
            // Drive UDP payload
            if (tx_state == 1 && tx_count < 2) begin
                if (s_udp_payload_axis_tready) begin
                    s_udp_payload_axis_tdata  <= {8'h0F + tx_count, 8'h0E + tx_count, 8'h0D + tx_count, 8'h0C + tx_count, 8'h0B + tx_count, 8'h0A + tx_count, 8'h09 + tx_count, 8'h08 + tx_count};
                    s_udp_payload_axis_tkeep  <= 8'hFF;
                    s_udp_payload_axis_tvalid <= 1'b1;
                    s_udp_payload_axis_tlast  <= (tx_count == 1);
                    s_udp_payload_axis_tuser  <= 1'b0;
                    tx_count <= tx_count + 1;
                end
            end else begin
                s_udp_payload_axis_tvalid <= 0;
                s_udp_payload_axis_tlast  <= 0;
            end
        end
    end

    // RX Monitor: collect output from DUT
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_count <= 0;
            rx_state <= 0;
        end else begin
            if (m_udp_hdr_valid && rx_state == 0) begin
                $display("\nDUT output UDP header:");
                $display("src_port=%0d, dst_port=%0d, length=%0d, checksum=0x%04h", m_udp_source_port, m_udp_dest_port, m_udp_length, m_udp_checksum);
                rx_state <= 1;
            end
            if (m_udp_payload_axis_tvalid && m_udp_payload_axis_tready && rx_state == 1 && rx_count < 2) begin
                rx_data[rx_count*8+0] = m_udp_payload_axis_tdata[63:56];
                rx_data[rx_count*8+1] = m_udp_payload_axis_tdata[55:48];
                rx_data[rx_count*8+2] = m_udp_payload_axis_tdata[47:40];
                rx_data[rx_count*8+3] = m_udp_payload_axis_tdata[39:32];
                rx_data[rx_count*8+4] = m_udp_payload_axis_tdata[31:24];
                rx_data[rx_count*8+5] = m_udp_payload_axis_tdata[23:16];
                rx_data[rx_count*8+6] = m_udp_payload_axis_tdata[15:8];
                rx_data[rx_count*8+7] = m_udp_payload_axis_tdata[7:0];
                if (m_udp_payload_axis_tlast) begin
                    rx_state <= 2;
                    $display("Received UDP payload:");
                    foreach (rx_data[j]) $write("%02x ", rx_data[j]);
                    $display();
                    $display("\n--- UDP test completed ---");
                    #10 $finish;
                end
                rx_count <= rx_count + 1;
            end
        end
    end













   
endmodule