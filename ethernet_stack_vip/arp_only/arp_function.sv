
// This SV import "DPI-C" statement tells SV how to call a C/C++ function (call_create_arp_frame).
// The `context` keyword allows the C/C++ function to interact with the SystemVerilog simulator’s internal state if needed
// Declare these functions in SV by defining an interface to a C/C++ function named `call_create_arp_frame`
// The function itself is implemented in a C/C++ file
// SV code calls this function directly, passing arguments as specified here
import "DPI-C" context function int call_create_arp_frame(
    input  string src_mac   ,
    input  string src_ip    ,
    input  string dst_mac   ,
    input  string dst_ip    ,
    output byte   pkt_data[], // Array allocated in SV, filled in C++
    inout  int    length
);

class ARP; //28 Octect (byte) ARP Request/Reply

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
    function new(); endfunction // constructor defination

    function void parse(byte data[28]);// data is formal parameter, pkt_data is actual parameter
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

    function void print();
        $display("\n-------- [DEBUG_SV] ARP Packet --------");
        $display("Hardware Type      : 0x%04h", htype);
        $display("Protocol Type      : 0x%04h", ptype);
        $display("HW Addr Length     : %0d", hlen);
        $display("Protocol Addr Len  : %0d", plen);
        $display("Opcode             : 0x%04h", oper);

        $write("Sender MAC Address : ");
        foreach (sha[i]) begin
            $write("%02x", sha[i]);// prints the current byte in hex, e.g., "0a"
            if (i < 5) $write(":");// prints ":" between bytes and ensure not to print it after the last byte (6th one)
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


module automatic test;

    // Pre-allocate array for ARP packet bytes
    byte pkt_data[28];
    int pkt_len = 0;

    string src_mac = "05:00:00:00:00:01";
    string src_ip  = "192.168.1.100";
    string dst_mac = "ff:ff:ff:ff:ff:ff";
    string dst_ip  = "192.168.1.1";

    ARP arp_pkt; // Declare ARP packet object

    initial begin
        // Call C++ DPI function to generate ARP frame directly into pkt_data[]
        call_create_arp_frame(src_mac, src_ip, dst_mac, dst_ip, pkt_data, pkt_len);

        if (pkt_len != 28) begin
            $fatal("Failed to retrieve ARP packet from DPI (len=%0d)", pkt_len);
        end

        // Parse and print
        arp_pkt = new(); //constructor execution
        arp_pkt.parse(pkt_data);
        arp_pkt.print();

        $finish;
    end
endmodule
