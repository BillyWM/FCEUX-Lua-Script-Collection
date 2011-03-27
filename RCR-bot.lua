-- River City Ransom bot. Game plays itself.
-- Author: Billy Wenge-Murphy (http://billy.wenge-murphy.com/)
-- Hack freely.

require("x_billy");

--constants:
SIDE_LEFT = "left";
SIDE_RIGHT = "right";
ATTACK_DIST = 10; 		--how close to come (x) before attacking
GOAL_RUN_THRESH = 50;	--how close to the goal (x) before we switch from run to walk

stats = {}
inventory = {}
floater = {text="", x=0, y=0, active=false, elapsedFrames=0}
player = {}
in_town = false;
enemies = {[1]={x=0,y=0,height=0, same_height=0}, [2]={x=0,y=0,height=0,same_height=0}};
	--where the bot is allowed to walk when navigating the level
	--may contain multiple boxes for each area. Bot will stay inside each
	--as it tries to navigate to its goal
safe = {
	--Highschool
	[0x00] = {
		[1] = {x1 = 0, y1 = 110, x2 = 768, y2 = 50},
		pt_next = { [1] = {x=780, y=80} }
	},
	--Sticksville
	[0x01] = {
		[1] = {x1 = 0, y1 = 109, x2 = 503, y2 = 50},
		pt_next = { [1] = {x=454, y=120} }
	},
	-- Grotto Mall
	[0x02] = {
		[1] = {x1 = 0, y1 = 111, x2 = 503, y2 = 50},
		pt_next = { [1] = {x=524, y=100} }
	},
	-- Sticksville
	[0x03] = {
		[1] = {x1 = 0, y1 = 110, x2 = 768, y2 = 50},
		pt_next = { [1] = {x=780, y=80} }
	},
	-- 0x04: park, skipped
	--Sticksville
	[0x05] = {
		[1] = {x1 = 0, y1 = 112, x2 = 60, y2 = 50},
		pt_next = { [1] = {x=328, y=124} }
	},
	--Waterfront Mall
	[0x06] = {
		[1] = {x1 = 0, y1 = 111, x2 = 768, y2 = 50},
		pt_next = { [1] = {x=780, y=80} }
	},
	--Bridge
	[0x07] = {
		[1] = {x1 = 0, y1 = 96, x2 = 768, y2 = 50},
		pt_next = { [1] = {x=780, y=50} }
	},
	-- Downtown
	[0x09] = {
		[1] = {x1 = 0, y1 = 111, x2 = 503, y2 = 50},
		pt_next = { [1] = {x=414, y=120} }
	}
}

--checks whether a destination point is a 'safe' zone for the target area
function in_bounds(x, y)
	local b = safe[area][1];
	if (x >= b.x1 and x <= b.x2 and y <= b.y1 and y >= b.y2) then
		return true
	else
		return false
	end
end

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

	area = memory.readbyte(0x0042);

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

	if (memory.readbytesigned(0x006F) == -128) then
		player.facing = SIDE_LEFT;
	else
		player.facing = SIDE_RIGHT;
	end

	--whether there are enemies left
	enemies_remain = memory.readbyte(0x0475) ~= 255;
	
	--Hardcoded until better indicator can be found
	in_town = (area == 2 or area == 6);

	--enemy stats
	enemies[1].seg = memory.readbyte(0x008E);
	enemies[2].seg = memory.readbyte(0x008F);

	for i=1, 2 do
		local off = i - 1; --offset
		enemies[i].last_height = enemies[i].height;
		enemies[i].height = memory.readbyte(0x00BB + off);
		--count the frames that a coin has been at the same height, to detect coin that's gone
		if (enemies[i].height == enemies[i].last_height) then
			enemies[i].same_height = enemies[i].same_height + 1
		else
			enemies[i].same_height = 0;
		end

		enemies[i].x = memory.readbyte(0x0085 + off) + (enemies[i].seg * 256);
		enemies[i].y = memory.readbyte(0x00A0 + off);
		--unfortunately, doesn't work perfectly. Enemies that don't spawn will also be '2'
		enemies[i].alive = (memory.readbyte(0x00CD + off) == 2);
		enemies[i].is_coin = (memory.readbyte(0x00CD + off) == 16) and enemies[i].same_height < 10;

		enemies[i].P1_dist = math.abs(player.x - enemies[i].x);
		if (enemies[i].x >= player.x) then
			enemies[i].P1_side = SIDE_RIGHT;
		else
			enemies[i].P1_side = SIDE_LEFT;
			enemies[i].P1_dist = enemies[i].P1_dist - 10;
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

	--target the first coin
	target = 0;
	for i=1,2 do
		if (enemies[i].is_coin) then target = i end
	end

	-- if no coins left then target enemy
	if (target == 0) then
		for i=1,2 do
			if (enemies[i].alive) then target = i end
		end
	end

	--if a target still isn't found, target the first coin

	--do move and attack logic if enemies are still alive,
	--or there are coins to collect
	if (target > 0 and enemies_remain) then

		--remember, up is higher!
		if (enemies[target].y > player.y) then joypad.set(1, {up=true}) end
		if (enemies[target].y < player.y) then joypad.set(1, {down=true}) end

		if (not enemies[target].is_coin) then
			if (enemies[target].P1_dist > ATTACK_DIST) then
				if (enemies[target].P1_side == SIDE_RIGHT) then
					--joypad.set(1, {right=true});
					joypad.tap("right");
				else
					--joypad.set(1, {left=true});
					joypad.tap("left");
				end
			else
				--change player's facing if needed
				if (enemies[target].P1_side == SIDE_RIGHT and player.facing == SIDE_LEFT) then
					joypad.tap("right");
				end
				if (enemies[target].P1_side == SIDE_LEFT and player.facing == SIDE_RIGHT) then
					joypad.tap("left");
				end

				--line up before attacking
				if (math.abs(enemies[target].y - player.y) < 3) then
					joypad.tap("B");
				end
			end
		else
			--coin collecting behavior
			if (enemies[target].x > player.x and in_bounds(player.x + 2, player.y)) then joypad.tap("right") end
			if (enemies[target].x < player.x and in_bounds(player.x - 2, player.y)) then joypad.tap("left") end
			if (enemies[target].y > player.y and in_bounds(player.y - 2, player.y)) then joypad.set(1, {up=true}) end
			if (enemies[target].y < player.y and in_bounds(player.y + 2, player.y)) then joypad.set(1, {down=true}) end
		end

	end

	--If all enemies are dead, navigate to the next area
	if (not enemies_remain or in_town) then
		local bounds = safe[area][1];
		local pt_next = safe[area]['pt_next'][1];
		local lr = false;
		-- After their planned move has been evaluted to be safe, move towards destination

		local goal_dist = math.abs(player.x - pt_next.x);
		--few pixels leeway, otherwise bot gets stuck
		if (goal_dist > 6) then

			--tap other direction to stop running once we're near the target so we don't overshoot
			if (goal_dist < GOAL_RUN_THRESH and player.running) then
				if (player.facing == SIDE_RIGHT) then joypad.tap("left") else joypad.tap("right") end
			end

			--move the right way, walking if we're close
			if (player.x < pt_next.x) then
				--joypad.set(1, {right=true})
				if (goal_dist > GOAL_RUN_THRESH) then joypad.tap("right") else joypad.set(1, {right=true}) end
				lr = true;
			end

			if (player.x > pt_next.x) then
				if (goal_dist > GOAL_RUN_THRESH) then joypad.tap("left") else joypad.set(1, {left=true}) end
				lr = true
			end
		else
		end
		

		--move up only after moving sideways
		if (player.y < pt_next.y and not lr) then joypad.set(1, {up=true}) end
		if (player.y > pt_next.y and not lr) then joypad.set(1, {down=true}) end
	end


	-- DEBUG DISPLAY --
	gui.text(20, 180, "1: " .. tostring(enemies[1].is_coin) .. " " .. tostring(enemies[1].alive));
	gui.text(100, 180, "2: " .. tostring(enemies[2].is_coin) .. " " .. tostring(enemies[2].alive));
	gui.text(0, 200, "Player X, Y: " .. player.x .. " " .. player.y .. " scroll: " .. scroll_abs .. " screenX: " .. player.screenX);
	if bounds then gui.text(0, 190, "Dest: " .. pt_next.x .. " " .. pt_next.y); end
	gui.text(20, 210, player.facing);

	emu.frameadvance();
end



