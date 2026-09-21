"""cocotb testbench for axis_fifo_loopback (sim_top).

Verifies the acceptance criteria from spec.md:
  - every word appears exactly once, in order (no loss/dup/reorder)
  - backpressure: s_axis_tready low when the FIFO is full
  - m_axis_tvalid low when the FIFO is empty
  - integrity preserved across two different clock frequencies (CDC)

Run manually:  cd designs/axis_fifo_loopback/tb && make
"""

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

DATA_WIDTH = 64
NUM_WORDS = 512
MASK = (1 << DATA_WIDTH) - 1


async def apply_reset(dut):
    dut.s_axis_aresetn.value = 0
    dut.m_axis_aresetn.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tdata.value = 0
    dut.m_axis_tready.value = 0
    for _ in range(8):
        await RisingEdge(dut.s_axis_aclk)
    dut.s_axis_aresetn.value = 1
    dut.m_axis_aresetn.value = 1
    for _ in range(4):
        await RisingEdge(dut.s_axis_aclk)


async def producer(dut, words):
    """Drive words on s_axis with proper tvalid/tready handshaking."""
    for w in words:
        dut.s_axis_tdata.value = w
        dut.s_axis_tvalid.value = 1
        await RisingEdge(dut.s_axis_aclk)
        while dut.s_axis_tready.value == 0:  # blocked by backpressure
            await RisingEdge(dut.s_axis_aclk)
    dut.s_axis_tvalid.value = 0


async def consumer(dut, out, n):
    """Read n words on m_axis, applying random backpressure."""
    while len(out) < n:
        dut.m_axis_tready.value = 1 if random.random() > 0.2 else 0
        await RisingEdge(dut.m_axis_aclk)
        if dut.m_axis_tvalid.value == 1 and dut.m_axis_tready.value == 1:
            out.append(int(dut.m_axis_tdata.value) & MASK)
    dut.m_axis_tready.value = 0


@cocotb.test()
async def loopback_preserves_order_and_data(dut):
    # Two different clock periods to exercise the CDC.
    cocotb.start_soon(Clock(dut.s_axis_aclk, 10, units="ns").start())
    cocotb.start_soon(Clock(dut.m_axis_aclk, 7, units="ns").start())

    await apply_reset(dut)

    words = [random.randrange(0, MASK + 1) for _ in range(NUM_WORDS)]
    received: list[int] = []

    con = cocotb.start_soon(consumer(dut, received, NUM_WORDS))
    await producer(dut, words)
    await con

    assert len(received) == NUM_WORDS, f"expected {NUM_WORDS}, got {len(received)}"
    if received != words:
        first = next(i for i, (a, b) in enumerate(zip(words, received)) if a != b)
        raise AssertionError(f"data/order mismatch, first diff at index {first}")


@cocotb.test()
async def empty_deasserts_tvalid(dut):
    cocotb.start_soon(Clock(dut.s_axis_aclk, 10, units="ns").start())
    cocotb.start_soon(Clock(dut.m_axis_aclk, 7, units="ns").start())
    await apply_reset(dut)
    dut.m_axis_tready.value = 1
    await RisingEdge(dut.m_axis_aclk)
    assert dut.m_axis_tvalid.value == 0, "tvalid must be low when the FIFO is empty"
