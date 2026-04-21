------------------------------------------------------------------------------------------
-- Lab 04
-- David W. Moore & Nate Powell
--
-- TransferController
------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MetaStab.ALL;

entity TransferController is
    generic (
        NUMLIGHTS: integer := 10 
    );
    Port (
        clock         : in  STD_LOGIC; -- 100MHz
        reset         : in  STD_LOGIC;
        activePatternBack : in std_logic_vector(2 downto 0);
        activePatternBall : in std_logic_vector(2 downto 0);
        moveLeft        : in std_logic;
        moveRight       : in std_logic;
        tx_out        : out STD_LOGIC;
        busy          : out STD_LOGIC;
        sevenSegs     : out STD_LOGIC_VECTOR (6 downto 0);
        anodes        : out STD_LOGIC_VECTOR (3 downto 0)
    );
end TransferController;

architecture TransferController_ARCH of TransferController is
    
    component SevenSegmentDriver is
        port(
            reset: in std_logic;
            clock: in std_logic;
            digit3, digit2, digit1, digit0 : in std_logic_vector(3 downto 0);
            blank3, blank2, blank1, blank0 : in std_logic;
            sevenSegs : out std_logic_vector(6 downto 0);
            anodes    : out std_logic_vector(3 downto 0)
        );
    end component;


    -- Timing Constants for 100MHz (10ns per tick)
    constant T0H : integer := 40;   constant T0L : integer := 85;
    constant T1H : integer := 80;   constant T1L : integer := 45;
    constant T_RES : integer := 10000; --little longer now

    type state_type is (IDLE, FETCH, FETCH_WAIT, SEND_BIT, WAIT_T_HIGH, WAIT_T_LOW, NEXT_LED, LATCH);
    signal state : state_type := IDLE;
    
    signal bit_cnt     : integer range 0 to 24 := 0;
    signal ctr         : integer := 0;
    signal led_cnt     : integer range 0 to 255 := 0; 
    signal current_bit : std_logic;
    signal dataBack   : std_logic_vector(23 downto 0);
    signal dataBall   : std_logic_vector(23 downto 0);
   
    signal outputPatternBack : std_logic_vector(3 downto 0);
    signal outputPatternBall : std_logic_vector(3 downto 0);
    
    signal cleanLeft    : std_logic;
    signal cleanRight   : std_logic;
    signal moveLeft_pulse  : std_logic; 
    signal moveRight_pulse : std_logic;
    signal cleanLeftPrev : std_logic;
    signal cleanRightPrev : std_logic;
    
    signal ledRegister  : std_logic_vector (9 downto 0) := "0000000001";
    signal target_color : std_logic_vector(23 downto 0);
    signal current_led_color : std_logic_vector(23 downto 0);
    
    signal debounce_ctr : integer range 0 to 100000 := 0; 
    signal debounce_tick : std_logic := '0';
    signal drawRegister : std_logic_vector (9 downto 0) := "0000000001";
    
    -- Intermediate signals for metastabilization
    signal moveLeft_mid, moveRight_mid : std_logic := '0';
    signal activePatternBall_mid, activePatternBack_mid : std_logic_vector(2 downto 0) := (others => '0');

    -- Metastabilized signals
    signal moveLeft_sync, moveRight_sync : std_logic;
    signal activePatternBall_sync, activePatternBack_sync : std_logic_vector(2 downto 0);
    
begin


    TRANSMITTER: process(clock, reset)
    begin
    if reset = '1' then
        state <= IDLE;
        tx_out <= '0';
        busy <= '0';
        ctr <= 0;
        led_cnt <= 0;
        bit_cnt <= 0;
        
    elsif rising_edge(clock) then
        case state is
            
           when IDLE =>
                tx_out <= '0';
                busy <= '1';
                led_cnt <= 0;
                bit_cnt <= 0;
                state <= SEND_BIT; 
                
                drawRegister <= ledRegister;
                current_led_color <= target_color;

           when SEND_BIT =>
                if bit_cnt < 24 then
                    -- Read from the locked current_led_color, NOT target_color
                    current_bit <= current_led_color(23 - bit_cnt); 
                    tx_out <= '1';
                    ctr <= 0;
                    state <= WAIT_T_HIGH;
                else
                    ctr <= 0;
                    if led_cnt < NUMLIGHTS - 1 then
                        led_cnt <= led_cnt + 1;
                        state <= NEXT_LED;
                    else
                        led_cnt <= 0;
                        state <= LATCH; 
                    end if;
                end if;

            when WAIT_T_HIGH =>
                ctr <= ctr + 1;
                if (current_bit = '0' and ctr >= T0H) or (current_bit = '1' and ctr >= T1H) then
                    tx_out <= '0';
                    ctr <= 0;
                    state <= WAIT_T_LOW;
                end if;

            when WAIT_T_LOW =>
                ctr <= ctr + 1;
                if (current_bit = '0' and ctr >= T0L) or (current_bit = '1' and ctr >= T1L) then
                    bit_cnt <= bit_cnt + 1;
                    state <= SEND_BIT;
                end if;

           when NEXT_LED =>
                
                current_led_color <= target_color;  -- gets color when safe
                bit_cnt <= 0;
                state <= SEND_BIT;

            when LATCH =>
                tx_out <= '0';
                if ctr < T_RES then
                    ctr <= ctr + 1;
                else
                    ctr <= 0;
                    state <= IDLE; -- new frame
                end if;

            when others => 
                state <= IDLE;
        end case;
    end if;
end process;
    
    
    METASTABILIZER: process(clock, reset)
    begin
    -- this thing is a monster.
    STABILIZE_INTERFACE
    (
    clock => clock,
    reset => reset,
    moveLeft => moveLeft,
    moveRight => moveRight, 
    activePatternBall => activePatternBall,
    activePatternBack => activePatternBack,
    moveLeft_mid => moveLeft_mid,
    moveRight_mid => moveRight_mid,
    activePatternBall_mid => activePatternBall_mid, 
    activePatternBack_mid => activePatternBack_mid,
    moveLeft_sync => moveLeft_sync,
    moveRight_sync => moveRight_sync,
    activePatternBall_sync => activePatternBall_sync,
    activePatternBack_sync => activePatternBack_sync
    );
    
    end process;
    
    
    --============================================================================
    --  debounces the left and right buttons using shift regs
    --============================================================================
    DEBOUNCE: process (reset, clock)
        variable leftReg: std_logic_vector (7 downto 0) := (others => '0');
        variable rightReg: std_logic_vector (7 downto 0) := (others => '0');
    begin   
        if (reset = '1') then
            leftReg := (others => '0');
            rightReg := (others => '0');
            cleanLeft <= '0';
            cleanRight <= '0';
            
        elsif (rising_edge (clock)) then
            if (debounce_tick = '1') then
                leftReg := moveLeft_sync & leftReg(7 downto 1);
                rightReg := moveRight_sync & rightReg(7 downto 1);
            end if;
            
            if (leftReg = "00000000") then
                cleanLeft <= '0';
            elsif (leftReg = "11111111") then
                cleanLeft <= '1';
            end if;
            
            if (rightReg = "00000000") then
                cleanRight <= '0';
            elsif (rightReg = "11111111") then
                cleanRight <= '1';
            end if;
        
       end if;
    end process;
    
    LED_MOVE: process (clock, reset) --taken from old code made to wrap
    begin
        if (reset = '1') then
            ledRegister <= "0000000001";
        elsif (rising_edge(clock)) then
            
            if (moveLeft_pulse = '1') then
                ledRegister <= ledRegister(8 downto 0) & ledRegister(9);
            
            elsif (moveRight_pulse = '1') then
                ledRegister <= ledRegister(0) & ledRegister(9 downto 1);
                
            end if;
        end if;
    end process;
    
    DEBOUNCE_CLOCK: process(clock) --stupid bullshit had moving colors but over lap needed for fix
    begin
        if rising_edge(clock) then
            if debounce_ctr >= 100000 then -- 100Hz tick at 100MHz
                debounce_ctr <= 0;
                debounce_tick <= '1';
            else
                debounce_ctr <= debounce_ctr + 1;
                debounce_tick <= '0';
            end if;
        end if;
    end process;
    
    target_color <= dataBall when drawRegister(led_cnt) = '1' else dataBack;
    
     --============================================================================
    --  since debouncing is a shift reg last safe position needs to be held for
    --  moving once with a press and hold, otherwise it would cycle super fast to
    --  end
    --============================================================================   
    SINGLE_MOVE_ON_HOLD: process (clock, reset)
    begin
        if (reset = '1') then
            cleanLeftPrev <= '0';
            cleanRightPrev <= '0';
            moveLeft_pulse <= '0';
            moveRight_pulse <= '0';
        elsif rising_edge (clock) then
            cleanLeftPrev <= cleanLeft;
            cleanRightPrev <= cleanRight;
            
            moveLeft_pulse <= cleanLeft and not cleanLeftPrev;
            moveRight_pulse <= cleanRight and not cleanRightPrev;
        end if;
     end process;
     
   

    LIGHTSELECTOR: with activePatternBack select
            dataBack <= X"00FF00" when "000", -- Pure Red
                         X"FF0000" when "001", -- Pure Green
                         X"0000FF" when "010", -- Pure Blue
                         X"FFFF00" when "011", -- Yellow (G+R)
                         X"00FFFF" when "100", -- Magenta (R+B)
                         X"FF00FF" when "101", -- White-ish (Warm)
                         X"80FF00" when "110", -- Orange (Full R, Half G)
                         X"FFFFFF" when "111", -- Full White
                         X"000000" when others;    
    
    LIGHTSELECTORBALL: with activePatternBall select
            dataBall <= X"00FF00" when "000", -- Pure Red
                         X"FF0000" when "001", -- Pure Green
                         X"0000FF" when "010", -- Pure Blue
                         X"FFFF00" when "011", -- Yellow (G+R)
                         X"00FFFF" when "100", -- Magenta (R+B)
                         X"FF00FF" when "101", -- White-ish (Warm)
                         X"80FF00" when "110", -- Orange (Full R, Half G)
                         X"FFFFFF" when "111", -- Full White
                         X"000000" when others;
   
   outputPatternBall <= '0' & activePatternBall_sync;
   outputPatternBack <= '0' & activePatternBack_sync;
   
    
    SEVSEG_DRIVER : SevenSegmentDriver
            port map (
                reset     => Reset,
                clock     => Clock,
                digit3    => outputPatternBall,
                digit2    => "0000",
                digit1    => "0000",
                digit0    => outputPatternBack,
                blank3    => '0',
                blank2    => '1',
                blank1    => '1',
                blank0    => '0',
                sevenSegs => sevenSegs,
                anodes    => anodes
        );
end TransferController_ARCH;