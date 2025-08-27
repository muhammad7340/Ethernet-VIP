// This SV import "DPI-C" statement tells SV how to call a C/C++ function (call_create_arp_frame).
// The `context` keyword allows the C/C++ function to interact with the SystemVerilog simulator’s internal state if needed
// Declare these functions in SV by defining an interface to a C/C++ function named `call_create_arp_frame`
// The function itself is implemented in a C/C++ file
// SV code calls this function directly, passing arguments as specified here
import "DPI-C" context function int call_create_arp_frame(
    input  string src_mac,
    input  string src_ip,
    input  string dst_mac,
    input  string dst_ip,
    output byte   pkt_data[], // Array allocated in SV, filled in C++
    inout  int    length
);

import "DPI-C" context function int call_create_eth_frame(
    input  string src_mac,
    input  string dst_mac,
    input  int    eth_type,   // Ethertype (e.g. 0x0800)
    output byte   pkt_data[],
    inout  int    length
);

import "DPI-C" context function int call_create_ip_header(
    input  string src_ip,
    input  string dst_ip,
    input  int    proto,      // IP protocol number (e.g. 17 for UDP)
    output byte   pkt_data[],
    inout  int    length
);

import "DPI-C" context function int call_create_udp_header(
    input  int    sport,
    input  int    dport,
    input  int    payload_len,
    output byte   pkt_data[],
    inout  int    length
);





// ======================= Classes for packet parsing (ARP / ETH / IP / UDP) =======================

class ARP; // 28 Octet (byte) ARP Request/Reply
    bit [15:0] htype;
    bit [15:0] ptype;
    bit [7:0]  hlen;
    bit [7:0]  plen;
    bit [15:0] oper;
    bit [7:0]  sha[6];
    bit [7:0]  spa[4];
    bit [7:0]  tha[6];
    bit [7:0]  tpa[4];

    // Constructor to instantiate ARP class
    function new(); endfunction // constructor definition

    function void parse(byte data[28]); // data is formal parameter, pkt_data is actual parameter
        htype = {data[0], data[1]};
        ptype = {data[2], data[3]};
        hlen  = data[4];
        plen  = data[5];
        oper  = {data[6], data[7]};
        for (int i = 0; i < 6; i++) sha[i] = data[8+i];
        for (int i = 0; i < 4; i++) spa[i] = data[14+i];
        for (int i = 0; i < 6; i++) tha[i] = data[18+i];
        for (int i = 0; i < 4; i++) tpa[i] = data[24+i];
    endfunction

    function void pack(output bit [7:0] data[28]);
		// Fixed fields
		data[0] = htype[15:8];
		data[1] = htype[7:0];
		data[2] = ptype[15:8];
		data[3] = ptype[7:0];
		data[4] = hlen;
		data[5] = plen;
		data[6] = oper[15:8];
		data[7] = oper[7:0];

		// MAC and IP addresses
		for (int i = 0; i < 6; i++) data[8+i]  = sha[i];
		for (int i = 0; i < 4; i++) data[14+i] = spa[i];
		for (int i = 0; i < 6; i++) data[18+i] = tha[i];
		for (int i = 0; i < 4; i++) data[24+i] = tpa[i];
	endfunction

    function void print();
        $display("\n-------- [DEBUG_SV] ARP Packet --------");
        $display("Hardware Type      : 0x%04h", htype);
        $display("Protocol Type      : 0x%04h", ptype);
        $display("HW Addr Length     : %0d", hlen);
        $display("Protocol Addr Len  : %0d", plen);
        $display("Opcode             : 0x%04h", oper);

        $write("Sender MAC Address : ");
        foreach (sha[i]) begin
            $write("%02x", sha[i]); // prints the current byte in hex, e.g., "0a"
            if (i < 5) $write(":"); // prints ":" between bytes and ensure not to print it after the last byte (6th one)
        end
        $write("\n");

        $write("Sender IP Address  : ");
        foreach (spa[i]) begin
            $write("%0d", spa[i]);
            if (i < 3) $write(".");
        end
        $write("\n");

        $write("Target MAC Address : ");
        foreach (tha[i]) begin
            $write("%02x", tha[i]);
            if (i < 5) $write(":");
        end
        $write("\n");

        $write("Target IP Address  : ");
        foreach (tpa[i]) begin
            $write("%0d", tpa[i]);
            if (i < 3) $write(".");
        end
        $write("\n-----------------------------\n");
    endfunction

endclass


class ETH;
    bit [47:0] dst_mac;
    bit [47:0] src_mac;
    bit [15:0] eth_type;

    function new(); endfunction

    function void parse(byte data[14]);
        dst_mac = {data[0], data[1], data[2], data[3], data[4], data[5]};
        src_mac = {data[6], data[7], data[8], data[9], data[10], data[11]};
        eth_type = {data[12], data[13]};
    endfunction

    function void print();
        $display("------ [DEBUG_SV] Ethernet Frame ------");
        $display("Destination MAC : %02x:%02x:%02x:%02x:%02x:%02x",
            dst_mac[47:40], dst_mac[39:32], dst_mac[31:24],
            dst_mac[23:16], dst_mac[15:8], dst_mac[7:0]);
        $display("Source MAC      : %02x:%02x:%02x:%02x:%02x:%02x",
            src_mac[47:40], src_mac[39:32], src_mac[31:24],
            src_mac[23:16], src_mac[15:8], src_mac[7:0]);
        $display("Ethertype       : 0x%04h", eth_type);
        $display("--------------------------------------");
    endfunction
endclass


class IP;
    bit [3:0]  version;
    bit [3:0]  ihl;
    bit [7:0]  dscp_ecn;
    bit [15:0] total_length;
    bit [15:0] identification;
    bit [2:0]  flags;
    bit [12:0] frag_offset;
    bit [7:0]  ttl;
    bit [7:0]  protocol;
    bit [15:0] hdr_checksum;
    bit [7:0]  src_ip[4];
    bit [7:0]  dst_ip[4];

    function new(); endfunction

    function void parse(byte data[20]);
        version     = data[0][7:4];
        ihl         = data[0][3:0];
        dscp_ecn    = data[1];
        total_length = {data[2], data[3]};
        identification = {data[4], data[5]};
        flags       = data[6][7:5];
        frag_offset = {data[6][4:0], data[7]};
        ttl         = data[8];
        protocol    = data[9];
        hdr_checksum = {data[10], data[11]};
        for (int i = 0; i < 4; i++) src_ip[i] = data[12+i];
        for (int i = 0; i < 4; i++) dst_ip[i] = data[16+i];
    endfunction

    function void print();
        $display("-------- [DEBUG_SV] IPv4 Packet --------");
        $display("Version         : %0d", version);
        $display("IHL             : %0d", ihl);
        $display("DSCP/ECN        : 0x%02h", dscp_ecn);
        $display("Total Length    : %0d", total_length);
        $display("Identification  : 0x%04h", identification);
        $display("Flags           : 0x%01h", flags);
        $display("Fragment Offset : %0d", frag_offset);
        $display("TTL             : %0d", ttl);
        $display("Protocol        : 0x%02h", protocol);
        $display("Header Checksum : 0x%04h", hdr_checksum);
        $write("Source IP       : ");
        foreach (src_ip[i]) begin
            $write("%0d", src_ip[i]);
            if (i < 3) $write(".");
        end
        $write("\nDestination IP  : ");
        foreach (dst_ip[i]) begin
            $write("%0d", dst_ip[i]);
            if (i < 3) $write(".");
        end
        $display("\n--------------------------------------");
    endfunction
endclass


class UDP;
    bit [15:0] src_port;
    bit [15:0] dst_port;
    bit [15:0] length;
    bit [15:0] checksum;

    function new(); endfunction

    function void parse(byte data[8]);
        src_port = {data[0], data[1]};
        dst_port = {data[2], data[3]};
        length   = {data[4], data[5]};
        checksum = {data[6], data[7]};
    endfunction

    function void print();
        $display("-------- [DEBUG_SV] UDP Segment --------");
        $display("Source Port      : %0d", src_port);
        $display("Destination Port : %0d", dst_port);
        $display("Length           : %0d", length);
        $display("Checksum         : 0x%04h", checksum);
        $display("--------------------------------------");
    endfunction
endclass















module automatic test;

    
    
    byte arp_data[]; // ARP packet (28 bytes)
    byte eth_data[]; // Ethernet frame (14 bytes)
    byte ip_data[];  // IPv4 header (20 bytes)
    byte udp_data[]; // UDP header (8 bytes)

    
    int arp_len = 0; 
    int eth_len = 0;
    int ip_len  = 0;
    int udp_len = 0;


    int result;

    // -------------------- Ethernet --------------------
    string src_mac = "05:00:00:00:00:01";
    string dst_mac = "ff:ff:ff:ff:ff:ff";
    int eth_type_arp = 16'h0806; // ARP
    int eth_type_ip  = 16'h0800; // IPv4

    // -------------------- IP --------------------
    string src_ip  = "192.168.1.100";
    string dst_ip  = "192.168.1.1";
    int proto_udp  = 17; // UDP protocol number

    // -------------------- UDP --------------------
    int sport       = 1234;
    int dport       = 5678;
    int payload_len = 16;


    ARP  arp_pkt; // object for ARP packet
    ETH  eth_pkt;
    IP   ip_pkt;
    UDP  udp_pkt;

    initial begin

  

        // ================== Ethernet + ARP ==================
        eth_data = new[14];
        arp_data = new[28];
        eth_len = 1;
        arp_len = 1;

        result = call_create_eth_frame(src_mac, dst_mac, eth_type_arp, eth_data, eth_len);
        result = call_create_arp_frame(src_mac, src_ip, dst_mac, dst_ip, arp_data, arp_len);

        if (result != -1) begin
            eth_pkt = new(); arp_pkt = new();
            eth_pkt.parse(eth_data); eth_pkt.print();
            arp_pkt.parse(arp_data); arp_pkt.print();
        end

        // ================== Ethernet + IP + UDP ==================

        eth_data = new[14];
        ip_data  = new[20];
        udp_data = new[8];
        eth_len = 1;
        ip_len  = 1;
        udp_len = 1;


        result = call_create_eth_frame(src_mac, dst_mac, eth_type_ip, eth_data, eth_len);
        result = call_create_ip_header(src_ip, dst_ip, proto_udp, ip_data, ip_len);
        result = call_create_udp_header(sport, dport, payload_len, udp_data, udp_len);

        if (result != -1) begin
            eth_pkt = new(); ip_pkt  = new(); udp_pkt = new();
            eth_pkt.parse(eth_data); eth_pkt.print();
            ip_pkt.parse(ip_data);   ip_pkt.print();
            udp_pkt.parse(udp_data); udp_pkt.print();
        end

        $display("\nAll packet generation and parsing tests completed.");
        $finish;
    end
endmodule