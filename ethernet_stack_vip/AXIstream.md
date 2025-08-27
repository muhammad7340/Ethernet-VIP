## AXI Stream
1. AXI-Stream (AXIS) is a streaming data protocol from ARM’s AXI family.

2. It’s used when you want to send continuous data (like packets, video, or samples) from one block (master) to another block (slave).

3. Analogy: Think of AXI-Stream like passing a packet word-by-word on a conveyor belt:
- One side (master) puts data on the belt.
- The other side (slave) says "I’m ready, give me more."
- Data moves only when both agree (handshake).

### Handshake Signals

The minimum AXI-Stream handshake uses 2 control signals:

- `TVALID` → Sender says: "I have valid data."
- `TREADY` → Receiver says: "I am ready to accept data."
- And 1 data signal: `TDATA` → The actual data word (e.g., 32-bit, 64-bit).
- Optional signals:
  - `TLAST` → Marks the last word of a packet/frame.
  - `TKEEP` → Byte-enable mask. Indicates which bytes in TDATA are valid (for partial words).
  - `TUSER` → User-defined sideband information (e.g., error flags).
Extra Signals:
- `TID` → Identifies the stream or packet (useful for multi-stream scenarios).
- `TDEST` → Indicates the destination of the data (useful for routing).


## AXI4-Full

Purpose: High-performance memory-mapped transactions (CPU ↔ memory, DMA, etc.).

### AXI4 Main Channels

AXI4 has 5 independent channels (all handshake-based with VALID/READY):

1. Write Address Channel (AW)
- Master → Slave
- Carries the address where data will be written.

2. Write Data Channel (W)
- Master → Slave
- Carries the data to write.

3. Write Response Channel (B)
- Slave → Master
- Sends back response (OKAY, SLVERR, DECERR).

4. Read Address Channel (AR)
- Master → Slave
- Carries the address to read from.

5. Read Data Channel (R)
- Slave → Master
- Carries the data read + response.
 
### Process FLow:
Example: Write Transaction

- Master puts address on AWADDR, asserts AWVALID.
- Slave asserts AWREADY → address accepted.
- Master puts data on WDATA, asserts WVALID.
- Slave asserts WREADY → data accepted.
- Slave sends BVALID response → Master asserts BREADY.

Example: Read Transaction

- Master puts read address on ARADDR, asserts ARVALID.
- Slave asserts ARREADY → address accepted.
- Slave sends data on RDATA with RVALID.
- Master asserts RREADY → data accepted.

### Handshake (same rule as AXIS)

Each channel uses the same handshake: `VALID = 1` AND `READY = 1` → transfer happens

### AXI4 Features
- Supports: Bursts (multiple beats per address) and enhanced control signals (e.g., `WID`, `BID`, `ARID`, `RID`).
- Handshake rule: Each channel uses VALID & READY.


## AXI4-Lite

Purpose: Simplified version for control registers (low bandwidth).
- Same 5 channels but: No bursts (single transfer only).
- Narrower data bus (e.g., 32-bit typical).
