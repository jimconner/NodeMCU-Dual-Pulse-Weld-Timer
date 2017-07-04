-- Dual pulse battery tab spot welder project

-- Connections:
--   OLED Display attached to SDA->D1,SCL->D2
--   Solid State Relay on D8, with NPN transistor to allow 5V switching across SSR
--   Microswitch on D4 to trigger weld cycle
--   Rotary encoder on CLK->D5, DT->D6, SW->D7
--   NTC Thermistor on A0 for over-temperature detection.

-- Variables 
sda = 1 -- SDA Pin
scl = 2 -- SCL Pin
pulse1 = 0
delay = 0
pulse2 = 0
pos_old = 0
select_line = 0
str1_sep = "*"
str2_sep = ":"
str3_sep = ":"
zap_pin = 4
relay_pin=8
last_zap = 0
debounce_delay = 1000000 -- 1-second re-trigger delay

 -- turn off the SSR at start in case we are recovering from a crash
gpio.mode(zap_pin, gpio.INPUT, gpio.PULLUP)
gpio.mode(relay_pin, gpio.OUTPUT)
gpio.write(relay_pin, gpio.LOW)

adc.force_init_mode(adc.INIT_ADC) -- Set ADC to read from input pin, rather than VDD

function load_config()
  files = file.list()
  if files["pulse1.config"] then
    if file.open("pulse1.config", "r") then
      pulse1 = file.read()
      file.close()
    end
    if file.open("delay.config", "r") then
      delay = file.read()
      file.close()
    end
    if file.open("pulse2.config", "r") then
      pulse2 = file.read()
      file.close()
    end
  end
  str1="Pulse1" .. str1_sep .. " " .. pulse1 .. " ms"
  str2="Delay " .. str2_sep .. " "  .. delay .. " ms"
  str3="Pulse2" .. str3_sep .. " " .. pulse2 .. " ms"
end

function save_config()
  files = file.list()
  if file.open("pulse1.config", "w") then
     file.write(pulse1)
    file.close()
  end
  if file.open("delay.config", "w") then
     file.write(delay)
    file.close()
  end
  if file.open("pulse2.config", "w") then
     file.write(pulse2)
    file.close()
  end
end


rotary.setup(0, 5, 6, 7, 1000, 250)

function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3C
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_8x13B)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
     --disp:setRot180()           -- Rotate Display if needed
end

function top_line(str)
   disp:firstPage()
   repeat
     disp:drawStr(5, 0, str)
   until disp:nextPage() == false
end


function print_OLED()
   disp:firstPage()
   repeat
--     disp:drawFrame(2,2,126,62)
     disp:drawStr(5, 16, str1)
     disp:drawStr(5, 30, str2)
     disp:drawStr(5, 44, str3)

--     disp:drawCircle(18, 47, 14)
   until disp:nextPage() == false
   
end

-- Main Program 
load_config()
init_OLED(sda,scl)
print_OLED() 

gpio.trig(zap_pin, "down", function (level, when)
   local delta = when - last_zap
   if delta < 0 then delta = delta + 2147483647 end;
   if delta > debounce_delay then
    last_zap = when
    if level == 0 then
      -- Keeping the if statements outside the timing loop complicates the code, but gives more accurate timings.
      pulse1us = (pulse1*1000)-750
      pulse2us = (pulse2*1000)-750
      bothus = ((pulse1+pulse2)*1000)-750
      delayus = (delay*1000) 
      if pulse1 == 0 and pulse2 == 0 then -- Do nothing
        top_line("No Zap...")
      elseif adc.read(0) > 804 then -- Over Temperature... around 40C to be on the safe side for now
       top_line("Too Hot: " .. math.floor((adc.read(0)-84)/18) .. "C")      
      elseif pulse2 == 0 then -- Only do pulse1
        top_line("Zap Pulse1...")
        gpio.write(relay_pin, gpio.HIGH)
        tmr.delay(pulse1us)
        gpio.write(relay_pin, gpio.LOW)
      elseif pulse1 == 0 then -- Only do pulse2
        top_line("Zap Pulse2...")
        gpio.write(relay_pin, gpio.HIGH)
        tmr.delay(pulse2us)
        gpio.write(relay_pin, gpio.LOW)
      elseif delay == 0 then -- Add pulse1+pulse2 into single longer pulse
        top_line("Zap Pulse1+2...")
        gpio.write(relay_pin, gpio.HIGH)
        tmr.delay(bothus)
        gpio.write(relay_pin, gpio.LOW)
      else  -- Double-zap cycle - pulse1, delay, pulse2
        top_line("Double Zap...")
        gpio.write(relay_pin, gpio.HIGH)
        tmr.delay(pulse1us)
        gpio.write(relay_pin, gpio.LOW)
        tmr.delay(delayus)
        gpio.write(relay_pin, gpio.HIGH)
        tmr.delay(pulse2us)
        gpio.write(relay_pin, gpio.LOW)
      end
      print_OLED()
    end
  end
end
)

rotary.on(0, rotary.TURN, function (type, pos, when)
  if bit.isclear(pos,1)  then
    if bit.isclear(pos,0) then
      diff = pos - pos_old
      pos_old = pos
      if select_line == 0 then
        pulse1 = pulse1 + diff
        if pulse1 < 0 then 
          pulse1 = 0
        end
        if pulse1 > 1000 then
          pulse1 = 1000
        end
        str1="Pulse1" .. str1_sep .. " " .. pulse1 .. " ms"
        print_OLED()
      end
      if select_line == 1 then
        delay = delay + diff
        if delay < 0 then 
          delay = 0
        end
        if delay > 1000 then
          delay = 1000
        end
        str2="Delay " .. str2_sep .. " " .. delay .. " ms"
        print_OLED()
      end
      if select_line == 2 then
        pulse2 = pulse2 + diff
        if pulse2 < 0 then 
          pulse2 = 0
        end
        if pulse2 > 1000 then
          pulse2 = 1000
        end
        str3="Pulse2" .. str3_sep .. " " .. pulse2 .. " ms"
        print_OLED()
      end
    end
  end
end
)

rotary.on(0, rotary.CLICK, function (type, pos, when)
  if select_line < 2 then
    select_line = select_line+1
  else
    select_line = 0
  end
  if select_line == 0 then
    str1_sep = "*"
  else
    str1_sep = ":"
  end
  if select_line == 1 then
    str2_sep = "*"
  else
    str2_sep = ":"
  end
  if select_line == 2 then
    str3_sep = "*"
  else
    str3_sep = ":"
  end
  str1="Pulse1" .. str1_sep .. " " .. pulse1 .. " ms"
  str2="Delay " .. str2_sep .. " "  .. delay .. " ms"
  str3="Pulse2" .. str3_sep .. " " .. pulse2 .. " ms"
  print_OLED()
end
)


rotary.on(0, rotary.DBLCLICK, function (type, pos, when)
  top_line("Saving...")
  save_config()
  print_OLED()
end
)

rotary.on(0, rotary.LONGPRESS, function (type, pos, when)
  top_line("Loading...")
  load_config()
  select_line=2
  print_OLED()
end
)
