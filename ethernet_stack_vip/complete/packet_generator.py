# Import ARP, Ethernet, IP, Udp class from Scapy's Layer 2 modules
from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP


#---------------------------------------- ARP ------------------------------------------#
# Define a Python function to create an ARP frame return it as a byte, list of values 2^8(0-255).
def create_arp_frame(hwsrc, psrc, hwdst, pdst,
                     hwtype=1, ptype=0x0800, hwlen=6, plen=4, op=2):

    # Create an ARP object using Scapy's ARP class that builds ARP packet using Scapy and store them into an object
    arp = ARP(hwtype=hwtype, ptype=ptype, hwlen=hwlen,
              plen=plen, op=op, hwsrc=hwsrc, psrc=psrc,
              hwdst=hwdst, pdst=pdst)
    
    """
    # Additional for debugging only 
    print("-------------[DEBUG_Python] ARP Frame Created in Python-------------------")
    arp.show()
    print("-----------------------[DEBUG_Python] ARP Frame Bytes---------------------")
    print(bytes(arp))
    print("-----------------------[DEBUG_Python] ARP Frame list----------------------")
    print(list(bytes(arp)))
    print("--------------------------------------------------------------------------")
    """
    # Convert Scapy packet object to bytes, then to a list of integers (0-255)
    return list(bytes(arp)) # byte:"\x00\x01\x08\.. --> list:"[0xff,0x08, 0x01]


#---------------------------------------- Ethernet ----------------------------------------#

def create_eth_frame(src_mac, dst_mac, eth_type=0x0800):
    # Create Ethernet frame (list of bytes) with source/destination MAC and EtherType (0x0800) for IPV4
    eth = Ether(src=src_mac, dst=dst_mac, type=eth_type)
    return list(bytes(eth))

#------------------------------------------- IP -------------------------------------------#
def create_ip_header(src_ip, dst_ip, proto=17):
    # Create IPv4 header (list of bytes) with source/destination IPs and protocol number (17-default)
    ip = IP(src=src_ip, dst=dst_ip, proto=proto)
    return list(bytes(ip))

#------------------------------------------- UDP -------------------------------------------#
def create_udp_header(sport, dport, payload_len=0):
    # Create UDP header (list of bytes) with source/destination ports and optional payload length (0-default)
    udp = UDP(sport=sport, dport=dport, len=8 + payload_len)
    return list(bytes(udp))




""" Signals Description:
  PARAMETERS (Inputs):
    - hwsrc  : Source MAC address (e.g., "aa:bb:cc:dd:ee:ff")
    - psrc   : Source IP address (e.g., "192.168.1.1")
    - hwdst  : Target MAC address
    - pdst   : Target IP address
    - hwtype : Hardware type (1 = Ethernet, default)
    - ptype  : Protocol type (0x0800 = IPv4, default)
    - hwlen  : Hardware address length (6 bytes for MAC)
    - plen   : Protocol address length (4 bytes for IPv4)
    - op     : Operation type (1 = request, 2 = reply)
"""







