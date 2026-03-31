import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import os

# Set ASSERT value
ASSERT = True
if "NOASSERT" in os.environ:
    ASSERT = False

## Start testbench from a hardware reset
#async def reset(dut):
#    dut.reset.value = 1
#
#    await ClockCycles(dut.clk, 5)
#    dut.reset.value = 0;

@cocotb.test()
async def test_tt(dut):
    """Simple functional test for Present cipher, tt_um_present module"""

    # ----------------------------
    # Clock generation: 10 us
    # ----------------------------
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # ----------------------------
    # Reset
    # ----------------------------
    dut.rst_n.value = 0
    dut.uio_in.value = 0
    #dut.idat.value = 0
    #dut.key

    await Timer(50, units="us") # Can also be done by clock-cycles, as in examples
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)   # with clockCycles this is not needed

    # ----------------------------
    # Test key and plaintext
    # ----------------------------
    # https://opencores.org/websvn/filedetails?repname=present&path=%2Fpresent%2Ftrunk%2FDecode%2Fbench%2Fvhdl%2FPresentFullDecoderTB.vhd
    #
    # 1-send key with cmd=1
    # 2-send data with cmd=2
    # 3-send "load" signal to start encryption cycle, with cmd=3 
    # 4-wait until "data_top_valid" is high
    # 5-read output


    # ----------------------------
    # Load 80-bits key
    # ----------------------------
    for _ in range(10):
        key_byte = int("00", 16) 
        dut.uio_in.value = 1
        dut.ui_in.value = key_byte
        await RisingEdge(dut.clk)

    # ----------------------------
    # Wait one clock cycle, because why not
    # ----------------------------
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)

    # ----------------------------
    # Load input 68-bits data
    # ----------------------------
    for _ in range(8):
        dut.uio_in.value = 2
        dut.ui_in.value = int("ff", 16)
        await RisingEdge(dut.clk)

    # ----------------------------
    # Wait one clock cycle, because why not
    # ----------------------------
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)

    # ----------------------------
    # Send load comand, 1 clock cycle, then reset to zero
    # ----------------------------
    dut.uio_in.value = 3
    await RisingEdge(dut.clk)
    dut.uio_in.value = 0

    # ----------------------------
    # Wait until data_top_valid is high
    # ----------------------------
    while dut.uio_out.value[2] == 0:
        await RisingEdge(dut.clk)

    # ----------------------------
    # Collect output bytes, 8 rounds
    # ----------------------------
    ciphertext_bytes = []
    

    for _ in range(8):
        await RisingEdge(dut.clk)
        cp = hex(dut.uo_out.value)
        #ciphertext_bytes = bytes.fromhex(cp)
        dut._log.info(f"Read byte: {cp}")
        ciphertext_bytes.append(int(cp, 16))

    assert bytearray(ciphertext_bytes).hex() == "a112ffc72f68417b"

    dut.uio_in.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)

    # ----------------------------
    # ROUND 2
    # ----------------------------

    dut.uio_in.value = 0b10000000

    # ----------------------------
    # Load input 68-bits data
    # ----------------------------
    for _ in range(8):
        dut.uio_in.value = 0b10000010
        dut.ui_in.value = int("ff", 16)
        await RisingEdge(dut.clk)

    # ----------------------------
    # Wait one clock cycle, because why not
    # ----------------------------
    dut.uio_in.value = 0b10000000
    await RisingEdge(dut.clk)

    # ----------------------------
    # Send load comand, 1 clock cycle, then reset to zero
    # ----------------------------
    dut.uio_in.value = 0b10000011
    await RisingEdge(dut.clk)
    dut.uio_in.value = 0b10000000

    # ----------------------------
    # Wait until data_top_valid is high
    # ----------------------------
    while dut.uio_out.value[2] == 0:
        await RisingEdge(dut.clk)

    # ----------------------------
    # Collect output bytes, 8 rounds
    # ----------------------------
    ciphertext_bytes = []
    

    for _ in range(8):
        await RisingEdge(dut.clk)
        cp = hex(dut.uo_out.value)
        #ciphertext_bytes = bytes.fromhex(cp)
        dut._log.info(f"Read byte: {cp}")
        ciphertext_bytes.append(int(cp, 16))

    #assert bytearray(ciphertext_bytes).hex() == "a112ffc72f68417b"