--Various features. Helpful: Auto-savestate in each new room
--Just for fun: Drag and drop
--Author: Billy Wenge-Murphy (http://billy.wenge-murphy.com/)
--Hack freely.

--constants
BYTE_MAPX = 0x001E;
BYTE_MAPY = 0x001D;
BYTE_PLAYERX = 0x0031;
BYTE_PLAYERY = 0x0033;
BYTE_ONFLOOR = 0x004D;
BYTE_ALIVE = 0x0007;

last_mapX = memory.readbyte(BYTE_MAPX);
last_mapY = memory.readbyte(BYTE_MAPY);
anon_state = savestate.create();

while true do

	cur_mapX = memory.readbyte(BYTE_MAPX);
	cur_mapY = memory.readbyte(BYTE_MAPY);
	on_floor = (memory.readbyte(BYTE_ONFLOOR) == 1);
	alive = (memory.readbyte(BYTE_ALIVE) ~= 0);

	if (cur_mapX ~= last_mapX or cur_mapY ~= last_mapY and on_floor) then
		savestate.save(anon_state);
		last_mapX = cur_mapX;
		last_mapY = cur_mapY;
	end

	if (not alive) then savestate.load(anon_state) end

	mouse = input.get();
	if (mouse.leftclick) then
		memory.writebyte(BYTE_PLAYERX, mouse.xmouse);
		memory.writebyte(BYTE_PLAYERX + 1, mouse.xmouse + 13);
		memory.writebyte(BYTE_PLAYERX + 4, mouse.xmouse - 1);

		local ypos = mouse.ymouse - 30;
		memory.writebyte(BYTE_PLAYERY, ypos);
		memory.writebyte(BYTE_PLAYERY + 3, ypos + 29);
		memory.writebyte(BYTE_PLAYERY + 1, ypos + 13);
	end

	emu.frameadvance();
	
end