-- Displays some info in River City Ransom

--Item names for belongings (inventory) and shop item identification.
--Luckily it's an unbroken list starting at 0x00 so numerical indexes are omitted
--List from: http://shrines.rpgclassics.com/nes/rcr/hacking.shtml
item_names = {
	"Nothing", "Donut", "Muffin", "Bagel", "Honey Bun", "Croissant", "Sugar", "Toll House",
	"Maple Pecan", "Oatmeal", "Brownie", "Mint Gum", "Lolly Pop", "Jaw Breaker", "Rock Candy",
	"Fudge Bar", "Salad Paris", "Onion Soup", "Cornish Hen", "Veal Walle", "Vita-mints", "Digestol",
	"Recharge!", "Karma Jolt", "Omni Elixir", "Date Saver", "Love Potion", "Antidote 12", "R & B",
	"Rock", "Pop", "Soul", "Classical", "Sneakers", "Boat Shoes", "Loafers", "Army Boots", "Texas Boots",
	"Slippers", "Thongs", "Sandals", "Mod Boots", "Insoles", "Maze Craze", "Decathlete", "Hyper Ball",
	"Techno Belt","Teddy Bear","Stone Hands", "Dragon Feet", "Grand Slam", "Acro Circus", "Javelin Man",
	"Fatal Steps", "Scandal Rag", "Comic Times", "Mystic Seer", "Nuclear Spy", "Indian Lore", "Excalibur",
	"Zeus' Wand", "Rodan Wing", "Gold Medal", "Isis Scroll", "Sirloin", "Rib-eye", "T-bone", "Lamb Leg",
	"Merv Burger", "Cheese Merv", "Fish Merv", "Mondo Merv", "Milk", "Iced Tea", "Soda", "Merv Malt",
	"Merv Fries", "Merv Rings", "Apple Pie", "Spicy Chili", "Smile", "Chickwich", "Dark Meat", "White Meat",
	"Combination", "Lemonade", "Gravy","Biscuits", "Corn Cobber", "Cole Slaw", "Coffee", "Tea", "Hot Cocoa",
	"Pancakes", "Waffles", "Ice Cream", "Roman Shake", "Cola Float", "Nero Pizza", "Lasagna", "Fresh Juice",
	"Lemon Tea", "Herbal Tea", "Carrot Cake", "Pound Cake", "Egg", "Octopus", "Squid", "Conger Eel", "Prawn",
	"Salmon", "Ark Shell", "Sea Urchin", "Halibut", "Swordfish", "Salad Roll", "Tuna Roll", "Shrimp Roll",
	"Mixed Roll", "Egg Roll", "Fried Rice", "Garlic Pork", "Pepper Beef", "Chow Mein", "Sauna",
	"No Thanks", "Nothing", "Main Menu"
}

--Duplicate all the elements adding a # in front, meaning "equipped"
num = #item_names;
for i = 1, num do
	local t = item_names[i];
	item_names[i + 0x80] = "#" .. t;
end

stats = {}
inventory = {}
floater = {text="", x=0, y=0, active=false, elapsedFrames=0}

--Float a money value up the screen when coins are picked up
function float_pickup(amount)
	floater.active = true;
	floater.x = 150;
	floater.y = 100;
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

	--make player a hamburger in shops
	--memory.writebyte(0x00CB, 0x23);

	------------ READ IN SOME VALUES ----------------------------

	--figure out how much money they have
	money = DEC_HEX(memory.readbyte(0x04C7)) / 100 + 	--cents to decimal
			DEC_HEX(memory.readbyte(0x04C8)) +			--dollars
			DEC_HEX(memory.readbyte(0x04C9)) * 10;		--higher dollars

	if (money_last == nil) then money_last = money end; --give money_last a value the first time
	if (money > money_last) then
		float_pickup(money - money_last);
	end

	paused = memory.readbyte(0x003F);

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

	runjump_byte = memory.readbyte(0x005D);
	is_running = (runjump_byte == 128 or runjump_byte == 32);
	is_walking = (memory.readbyte(0x004F) == 0x81);
	is_jumping = (runjump_byte == 64);
	is_leaping = (runjump_byte == 192);

	------------------- DO DISPLAY OF VALUES -------------------------------

	gui.text(0,0, ""); -- force clear of previous text
	if (is_running) then gui.text(5,190,"running") end
	if (is_walking) then gui.text(30, 190, "walking") end
	if (is_jumping) then gui.text(60, 190, "jumping") end
	if (is_leaping) then gui.text(60, 190, "leaping") end

	--this value is too small. Some screens > 256px. Must be other values involved
	local px = memory.readbyte(0x0083);
	local py = memory.readbyte(0x009E);
	px = px + memory.readbyte(0x008C) * 256;
	gui.text(120, 180, "Player X, Y: " .. px .. " " .. py);

	if (floater.active) then
		floater.y = floater.y - 0.7;
		floater.elapsedFrames = floater.elapsedFrames + 1;
		gui.text(floater.x, floater.y, floater.text);
		if (floater.elapsedFrames > 150) then floater.active = false end
	end

	--Displays character stats when game is paused.
	--For convenience, goes away as soon as pause menu starts sliding out (64)
	--Since this depends on menu values, hitting select can keep it on screen
	if (paused ~= 0 and paused ~= 64) then

		gui.drawbox(10, 32, 70, 64, "#000066");
		gui.text(10,32, "Punch: " .. stats.punch);
		gui.text(10,40, "Kick: " .. stats.kick);
		gui.text(10,48,"Weapon: " .. stats.weapon);
		gui.text(10,56,"Throwing: " .. stats.throwing);
		gui.text(10,64,"Agility: " .. stats.agility);
		gui.text(10,72,"Defense: " .. stats.defense);
		gui.text(10,80,"Strength: " .. stats.strength);
		gui.text(10,88,"Willpower: " .. stats.willpower);
		gui.text(10,96,"Stamina: " .. stats.stamina);
		gui.text(10,104,"Max power: " .. stats['max power']);

		for i,v in ipairs(inventory) do
			gui.text(100, 24 + i * 8, item_names[inventory[i] + 1]);
		end

		--Shorter version for stats, but unsorted:
		--[[
		local text_y = 32;
		for k,v in pairs(stats) do
			gui.text(10, text_y, k .. ": " .. v);
			text_y = text_y + 8;
		end
		]]

	end

	money_last = money;

	emu.frameadvance();
end



