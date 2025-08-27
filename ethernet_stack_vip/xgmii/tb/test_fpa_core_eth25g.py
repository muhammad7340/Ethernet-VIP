import logging
import os

#This line imports specific classes (Ether, ARP, IP, UDP) from Scapy’s protocol layers.
#These classes represent packet headers used to construct or parse network packets at different OSI layers (L2 = Ethernet/ARP, L3 = IP, L4 = UDP).
from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP

import cocotb_test.simulator

import cocotb
from cocotb.log import SimLog
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

#Provides XGMII frame, source, and sink classes for 10G/25G Ethernet simulation.

from cocotbext.eth import XgmiiFrame, XgmiiSource, XgmiiSink








class TB:
    def __init__(self, dut):
        self.dut = dut  # Save the DUT (Device Under Test) reference for later use

        # Set up logging for the testbench using cocotb's SimLog
        self.log = SimLog("cocotb.tb")  
        self.log.setLevel(logging.DEBUG)  # Set log level to DEBUG for detailed output

        # Start a 2.56 ns period clock on the main DUT clock signal (dut.clk)
        cocotb.start_soon(Clock(dut.clk, 2.56, units="ns").start())

        # Initialize lists to hold XGMII sources (input to DUT) and sinks (output from DUT)
        self.sfp_source = []
        self.sfp_sink = []

        # Loop over SFP ports (e.g., sfp_1 and sfp_2)
        for y in range(1, 3):

            # Start RX clock for SFP port y (used for receiving data)
            cocotb.start_soon(Clock(getattr(dut, f"sfp_{y}_rx_clk"), 2.56, units="ns").start())

            # Create an XgmiiSource to send data into the DUT's RX interface for port y
            # Dynamically access the corresponding rxd, rxc, clk, and rst signals using getattr
            source = XgmiiSource(
                getattr(dut, f"sfp_{y}_rxd"),     # RX data bus
                getattr(dut, f"sfp_{y}_rxc"),     # RX control bus
                getattr(dut, f"sfp_{y}_rx_clk"),  # RX clock
                getattr(dut, f"sfp_{y}_rx_rst")   # RX reset
            )
            self.sfp_source.append(source)  # Add the source to the list for later access

            # Start TX clock for SFP port y (used for transmitting data)
            cocotb.start_soon(Clock(getattr(dut, f"sfp_{y}_tx_clk"), 2.56, units="ns").start())

            # Create an XgmiiSink to receive data from the DUT's TX interface for port y
            sink = XgmiiSink(
                getattr(dut, f"sfp_{y}_txd"),     # TX data bus
                getattr(dut, f"sfp_{y}_txc"),     # TX control bus
                getattr(dut, f"sfp_{y}_tx_clk"),  # TX clock
                getattr(dut, f"sfp_{y}_tx_rst")   # TX reset
            )
            self.sfp_sink.append(sink)  # Add the sink to the list for later access







    #------------------------------------------------------------------------------------------------------   
        # Define an asynchronous method to initialize/reset the DUT and related signals
    async def init(self):

        # Immediately set main DUT reset to 0 (inactive) before the simulation starts
        self.dut.rst.setimmediatevalue(0)

        # Loop over both SFP ports (1 and 2) to set their RX and TX resets to 0 (inactive)
        for y in range(1, 3):
            getattr(self.dut, f"sfp_{y}_rx_rst").setimmediatevalue(0)  # Set RX reset inactive
            getattr(self.dut, f"sfp_{y}_tx_rst").setimmediatevalue(0)  # Set TX reset inactive

        # Wait for 10 clock cycles — ensures the system settles/stabilizes before asserting reset
        for k in range(10):
            await RisingEdge(self.dut.clk)

        # Activate main reset signal — sets DUT into reset state
        self.dut.rst.value = 1

        # Activate RX and TX reset lines for both SFP ports
        for y in range(1, 3):
            getattr(self.dut, f"sfp_{y}_rx_rst").value = 1
            getattr(self.dut, f"sfp_{y}_tx_rst").value = 1

        # Hold reset active for 10 more clock cycles (common reset hold period)
        for k in range(10):
            await RisingEdge(self.dut.clk)

        # Deassert main reset (set to 0) — brings DUT out of reset
        self.dut.rst.value = 0

        # Deassert RX and TX resets for both SFP ports — brings SFP interfaces out of reset
        for y in range(1, 3):
            getattr(self.dut, f"sfp_{y}_rx_rst").value = 0
            getattr(self.dut, f"sfp_{y}_tx_rst").value = 0







#------------------------------------------------------------------------------------------------------
# Define a cocotb test coroutine, automatically run by the simulator
@cocotb.test()
async def run_test(dut):

    # Create an instance of the testbench class and pass in the DUT
    tb = TB(dut)

    # Run the initialization (resets, clocks) before starting the test
    await tb.init()

    # Log test activity (visible in simulator output)
    tb.log.info("test UDP RX packet")

    # Create a payload: 256 bytes with values 0 to 255 (repeats every 256)
    payload = bytes([x % 256 for x in range(256)])

    # Build Ethernet header: src and dst MAC addresses
    eth = Ether(src='5a:51:52:53:54:55', dst='02:00:00:00:00:00')

    # Build IP header: source and destination IPs
    ip = IP(src='192.168.1.100', dst='192.168.1.128')

    # Build UDP header: source and destination ports
    udp = UDP(sport=5678, dport=1234)

    # Stack layers together: Ethernet / IP / UDP / payload (creates full packet)
    test_pkt = eth / ip / udp / payload


    #test_pkt.build()-Converts the high-level Scapy packet into raw bytesto drive  the dut that expects raw bytes
    #XgmiiFrame.from_payload(...)-Wraps raw Ethernet frame into XGMII frame format for DUT input
    # Build raw packet bytes and convert to XGMII frame (for 10G Ethernet interface)
    test_frame = XgmiiFrame.from_payload(test_pkt.build())

    # Send the XGMII frame into the DUT Reciever portthrough SFP port 0's RX interface
    await tb.sfp_source[0].send(test_frame)






    #------------------------------------------------------------------------------------------------------
    # Log that we are expecting to receive an ARP request
    tb.log.info("receive ARP request")

    # Receive an XGMII frame from the DUT via SFP sink 0 (TX side of DUT)
    rx_frame = await tb.sfp_sink[0].recv()

    # Extract raw payload from the XGMII frame and parse it back into a Scapy Ethernet packet
    rx_pkt = Ether(bytes(rx_frame.get_payload()))

    # -----------------------------
    # Now we begin validating the ARP packet fields
    # -----------------------------

    # ARP packets are broadcast, so destination MAC should be all FFs (broadcast address)
    assert rx_pkt.dst == 'ff:ff:ff:ff:ff:ff'

    # Source MAC in ARP should be DUT's MAC — it should match the destination MAC in the test packet
    # Test send the destination mac address to DUT to recive the packet and forward it to some ip address given but it dont know the mac of that ip address.
    # here beasically we are seeing if the source address of packet we recieve matches the destination address of the packet we sent to dut.
    assert rx_pkt.src == test_pkt.dst

    #`validating that this ARP request is correctly formed and contains the expected info.``
    # Validate standard ARP header fields (these are part of ARP protocol spec)
    # Hardware type = 1 (Ethernet)
    assert rx_pkt[ARP].hwtype == 1
    # Protocol type = 0x0800 (IPv4)
    assert rx_pkt[ARP].ptype == 0x0800
    # Hardware address length = 6 (MAC address)
    assert rx_pkt[ARP].hwlen == 6
    # Protocol address length = 4 (IPv4 address)
    assert rx_pkt[ARP].plen == 4
    # Operation = 1 (ARP Request)
    assert rx_pkt[ARP].op == 1

    # Source hardware address in ARP should match DUT's MAC (same as test_pkt.dst)
    assert rx_pkt[ARP].hwsrc == test_pkt.dst
    # Source protocol address should be DUT's IP (same as destination IP in original test packet)
    assert rx_pkt[ARP].psrc == test_pkt[IP].dst
    # Target hardware address is unknown in ARP request — should be all zeros
    assert rx_pkt[ARP].hwdst == '00:00:00:00:00:00'
    # Target protocol address is the sender's IP (we're asking "who has this IP?")
    assert rx_pkt[ARP].pdst == test_pkt[IP].src



    #-----------------------------------------------------------------------------------------------------
    # Log the action for visibility in simulation output
    tb.log.info("send ARP response")

    # Construct the Ethernet frame header
    # - src: testbench MAC (pretending to be the owner of the target IP)
    # - dst: DUT's MAC (the one who asked via ARP)
    eth = Ether(
        src=test_pkt.src,  # '5a:51:52:53:54:55' — TB's MAC
        dst=test_pkt.dst   # '02:00:00:00:00:00' — DUT's MAC
    )

    # Build the ARP reply payload
    arp = ARP(
        hwtype=1,         # Hardware type: Ethernet
        ptype=0x0800,     # Protocol type: IPv4
        hwlen=6,          # Hardware address length: 6 bytes (MAC)
        plen=4,           # Protocol address length: 4 bytes (IPv4)
        op=2,             # Opcode 2 = ARP Reply
        hwsrc=test_pkt.src,      # Reply with our MAC (TB's MAC)
        psrc=test_pkt[IP].src,   # Reply with our IP (TB's IP)
        hwdst=test_pkt.dst,      # Tell who asked (DUT's MAC)
        pdst=test_pkt[IP].dst    # IP they were asking about (192.168.1.128)
    )

    # Combine Ethernet and ARP into one packet to send response for ARP inside ethernet frame, response doesnt need udp/ip 
    resp_pkt = eth / arp

    # Convert the Scapy packet into an XGMII frame (raw byte format)
    resp_frame = XgmiiFrame.from_payload(resp_pkt.build())

    # Send the ARP reply to the DUT via SFP port 0
    await tb.sfp_source[0].send(resp_frame)
    


    #-----------------------------------------------------------------------------------------------------

    tb.log.info("receive UDP packet")
    rx_frame = await tb.sfp_sink[0].recv()
    rx_pkt = Ether(bytes(rx_frame.get_payload()))
    tb.log.info("RX packet: %s", repr(rx_pkt))
    assert rx_pkt.dst == test_pkt.src
    assert rx_pkt.src == test_pkt.dst
    assert rx_pkt[IP].dst == test_pkt[IP].src
    assert rx_pkt[IP].src == test_pkt[IP].dst
    assert rx_pkt[UDP].dport == test_pkt[UDP].sport
    assert rx_pkt[UDP].sport == test_pkt[UDP].dport
    assert rx_pkt[UDP].payload == test_pkt[UDP].payload
 
    #-----------------------------------------------------------------------------------------------------
    # Log that we're expecting a UDP packet from DUT
    tb.log.info("receive UDP packet")
    # Await and receive an XGMII frame from DUT on port 0
    rx_frame = await tb.sfp_sink[0].recv()

    # Convert raw bytes payload back to a Scapy Ethernet packet
    rx_pkt = Ether(bytes(rx_frame.get_payload()))
    # Log received packet details for debugging
    tb.log.info("RX packet: %s", repr(rx_pkt))


    # Verify Ethernet addresses are reversed (since this is a reply from dut back to testbench)
    assert rx_pkt.dst == test_pkt.src
    assert rx_pkt.src == test_pkt.dst
    # Verify IP addresses are reversed (reply packet)
    assert rx_pkt[IP].dst == test_pkt[IP].src
    assert rx_pkt[IP].src == test_pkt[IP].dst

    # Verify UDP ports swapped (reply)
    assert rx_pkt[UDP].dport == test_pkt[UDP].sport
    assert rx_pkt[UDP].sport == test_pkt[UDP].dport
    # Verify payload matches original data
    assert rx_pkt[UDP].payload == test_pkt[UDP].payload
