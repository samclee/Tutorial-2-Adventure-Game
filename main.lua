-- libraries
local bump = require 'libs.bump'; -- collision engine
local camera = require 'libs.camera';
world = bump.newWorld();
cam = camera(400, 300);

-- assets
-- visual
local bg = love.graphics.newImage('assets/bg.png');
local playerSprite = love.graphics.newImage('assets/hero.png');
local enemySprite = love.graphics.newImage('assets/enemy.png');

-- audio
local boop = love.audio.newSource('assets/boop.wav', 'static');
boop:setVolume(0.5);
local music = love.audio.newSource('assets/song.mp3');
music:setVolume(0.15);
music:setLooping(true);

-- classes
local player = {x = 340, y = 240, w = playerSprite:getWidth(), h = playerSprite:getHeight(), hp = 3, 
						canGetHit = true,
						target = {x = 360, y = 260}
						 };
local Enemy = require 'classes.Enemy';
local enemies = {};
local numEnemies = 10;
						
function love.load()
	-- audio/visual stuff
	love.graphics.setFont( love.graphics.newFont(30) );
	love.graphics.setPointSize(10);
	music:play();
	
	-- add player
	world:add(player, player.x, player.y, player.w, player.h);
	
	-- add bounds
	world:add({}, 0, -10, 1600, 10); -- top wall
	world:add({}, 0, 1200, 1600, 10); -- btm wall
	world:add({}, -10,0, 10, 1200); -- left wall
	world:add({}, 1600, 0, 10, 1200); -- right wall
	
	-- create and add enemies
	love.math.setRandomSeed(os.time());
	for i=1,numEnemies do
		enemies[i] = Enemy(love.math.random(100, 1500), love.math.random(100, 1100), enemySprite);
		world:add(enemies[i], enemies[i].x, enemies[i].y, enemies[i].w, enemies[i].h);
	end
end

function love.update(dt)
	-- movement
	local dx, dy = 0,0; -- used for direction we'll move
	local spd = 5; -- how much we'll move by
	local range = 80;
	
	if love.keyboard.isDown('up') then dy = -1; end
	if love.keyboard.isDown('down') then dy = 1; end
	if love.keyboard.isDown('left') then dx = -1; end
	if love.keyboard.isDown('right') then dx = 1; end
	
	-- move player
	local actualX, actualY, collisions, len = world:move(player, player.x + dx * spd, player.y + dy * spd);
	player.x, player.y = actualX, actualY;
	
	-- set camera 
	local cameraX, cameraY = 400, 300;
	if player.x + player.w / 2 > 800 then cameraX = 1200 end
	if player.y + player.h / 2 > 600 then cameraY = 900 end
	cam:lookAt(cameraX, cameraY);
	
	-- check collisions, collisions is list of things we hit
	 if len == 0 then
		player.canGetHit = true;
	 end
	 for i=1,len do
		if collisions[i].other.id == 'enemy' and player.canGetHit == true then
			player.hp = player.hp - 1;
			player.canGetHit = false;
		end
	 end
	 
	 -- check if player dead
	if player.hp <= 0 then
		world:move(player, 340, 240);
		player.x, player.y = 320, 240;
		player.hp = 3;
		if #enemies < numEnemies then
			for i=#enemies+1,numEnemies do
				enemies[i] = Enemy(love.math.random(100, 1500), love.math.random(100, 1100), enemySprite);
				world:add(enemies[i], enemies[i].x, enemies[i].y, enemies[i].w, enemies[i].h);
			end -- add enemies back up to numEnemies
		end -- if less than numEnemies enemies
	end -- if player dead
	 
	 -- move attack target
	 if dx ~= 0 or dy ~= 0 then
		player.target.x = player.x + player.w / 2 + dx * range;
		player.target.y = player.y + player.h / 2 + dy * range;
	end
	
	-- clear out any dead enemies
	for i=#enemies, 1, -1 do
		if enemies[i].dead == true then
			world:remove(enemies[i]);
			table.remove(enemies, i);
		end
	end
end

function love.draw()
	cam:attach()
	-- draw bg
	love.graphics.draw(bg,0,0);
	
	-- draw player
	love.graphics.draw(playerSprite, player.x, player.y);
	
	-- draw enemies
	for i=1,#enemies do
		love.graphics.draw(enemySprite, enemies[i].x, enemies[i].y);
	end
	
	-- draw attack target
	love.graphics.points(player.target.x, player.target.y);
	
	cam:detach();
	
	-- draw UI
	love.graphics.setColor(0,0,0);
	love.graphics.print("Player HP: " .. player.hp);
	love.graphics.setColor(255,255,255);
end

function love.keypressed(key)
	if key == 'z' then
		local items, len = world:queryPoint(player.target.x, player.target.y);
		for i=1,len do
			if items[i].id == 'enemy' then
				items[i].hp = items[i].hp - 1;
				if items[i].hp <= 0 then
					items[i].dead = true;
				end -- if enemy has 0 hp
				boop:play();
			end -- if enemy is hit
		end -- for every collision at target
	end -- if z pressed
end