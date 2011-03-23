-- River City Ransom bot. Game plays itself.
-- Author: Billy Wenge-Murphy (http://billy.wenge-murphy.com/)
-- Hack freely.

require("x_billy");

--constants:
SIDE_LEFT = "left";
SIDE_RIGHT = "right";

stats = {}
inventory = {}
floater = {text="", x=0, y=0, active=false, elapsedFrames=0}
player = {}
enemies = {[1]={x=0,y=0}, [2]={x=0,y=0}, [3]={x=0,y=0}};

--Float a money value up the screen when coins are picked up
function float_pickup(amount)
	floater.active = true;
	floater.x = player.screenX - 12;
	floater.y = (240 - player.y) - 40;
	floater.elapsedFrames = 0;
	floater.text = string.format("$%.2f", amount);
end;

--For RCR's insane money system:
--Converts from decimal to hex....and then back to dec.
--Credit: "Lostgallifreyan", http://lua-users.org/lists/lua-l/2004-09/msg00054.html
function DEC_HEX(IN)
	local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
	if (IN == 0) then return 0 end
	while IN>0 do
		I=I+1
		IN,D=math.floor(IN/B),math.mod(IN,B)+1
		OUT=string.sub(K,D,D)..OUT
	end
	return tonumber(OUT)
end


while true do

	------------ READ IN SOME VALUES ----------------------------

	 --relative screen scroll per section (0-255)
	scroll_rel = memory.readbyte(0x00DC);
	seg = memory.readbyte(0x008C);

	--figure out how much money they have
	money = DEC_HEX(memory.readbyte(0x04C7)) / 100 +	--cents
			DEC_HEX(memory.readbyte(0x04C8)) +			--dollars
			DEC_HEX(memory.readbyte(0x04C9)) * 10;		--higher dollars

	paused = memory.readbyte(0x003F);

	player.x = memory.readbyte(0x0083);
	player.y = memory.readbyte(0x009E);
	player.x = player.x + (seg * 256); --true x value
	scroll_abs = scroll_rel + (memory.readbyte(0x003D) * 256);
	player.screenX = player.x - scroll_abs;

	if (memory.readbytesigned(0x006F) == -1) then
		player.facing = SIDE_LEFT;
	else
		player.facing = SIDE_RIGHT;
	end

	--enemy stats
	enemies[1].seg = memory.readbyte(0x008E);
	enemies[2].seg = memory.readbyte(0x008F);
	enemies[3].seg = memory.readbyte(0x0090);

	for i=1, 3 do
		local off = i - 1; --offset
		enemies[i].x = memory.readbyte(0x0084 + off) + (enemies[i].seg * 256);
		enemies[i].y = memory.readbyte(0x00A0 + off);
		enemies[i].P1_dist = math.abs(player.x - enemies[i].x);
		if (enemies[i].x >= player.x) then
			enemies[i].P1_side = SIDE_RIGHT;
		else
			enemies[i].P1_side = SIDE_LEFT;
			enemies[i].P1_dist = enemies[i].P1_dist - 16;
		end
	end

	stats.punch = memory.readbyte(0x049F);
	stats.kick = memory.readbyte(0x04A3);
	stats.weapon = memory.readbyte(0x04A7);
	stats.throwing = memory.readbyte(0x04AB);
	stats.agility = memory.readbyte(0x04AF);
	stats.defense = memory.readbyte(0x04B3);
	stats.strength = memory.readbyte(0x04B7);
	stats.willpower = memory.readbyte(0x04BB);
	stats.stamina = memory.readbyte(0x04BF);
	stats["max power"] = memory.readbyte(0x04C3);

	-- 7 items
	for i = 1, 8 do
		inventory[i] = memory.readbyte(0x064D + i - 1);
	end

	byte_run_jump = memory.readbyte(0x005D);
	player.running = (byte_run_jump == 128 or byte_run_jump == 32);
	player.walking = (memory.readbyte(0x004F) == 0x81);
	player.jumping = (runjump_byte == 64);
	player.leaping = (runjump_byte == 192);

	------------------- DO MOVEMENT LOGIC -------------------------------

	gui.text(0,0, ""); -- force clear of previous text

	local e = 2;
	if (enemies[e].P1_dist > 15) then
		if (enemies[e].P1_side == SIDE_RIGHT) then
			joypad.set(1, {right=true});
		else
			joypad.set(1, {left=true});
		end
	else
		--change player's facing if needed and attack
		if (enemies[e].P1_side == SIDE_RIGHT and player.facing == SIDE_LEFT) then
			joypad.set(1, {right=true});
		end
		if (enemies[e].P1_side == SIDE_LEFT and player.facing == SIDE_RIGHT) then
			joypad.set(1, {left=true});
		end

		joypad.tap("B");
	end

	
	gui.text(20, 120, enemies[1].P1_side .. ", " .. enemies[1].P1_dist);
	gui.text(20, 130, enemies[2].P1_side .. ", " .. enemies[2].P1_dist);
	gui.text(20, 140, enemies[3].P1_side .. ", " .. enemies[3].P1_dist);
	gui.text(20, 160, player.facing);

	emu.frameadvance();
end



