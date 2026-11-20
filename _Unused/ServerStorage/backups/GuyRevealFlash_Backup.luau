--[[
	GuyRevealFlash (ModuleScript, StarterPlayerScripts.BaldiClient.GuyRevealFlash)

	The jumpscare when you try to collect Guy's fake notebook. The server fires
	GuyReveal at the victim (and freezes them for STUN_ON_REVEAL seconds). A
	flashbang hits, StarterGui.GuyRevealGui (its Flash canvas) slams in, then
	fades out over the freeze.
]]

local GuyRevealFlash = {}

function GuyRevealFlash.init(ctx)
	local fx = ctx.controllers.UiFx
	local sounds = ctx.controllers.SoundController
	local cfg = ctx.config.NPC.GUY or {}
	local self = {}

	local gui = fx.gui("GuyRevealGui")
	gui.Enabled = false
	local canvas = gui:WaitForChild("Flash")
	local title = canvas:WaitForChild("TitleLabel")
	local titleRotation = title.Rotation

	local token = 0
	ctx.remotes.GuyReveal.OnClientEvent:Connect(function()
		token += 1
		local myToken = token
		fx.flashbang()
		canvas.GroupTransparency = 0
		title.Rotation = titleRotation + math.random(-6, 6)
		gui.Enabled = true
		sounds.play("caught", 1.4)
		task.delay(0.35, function()
			if myToken ~= token then
				return
			end
			local fade = math.max(0.4, (cfg.STUN_ON_REVEAL or 3) - 0.35)
			fx.tween(canvas, fade, { GroupTransparency = 1 }).Completed:Connect(function()
				if myToken == token then
					gui.Enabled = false
				end
			end)
		end)
	end)

	return self
end

return GuyRevealFlash
