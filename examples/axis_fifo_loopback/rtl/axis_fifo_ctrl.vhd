library ieee;
use ieee.std_logic_1164.all;

-- AXI-Stream <-> FIFO Generator (independent clocks, first-word-fall-through)
-- handshake glue. Data integrity and ordering are guaranteed by the FIFO; this
-- block is only the AXI-Stream handshake around the FIFO's raw ports.
entity axis_fifo_ctrl is
  generic (
    DATA_WIDTH : positive := 64
  );
  port (
    -- AXI-Stream slave (write clock domain)
    s_axis_aclk    : in  std_logic;
    s_axis_aresetn : in  std_logic;
    s_axis_tdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;

    -- AXI-Stream master (read clock domain)
    m_axis_aclk    : in  std_logic;
    m_axis_aresetn : in  std_logic;
    m_axis_tdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;

    -- FIFO Generator write side (wired up in the block design)
    fifo_din       : out std_logic_vector(DATA_WIDTH-1 downto 0);
    fifo_wr_en     : out std_logic;
    fifo_full      : in  std_logic;

    -- FIFO Generator read side (first-word-fall-through)
    fifo_dout      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    fifo_rd_en     : out std_logic;
    fifo_empty     : in  std_logic
  );
end entity axis_fifo_ctrl;

architecture rtl of axis_fifo_ctrl is
begin
  -- Write side: take a beat whenever the FIFO can accept one.
  s_axis_tready <= not fifo_full;
  fifo_wr_en    <= s_axis_tvalid and (not fifo_full);
  fifo_din      <= s_axis_tdata;

  -- Read side (FWFT): the head word is present on dout while not empty.
  m_axis_tvalid <= not fifo_empty;
  m_axis_tdata  <= fifo_dout;
  fifo_rd_en    <= m_axis_tready and (not fifo_empty);

  -- Note: resets are exposed for AXI-Stream convention; this glue is stateless,
  -- so all sequential state lives in the FIFO.
end architecture rtl;
