library ieee;
use ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;

-- axis_fifo_loopback — unit top (architecture.md `top:`).
-- AXI-Stream CDC loopback: axis_fifo_ctrl handshake glue around an XPM
-- dual-clock first-word-fall-through FIFO. Reused by parents through direct
-- RTL instantiation; DATA_WIDTH / DEPTH are set by the parent.
entity axis_fifo_loopback is
  generic (
    DATA_WIDTH : positive := 64;
    DEPTH      : positive := 512;   -- power of 2, >= 16
    CDC_STAGES : positive := 2
  );
  port (
    s_axis_aclk    : in  std_logic;
    s_axis_aresetn : in  std_logic;
    s_axis_tdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;

    m_axis_aclk    : in  std_logic;
    m_axis_aresetn : in  std_logic;   -- AXI convention; XPM resets both domains from rst
    m_axis_tdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic
  );
end entity axis_fifo_loopback;

architecture rtl of axis_fifo_loopback is
  signal rst                     : std_logic;
  signal din, dout               : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wr_en, rd_en            : std_logic;
  signal full, empty             : std_logic;
  signal wr_rst_busy, rd_rst_busy : std_logic;
  signal ctrl_full, ctrl_empty   : std_logic;
begin

  rst <= not s_axis_aresetn;            -- XPM rst: active high, wr_clk domain

  -- Never write or read while the XPM reset sequence is in progress.
  ctrl_full  <= full  or wr_rst_busy;
  ctrl_empty <= empty or rd_rst_busy;

  ctrl : entity work.axis_fifo_ctrl
    generic map (DATA_WIDTH => DATA_WIDTH)
    port map (
      s_axis_aclk    => s_axis_aclk,
      s_axis_aresetn => s_axis_aresetn,
      s_axis_tdata   => s_axis_tdata,
      s_axis_tvalid  => s_axis_tvalid,
      s_axis_tready  => s_axis_tready,
      m_axis_aclk    => m_axis_aclk,
      m_axis_aresetn => m_axis_aresetn,
      m_axis_tdata   => m_axis_tdata,
      m_axis_tvalid  => m_axis_tvalid,
      m_axis_tready  => m_axis_tready,
      fifo_din       => din,
      fifo_wr_en     => wr_en,
      fifo_full      => ctrl_full,
      fifo_dout      => dout,
      fifo_rd_en     => rd_en,
      fifo_empty     => ctrl_empty
    );

  fifo : xpm_fifo_async
    generic map (
      CDC_SYNC_STAGES     => CDC_STAGES,
      DOUT_RESET_VALUE    => "0",
      ECC_MODE            => "no_ecc",
      FIFO_MEMORY_TYPE    => "auto",
      FIFO_READ_LATENCY   => 0,          -- required for fwft
      FIFO_WRITE_DEPTH    => DEPTH,
      FULL_RESET_VALUE    => 1,          -- tready low during reset
      PROG_EMPTY_THRESH   => 10,
      PROG_FULL_THRESH    => 10,
      RD_DATA_COUNT_WIDTH => 1,
      READ_DATA_WIDTH     => DATA_WIDTH,
      READ_MODE           => "fwft",
      RELATED_CLOCKS      => 0,
      SIM_ASSERT_CHK      => 1,
      USE_ADV_FEATURES    => "0000",
      WAKEUP_TIME         => 0,
      WRITE_DATA_WIDTH    => DATA_WIDTH,
      WR_DATA_COUNT_WIDTH => 1
    )
    port map (
      sleep         => '0',
      rst           => rst,
      wr_clk        => s_axis_aclk,
      wr_en         => wr_en,
      din           => din,
      full          => full,
      prog_full     => open,
      wr_data_count => open,
      overflow      => open,
      wr_rst_busy   => wr_rst_busy,
      almost_full   => open,
      wr_ack        => open,
      rd_clk        => m_axis_aclk,
      rd_en         => rd_en,
      dout          => dout,
      empty         => empty,
      prog_empty    => open,
      rd_data_count => open,
      underflow     => open,
      rd_rst_busy   => rd_rst_busy,
      almost_empty  => open,
      data_valid    => open,
      injectsbiterr => '0',
      injectdbiterr => '0',
      sbiterr       => open,
      dbiterr       => open
    );

end architecture rtl;
