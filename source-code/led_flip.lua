local me = { 
  flip = function ()
    if gpio.read(4) == gpio.LOW then
      gpio.write(4, gpio.HIGH)
    else
      gpio.write(4, gpio.LOW)
    end
  end
}
return me