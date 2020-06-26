-- Autor reseni: SEM DOPLNTE VASE, JMENO, PRIJMENI A LOGIN
-- Author : Maroš Geffert, xgeffe00

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ledc8x8 is
port (
    ROW : out std_logic_vector (0 to 7);
    LED : out std_logic_vector (0 to 7);
    RESET : in std_logic;
    SMCLK : in std_logic
);
end ledc8x8;

architecture main of ledc8x8 is
    signal signal_leds: std_logic_vector(7 downto 0); -- input singaly
    signal signal_rows: std_logic_vector(7 downto 0);
    signal clock_cnt: std_logic_vector(11 downto 0) :=(others => '0');
    signal timer : std_logic_vector(21 downto 0) :=(others => '0');
    signal state : std_logic_vector(1 downto 0) := "00";
    signal clock_enable : std_logic := '0';

begin

    ---------------------------------
    --- Citacka ---------------------
    ---------------------------------
    generator_ce: process(SMCLK, RESET, clock_cnt) 
    begin
        if RESET = '1' then --Reset
            clock_cnt <= "000000000000"; -- pocitadlo clock count nastavim na 0
        elsif rising_edge(SMCLK) then
            clock_cnt <= clock_cnt + 1; -- pocitanie do 3600 
        end if;
    end process generator_ce;

    clock_enable <= '1' when clock_cnt = "111000010000" else '0'; -- nasledne clock enable, ked sa count == 3600
    
    ---------------------------------
    --- State zmien -----------------
    ---------------------------------
    state_zmien: process(SMCLK, RESET, clock_cnt, timer, state)
    begin
        if RESET = '1' then
            timer <= (others => '0');
        elsif rising_edge(SMCLK) then    
            timer <= Timer + 1; -- odpocitavanie pol sekundy a nasledna zmena stavu
            if timer = "1110000100000000000000" then
                if state = "00" or state = "01" then
                    state <= state + 1;
                    timer <= (others => '0');
                end if;
            end if;
        end if;
    end process state_zmien;
    
    ---------------------------------
    --- Rotacia riadkov -------------
    ---------------------------------
    rotacia: process(RESET, SMCLK, clock_enable, signal_rows)
    begin
        if RESET = '1' then 
            signal_rows <= "10000000"; -- na zaciatku je aktivny prvy riadok a postupne prechadza vsetko riadky
        elsif SMCLK'event and SMCLK = '1' and clock_enable = '1' then
            signal_rows <= signal_rows(0) & signal_rows(7 downto 1); --Konkatenacia, posuva sa jednotka 
        end if;
    end process rotacia;
    
    ---------------------------------
    --- Dekoder riadkov -------------
    ---------------------------------
    dekoder: process(signal_rows, state)
    begin
        -- Stav kedy pol sekundy svietia LED
        if state = "00" then
            case signal_rows is
                when "10000000" => signal_leds <= "01110111";
                when "01000000" => signal_leds <= "00100111";
                when "00100000" => signal_leds <= "01010001";
                when "00010000" => signal_leds <= "01110110";
                when "00001000" => signal_leds <= "01110111";
                when "00000100" => signal_leds <= "11110100";
                when "00000010" => signal_leds <= "11110110";
                when "00000001" => signal_leds <= "11110000";
                when others     => signal_leds <= "11111111";
            end case;
            -- Stav kedy pol sekundy LED nesvietia 
        elsif state ="01" then
            case signal_rows is
                when "10000000" => signal_leds <= "11111111";
                when "01000000" => signal_leds <= "11111111";
                when "00100000" => signal_leds <= "11111111";
                when "00010000" => signal_leds <= "11111111";
                when "00001000" => signal_leds <= "11111111";
                when "00000100" => signal_leds <= "11111111";
                when "00000010" => signal_leds <= "11111111";
                when "00000001" => signal_leds <= "11111111";
                when others     => signal_leds <= "11111111";
            end case;
            -- Stav kedy uz svietia LED staticky (v podstate stale) 
        elsif state = "10" or state = "11" then
            case signal_rows is
                when "10000000" => signal_leds <= "01110111";
                when "01000000" => signal_leds <= "00100111";
                when "00100000" => signal_leds <= "01010001";
                when "00010000" => signal_leds <= "01110110";
                when "00001000" => signal_leds <= "01110111";
                when "00000100" => signal_leds <= "11110100";
                when "00000010" => signal_leds <= "11110110";
                when "00000001" => signal_leds <= "11110000";
                when others     => signal_leds <= "11111111";
            end case;
        end if;
        
    end process dekoder;

    ROW <= signal_rows;
    LED <= signal_leds;
end main;




-- ISID: 75579
