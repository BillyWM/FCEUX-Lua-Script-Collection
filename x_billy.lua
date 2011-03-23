-- Personal function library.
-- Author: Billy Wenge-Murphy (http://billy.wenge-murphy.com/)
-- Hack freely. Feel free to give it a more appropriate name or roll it into x_functions


--taps a button
local last = {up=false,down=false,left=false,right=false,A=false,A=false,start=false,select=false}

if not joypad.tap then

	joypad.tap = function(btn)
		if (last[btn] == false) then
			joypad.set(1, {[btn]=true});
		end
		last = joypad.read(1);
	end

end