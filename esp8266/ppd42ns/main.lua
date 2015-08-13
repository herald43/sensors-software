-- esp8266-12
pin_P1=6  -- gpio12
pin_P2=5  -- gpio14

sampletime=30000 -- 30 seconds
filter_time=10000 -- in us
durationP1=0
trigOnP1=0
lastTriggerP1=0
lowpulseoccupancyP1=0
last_P1 = gpio.HIGH

durationP2=0
lastHighP2=0
trigOnP2=0
lowpulseoccupancyP2=0
last_P2 = gpio.HIGH


PIN_GREEN_LED = 2
PIN_RED_LED = 1
gpio.mode(PIN_GREEN_LED, gpio.OUTPUT)
gpio.write(PIN_GREEN_LED, gpio.HIGH)
c = gpio.HIGH


gpio.mode(pin_P1, gpio.INT, gpio.PULLUP)
function pin4change(level)
   if (tmr.now() - lastTriggerP1) > filter_time then	
      if level == gpio.LOW then
	 trigOnP1 = tmr.now()
      end

      if level == gpio.HIGH then
	 durationP1 = tmr.now() - trigOnP1
	 lowpulseoccupancyP1 = lowpulseoccupancyP1 + durationP1
      end
      lastTriggerP1 = tmr.now()
   end
   gpio.trig(pin_P1, "both")
end
gpio.trig(pin_P1, "both", pin4change)


gpio.mode(pin_P2, gpio.INT, gpio.PULLUP)
function pin2change(level)
   if (level == gpio.LOW) and (last_P2 == gpio.HIGH) then
      if (tmr.now() - trigOnP2) > filter_time then
	 last_P2 = gpio.LOW
	 trigOnP2 = tmr.now()
      end
   end
   
   if (level == gpio.HIGH) and (last_P2 == gpio.LOW) then
      if (tmr.now() - lastHighP2) > filter_time then
	 last_P2 = gpio.HIGH
	 lastHighP2 = tmr.now()
	 durationP2 = lastHighP2 - trigOnP2
	 lowpulseoccupancyP2 = lowpulseoccupancyP2 + durationP2
      end
   end
   gpio.trig(pin_P2, "both")
end
gpio.trig(pin_P2, "both", pin2change)


tmr.alarm(0,sampletime,1,function()
    if wifi.sta.getip() == nil then
        status = wifi.sta.status()
        if status == 1 then -- connecting
	   gpio.write(PIN_GREEN_LED, c)
	   if c == gpio.HIGH then
	      c = gpio.LOW
	   else
	      c = gpio.HIGH
	   end
        elseif status <= 4 then
	   gpio.write(PIN_GREEN_LED, gpio.LOW)
        elseif status == 5 then
	   gpio.write(PIN_GREEN_LED, gpio.HIGH)
        end
    else
        print('IP: ',wifi.sta.getip())
	send_to_api(lowpulseoccupancyP1, lowpulseoccupancyP2, sampletime)
    end
    -- even if the data could not be sent.
    -- throw it away and try again after samplingtime
    lowpulseoccupancyP1 = 0
    lowpulseoccupancyP2 = 0
end)

dofile('http.lua')
