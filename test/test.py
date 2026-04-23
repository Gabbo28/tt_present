import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import os

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

# Set ASSERT value
ASSERT = True
if "NOASSERT" in os.environ:
    ASSERT = False


async def load_key_hex(dut, key_hex):
    key = bytes.fromhex(key_hex)
    dut._log.info(f"Loading KEY = 0x{key_hex}")
    for val in key:
        dut.uio_in.value = 1
        dut.ui_in.value = val
        await RisingEdge(dut.clk)
    dut.uio_in.value = 0

async def load_data_hex(dut, data_hex):
    data = bytes.fromhex(data_hex)
    dut._log.info(f"Loading PLAINTEXT = 0x{data_hex}")
    for val in data:
        dut.uio_in.value = 2
        dut.ui_in.value = val
        await RisingEdge(dut.clk)
    dut.uio_in.value = 0
    
async def load(dut):
    dut.uio_in.value = 3
    await RisingEdge(dut.clk)
    dut.uio_in.value = 0

async def read_ciphertext(dut):
    # Wait until data_top_valid is high
    while dut.uio_out.value[2] == 0:
        await RisingEdge(dut.clk)

    # Collect output bytes, 8 rounds
    ciphertext_bytes = []
    
    for _ in range(8):
        await RisingEdge(dut.clk)
        cp = hex(dut.uo_out.value)
        # dut._log.info(f"Read byte: {cp}")
        ciphertext_bytes.append(int(cp, 16))
    ciphertext = bytearray(ciphertext_bytes).hex()
    dut._log.info(f"CIPHERTEXT: {ciphertext}")
    return ciphertext

@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_present_encryption(dut):
    dut._log.info("\nPresent-80 encryption tests")

    # Clock generation: 100 ns
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.uio_in.value = 0
    
    await Timer(500, unit="ns") # Can also be done by clock-cycles, as in examples
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)   # with clockCycles this is not needed

    # ----------------------------
    # Testcase 1
    # ---------------------------- 
    dut._log.info(f"\nTestcase 1\n")
    
    key_hex     = "00000000000000000000"
    data_hex    = "0000000000000000"   
    expected    = "5579c1387b228445"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)


    # ----------------------------
    # Testcase 2
    # ---------------------------- 
    dut._log.info(f"\nTestcase 2\n")
    
    key_hex     = "00000000000000000000"
    data_hex    = "ffffffffffffffff"   
    expected    = "a112ffc72f68417b"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)

    # ----------------------------
    # Testcase 3
    # ---------------------------- 
    dut._log.info(f"\nTestcase 3\n")
    
    key_hex     = "ffffffffffffffffffff"
    data_hex    = "0000000000000000"   
    expected    = "e72c46c0f5945049"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)


    # ----------------------------
    # Testcase 4
    # ---------------------------- 
    dut._log.info(f"\nTestcase 4\n")
    
    key_hex     = "ffffffffffffffffffff"
    data_hex    = "ffffffffffffffff"   
    expected    = "3333dcd3213210d2"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_hw_trojan(dut):
    dut._log.info("\nPresent-80 glitching tests")

    # Clock generation: 100 ns
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.uio_in.value = 0
    
    await Timer(500, unit="ns") # Can also be done by clock-cycles, as in examples
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)   # with clockCycles this is not needed


    # ----------------------------
    # ROUND 1
    # ----------------------------
    dut._log.info(f"\nEncryption Round 1: mask 0000\n")
    
    key_hex     = "00000000000000000000"
    data_hex    = "ffffffffffffffff"   
    expected    = "a112ffc72f68417b"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    #assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)

    # ----------------------------
    # ROUND 2
    # ----------------------------

    dut._log.info(f"\nEncryption Round 2: mask 1000\n")
    
    key_hex     = "00000000000000000000"
    data_hex    = "ffffffffffffffff"   
    expected    = "5fe15253d0b6be84"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)


    # ----------------------------
    # ROUND 3
    # ----------------------------

    dut._log.info(f"\nEncryption Round 3: mask 0100\n")
    
    key_hex     = "00000000000000000000"
    data_hex    = "ffffffffffffffff"   
    expected    = "5fe15253d0b6be84"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    #assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)


    # ----------------------------
    # ROUND 4
    # ----------------------------

    dut._log.info(f"\nEncryption Round 4: mask 0010\n")
    
    key_hex     = "00000000000000000000"
    data_hex    = "ffffffffffffffff"   
    expected    = "5fe15253d0b6be84"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    #assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)

    
    # ----------------------------
    # ROUND 5
    # ----------------------------

    dut._log.info(f"\nEncryption Round 5: mask 0001\n")
    
    key_hex     = "00000000000000000000"
    data_hex    = "ffffffffffffffff"   
    expected    = "5fe15253d0b6be84"

    # Load 80-bits key
    await load_key_hex(dut, key_hex)

    # Load input 68-bits data
    await load_data_hex(dut, data_hex)

    # Send load comand, 1 clock cycle, then reset to zero
    await load(dut) 

    # Read output
    ciphertext = await read_ciphertext(dut)

    # Assertion
    #assert ciphertext == expected
    
    # Wait some time
    for _ in range(10):
        await RisingEdge(dut.clk)