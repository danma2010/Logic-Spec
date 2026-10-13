"""cocotb tests for axis_fifo_loopback — one test per testplan.md entry.

Default DUT: the unit top `axis_fifo_loopback` (XPM FIFO). `make FAST=1` uses
`sim_top` (same controller + behavioural FIFO) for quick iteration only.

Handshake convention: values are driven right after a rising edge and the
transfer decision uses the values read right after the *next* rising edge,
i.e. the values present at that edge (cocotb resumes before the edge's
registered updates are visible).

Run:  bash tools/run_tests.sh axis_fifo_loopback   (see sim/RUN.md)
"""

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

DEPTH = 512
_COCOTB2 = int(cocotb.__version__.split(".")[0]) >= 2


def _clock(sig, period_ns):
    clk = Clock(sig, period_ns, "ns")
    if _COCOTB2:
        clk.start()
    else:
        cocotb.start_soon(clk.start())


def _mask(dut):
    return (1 << len(dut.s_axis_tdata)) - 1


def _is1(sig):
    return str(sig.value) == "1"


async def setup(dut, s_ns, m_ns):
    _clock(dut.s_axis_aclk, s_ns)
    _clock(dut.m_axis_aclk, m_ns)
    dut.s_axis_aresetn.value = 0
    dut.m_axis_aresetn.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tdata.value = 0
    dut.m_axis_tready.value = 0
    for _ in range(16):
        await RisingEdge(dut.s_axis_aclk)
    dut.s_axis_aresetn.value = 1
    dut.m_axis_aresetn.value = 1


async def wait_ready(dut, timeout=2000):
    """Wait until the write side leaves reset (tready high at an edge)."""
    for _ in range(timeout):
        await RisingEdge(dut.s_axis_aclk)
        if _is1(dut.s_axis_tready):
            return
    raise AssertionError(f"s_axis_tready never rose within {timeout} cycles after reset")


class Producer:
    """Drives words on s_axis; counts accepted beats and backpressure."""

    def __init__(self, dut):
        self.dut = dut
        self.accepted = 0
        self.saw_backpressure = False

    async def send(self, words):
        dut = self.dut
        await wait_ready(dut)
        for w in words:
            dut.s_axis_tdata.value = w
            dut.s_axis_tvalid.value = 1
            while True:
                await RisingEdge(dut.s_axis_aclk)
                if _is1(dut.s_axis_tready):
                    self.accepted += 1
                    break
                self.saw_backpressure = True
        dut.s_axis_tvalid.value = 0


async def consume(dut, n, out, stall=0.2):
    """Read n words on m_axis with random backpressure (probability `stall`)."""
    mask = _mask(dut)
    while len(out) < n:
        ready = 0 if random.random() < stall else 1
        dut.m_axis_tready.value = ready
        await RisingEdge(dut.m_axis_aclk)
        if ready and _is1(dut.m_axis_tvalid):
            out.append(int(dut.m_axis_tdata.value) & mask)
    dut.m_axis_tready.value = 0


def _compare(sent, got):
    assert len(got) == len(sent), f"expected {len(sent)} words, got {len(got)}"
    if got != sent:
        i = next(i for i, (a, b) in enumerate(zip(sent, got)) if a != b)
        raise AssertionError(f"order/data mismatch at index {i}: sent {sent[i]:#x}, got {got[i]:#x}")


async def stream(dut, n, stall=0.2):
    mask = _mask(dut)
    sent = [random.randrange(0, mask + 1) for _ in range(n)]
    got = []
    prod = Producer(dut)
    con = cocotb.start_soon(consume(dut, n, got, stall))
    await prod.send(sent)
    await con
    return sent, got, prod


@cocotb.test()
async def t01_order_integrity(dut):
    """T01 (AC-1, AC-4): 1024 words, s 10 ns / m 7 ns, 20 % stalls -> received == sent."""
    await setup(dut, 10, 7)
    sent, got, _ = await stream(dut, 1024, stall=0.2)
    _compare(sent, got)


@cocotb.test()
async def t02_backpressure_full(dut):
    """T02 (AC-2, AC-1): consumer stalled -> tready low after DEPTH-8..DEPTH+4 words,
    stays low 50 cycles with no beat accepted; then all accepted words drain in order."""
    await setup(dut, 10, 7)
    mask = _mask(dut)
    dut.m_axis_tready.value = 0
    await wait_ready(dut)

    sent = []
    low_run = 0
    while low_run < 50:
        w = random.randrange(0, mask + 1)
        dut.s_axis_tdata.value = w
        dut.s_axis_tvalid.value = 1
        await RisingEdge(dut.s_axis_aclk)
        if _is1(dut.s_axis_tready):
            assert low_run == 0, "a beat was accepted after tready had been low (no space freed)"
            sent.append(w)
        else:
            low_run += 1
        assert len(sent) <= DEPTH + 4, f"accepted {len(sent)} words without backpressure"
    dut.s_axis_tvalid.value = 0
    n = len(sent)
    assert DEPTH - 8 <= n <= DEPTH + 4, f"tready fell after {n} words, expected {DEPTH - 8}..{DEPTH + 4}"

    got = []
    await consume(dut, n, got, stall=0.0)
    _compare(sent, got)


@cocotb.test()
async def t03_empty_tvalid_low(dut):
    """T03 (AC-3): tvalid low for 200 cycles when empty after reset, and for 100
    cycles after a 16-word burst has drained."""
    await setup(dut, 10, 7)
    dut.m_axis_tready.value = 1
    for i in range(200):
        await RisingEdge(dut.m_axis_aclk)
        assert not _is1(dut.m_axis_tvalid), f"tvalid high while empty (cycle {i} after reset)"

    sent, got, _ = await stream(dut, 16, stall=0.0)
    _compare(sent, got)
    dut.m_axis_tready.value = 1
    for i in range(100):
        await RisingEdge(dut.m_axis_aclk)
        assert not _is1(dut.m_axis_tvalid), f"tvalid high after drain (cycle {i})"


@cocotb.test()
async def t04_cdc_fast_writer(dut):
    """T04 (AC-4, AC-1, AC-2): s 4 ns / m 13 ns, 2048 words, 20 % stalls ->
    received == sent and backpressure observed at least once."""
    await setup(dut, 4, 13)
    sent, got, prod = await stream(dut, 2048, stall=0.2)
    _compare(sent, got)
    assert prod.saw_backpressure, "FIFO never filled — tready was never observed low"
