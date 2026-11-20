local face1 = 'rbxassetid://132164868393243'
local face2 = 'rbxassetid://85825823126181'
local face3= 'rbxassetid://99135612782663'
local particle = script.Parent

while true do
	wait(.5)
	local f = math.random(1,15)
	if f == 1 then
		particle.Texture = face1
	end
	if f == 2 then
		particle.Texture = face2
	end
	if f == 3 then
		particle.Texture = face3
	end
end
