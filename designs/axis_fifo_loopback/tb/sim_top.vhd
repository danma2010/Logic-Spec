library ieee;
use ieee.std_logic_1164.all;

-- Simulation-only top: the REAL controller (axis_fifo_ctrl) wired to the
-- behavioural FIFO model. cocotb drives this via s_axis / m_axis. The hardware
-- top is the block-design wrapper produced by bd/build_bd.tcl instead.
entity sim_top is
  generic (
    DATA_WIDTH : positive := 64
  );
  port (
    s_axis_aclk    : in  std_logic;
    s_axis_aresetn : in  std_logic;
    s_axis_tdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;

    m_axis_aclk    : in  std_logic;
    m_axis_aresetn : in  std_logic;
    m_axis_tdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic
  );
end entity sim_top;

architecture sim of sim_top is
  signal din, dout               : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wr_en, full, rd_en, empty : std_logic;
begin

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
      fifo_full      => full,
      fifo_dout      => dout,
      fifo_rd_en     => rd_en,
      fifo_empty     => empty
    );

  fifo : entity work.fifo_model
    generic map (DATA_WIDTH => DATA_WIDTH, DEPTH => 512)
    port map (
      wr_clk => s_axis_aclk,
      rd_clk => m_axis_aclk,
      din    => din,
      wr_en  => wr_en,
      full   => full,
      dout   => dout,
      rd_en  => rd_en,
      empty  => empty
    );

end architecture sim;
