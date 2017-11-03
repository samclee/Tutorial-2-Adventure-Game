local Class = require 'libs.class'

local Enemy = Class{}

function Enemy:init(x, y, sprite)
	self.x = x;
	self.y = y;
	self.w = sprite:getWidth();
	self.h = sprite:getHeight();
	self.hp = 3;
	self.id = 'enemy';
	self.dead = false;
end


return Enemy