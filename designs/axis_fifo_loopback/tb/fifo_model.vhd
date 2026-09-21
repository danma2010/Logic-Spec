library ieee;
use ieee.std_logic_1164.all;

-- Behavioural (simulation-only) first-word-fall-through FIFO with independent
-- read/write clocks. This is a FUNCTIONAL stand-in for the fast cocotb loop, not
-- a timing or metastability model of the real IP. For full verification, replace
-- the instance with the generated fifo_512x64 (see sim/RUN.md).
entity fifo_model is
  generic (
    DATA_WIDTH : positive := 64;
    DEPTH      : positive := 512
  );
  port (
    wr_clk : in  std_logic;
    rd_clk : in  std_logic;
    din    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_en  : in  std_logic;
    full   : out std_logic;
    dout   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_en  : in  std_logic;
    empty  : out std_logic
  );
end entity fifo_model;

architecture bhv of fifo_model is
  type mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
begin
  process (wr_clk, rd_clk) is
    variable mem  : mem_t;
    variable head : natural := 0;
    variable tail : natural := 0;
    variable cnt  : natural := 0;
  begin
    -- write on wr_clk
    if rising_edge(wr_clk) then
      if wr_en = '1' and cnt < DEPTH then
        mem(tail) := din;
        tail := (tail + 1) mod DEPTH;
        cnt  := cnt + 1;
      end if;
    end if;

    -- read on rd_clk
    if rising_edge(rd_clk) then
      if rd_en = '1' and cnt > 0 then
        head := (head + 1) mod DEPTH;
        cnt  := cnt - 1;
      end if;
    end if;

    -- outputs: FWFT presents the head word while not empty
    if cnt > 0 then
      dout  <= mem(head);
      empty <= '0';
    else
      empty <= '1';
    end if;

    if cnt >= DEPTH then
      full <= '1';
    else
      full <= '0';
    end if;
  end process;
end architecture bhv;
