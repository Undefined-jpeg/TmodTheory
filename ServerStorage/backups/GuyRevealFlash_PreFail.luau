--[[
	GuyRevealFlash (ModuleScript, StarterPlayerScripts.BaldiClient.GuyRevealFlash)

	Guy no longer has a body in the world: when you try to collect his fake
	notebook, the server fires GuyReveal at you and he HAUNTS YOUR SCREEN.

	  * StarterGui.Guy (the purple "FATAL ERROR" window) slams in after a
	    flashbang and jumps around the screen to block your view, every
	    MOVE_INTERVAL seconds (mostly springy tweens, sometimes a hard snap).
	  * His face flips between FACE_STARE (Guy1) and FACE_LAUGH (Guy2) every
	    FACE_SWAP seconds - the laugh frame is a little bigger and tilted.
	  * The window background and the text keep spawning short-lived glitch
	    copies of themselves just behind the originals: offset a few pixels,
	    tinted brighter purple / magenta, fading out in a fraction of a second.
	  * A slight purple shade covers the whole screen while he is there.

	After HAUNT_SECONDS he flickers out. A round ending, winning, losing or
	respawning clears him instantly.
]]

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GLITCH_TINTS = {
	Color3.fromRGB(190, 90, 255),
	Color3.fromRGB(230, 70, 220),
	Color3.fromRGB(140, 70, 255),
	Color3.fromRGB(255, 110, 230),
}
local SHADE_COLOR = Color3.fromRGB(110, 40, 160)
local SHADE_TRANSPARENCY = 0.72 -- 1 = invisible; lower = darker purple
local MAX_CLONES = 12 -- glitch copies alive at once

local GuyRevealFlash = {}

function GuyRevealFlash.init(ctx)
	local fx = ctx.controllers.UiFx
	local sounds = ctx.controllers.SoundController
	local cfg = ctx.config.NPC.GUY or {}
	local self = {}

	local HAUNT_SECONDS = cfg.HAUNT_SECONDS or 8
	local FACE_SWAP = cfg.FACE_SWAP or 0.15
	local MOVE_INTERVAL = cfg.MOVE_INTERVAL or 1.5
	local FACE_STARE = cfg.FACE_STARE or "rbxassetid://105812793677447"
	local FACE_LAUGH = cfg.FACE_LAUGH or "rbxassetid://134737818710462"

	local gui = fx.gui("Guy")
	gui.Enabled = false
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 11
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local mainFrame = gui:WaitForChild("MainFrame")
	local background = mainFrame:WaitForChild("WindowBackgroundImage")
	local face = mainFrame:WaitForChild("GuyFace")
	local text = mainFrame:WaitForChild("TextLabel")

	local homePosition = mainFrame.Position
	local homeAnchor = mainFrame.AnchorPoint
	local faceSize = face.Size
	local facePosition = face.Position
	local faceRotation = face.Rotation

	-- copies sit just behind their original (Sibling ZIndex inside MainFrame)
	background.ZIndex = 3
	face.ZIndex = 4
	text.ZIndex = 6
	face.Image = FACE_STARE

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ FACE_STARE, FACE_LAUGH, background.Image })
		end)
	end)

	-- full-screen purple shade, under the window
	local shade = Instance.new("Frame")
	shade.Name = "PurpleShade"
	shade.Size = UDim2.fromScale(1, 1)
	shade.BorderSizePixel = 0
	shade.BackgroundColor3 = SHADE_COLOR
	shade.BackgroundTransparency = 1
	shade.Active = false
	shade.ZIndex = 0
	shade.Parent = gui

	local token = 0
	local loop = nil
	local moveTween = nil
	local shadeTween = nil
	local live = {}
	local liveCount = 0

	local function dropClone(c)
		if live[c] then
			live[c] = nil
			liveCount -= 1
		end
		c:Destroy()
	end

	-- one glitch copy of `source`, offset and tinted, fading out fast
	local function spawnGlitch(source, zIndex, minOff, maxOff, isImage)
		if liveCount >= MAX_CLONES then
			return
		end
		local c = source:Clone()
		c.Name = "GlitchCopy"
		for _, child in c:GetChildren() do
			if child:IsA("UIStroke") or child:IsA("UIGradient") then
				child:Destroy()
			end
		end
		local function off()
			local v = math.random(minOff, maxOff)
			return math.random() < 0.5 and -v or v
		end
		c.Position = source.Position + UDim2.fromOffset(off(), off())
		c.ZIndex = zIndex
		c.BackgroundTransparency = 1
		local tint = GLITCH_TINTS[math.random(1, #GLITCH_TINTS)]
		local start = 0.2 + math.random() * 0.3
		local goal
		if isImage then
			-- slight horizontal stretch so the copy tears sideways
			c.Size = source.Size + UDim2.fromOffset(math.random(-6, 10), 0)
			c.ImageColor3 = tint
			c.ImageTransparency = start
			goal = { ImageTransparency = 1 }
		else
			c.TextColor3 = tint
			c.TextTransparency = start
			c.TextStrokeTransparency = 1
			goal = { TextTransparency = 1 }
		end
		live[c] = true
		liveCount += 1
		c.Parent = mainFrame
		local tween = TweenService:Create(
			c,
			TweenInfo.new(0.15 + math.random() * 0.15, Enum.EasingStyle.Linear),
			goal
		)
		tween.Completed:Connect(function()
			dropClone(c)
		end)
		tween:Play()
	end

	local function glitchBurst(count)
		for _ = 1, count do
			if math.random() < 0.6 then
				spawnGlitch(background, 2, 4, 14, true)
			else
				spawnGlitch(text, 5, 3, 10, false)
			end
		end
	end

	local function setFace(laughing)
		if laughing then
			face.Image = FACE_LAUGH
			face.Size = faceSize + UDim2.fromOffset(16, 16)
			face.Rotation = faceRotation + (math.random() < 0.5 and -5 or 5)
			face.Position = facePosition + UDim2.fromOffset(math.random(-3, 3), math.random(-3, 3))
		else
			face.Image = FACE_STARE
			face.Size = faceSize
			face.Rotation = faceRotation
			face.Position = facePosition
		end
	end

	-- a screen point (scale) well away from where the window is now
	local function randomSpot()
		local cur = mainFrame.Position
		local x, y
		for _ = 1, 6 do
			x = 0.25 + math.random() * 0.5
			y = 0.25 + math.random() * 0.5
			local dx, dy = x - cur.X.Scale, y - cur.Y.Scale
			if dx * dx + dy * dy >= 0.04 then
				break
			end
		end
		return UDim2.fromScale(x, y)
	end

	local function clear()
		token += 1
		if loop then
			loop:Disconnect()
			loop = nil
		end
		if moveTween then
			moveTween:Cancel()
			moveTween = nil
		end
		if shadeTween then
			shadeTween:Cancel()
			shadeTween = nil
		end
		for c in pairs(live) do
			c:Destroy()
		end
		table.clear(live)
		liveCount = 0
		gui.Enabled = false
		mainFrame.Visible = true
		mainFrame.Position = homePosition
		mainFrame.AnchorPoint = homeAnchor
		setFace(false)
		shade.BackgroundTransparency = 1
	end

	local function finish(myToken)
		if myToken ~= token then
			return
		end
		if loop then
			loop:Disconnect()
			loop = nil
		end
		shadeTween = TweenService:Create(shade, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		shadeTween:Play()
		task.spawn(function()
			-- flicker out (odd count -> ends hidden)
			for _ = 1, 7 do
				if myToken ~= token then
					return
				end
				mainFrame.Visible = not mainFrame.Visible
				task.wait(0.06)
			end
			if myToken == token then
				clear()
			end
		end)
	end

	local function haunt()
		clear()
		local myToken = token
		local startedAt = os.clock()
		local nextGlitch = startedAt
		local nextFace = startedAt + FACE_SWAP
		local nextMove = startedAt + MOVE_INTERVAL
		local kickUntil = 0
		local laughing = false

		mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		mainFrame.Position = randomSpot()
		setFace(false)
		fx.flashbang()
		sounds.play("caught", 1.4)
		gui.Enabled = true

		loop = RunService.RenderStepped:Connect(function()
			local now = os.clock()
			local t = now - startedAt

			-- purple shade: fade in, gentle pulse, darker kick on snaps
			local fadeIn = math.min(1, t / 0.3)
			local alpha = 1 - (1 - SHADE_TRANSPARENCY) * fadeIn
			alpha += math.sin(t * 6) * 0.04 * fadeIn
			if now < kickUntil then
				alpha -= 0.15 * ((kickUntil - now) / 0.15)
			end
			shade.BackgroundTransparency = math.clamp(alpha, 0, 1)

			if now >= nextGlitch then
				nextGlitch = now + 0.06 + math.random() * 0.06
				glitchBurst(math.random(1, 3))
			end

			if now >= nextFace then
				nextFace = now + FACE_SWAP
				laughing = not laughing
				setFace(laughing)
			end

			if now >= nextMove then
				nextMove = now + MOVE_INTERVAL + math.random() * 0.5
				if moveTween then
					moveTween:Cancel()
					moveTween = nil
				end
				local spot = randomSpot()
				if math.random() < 0.7 then
					local style = math.random() < 0.5 and Enum.EasingStyle.Back or Enum.EasingStyle.Quint
					moveTween = TweenService:Create(
						mainFrame,
						TweenInfo.new(0.35, style, Enum.EasingDirection.Out),
						{ Position = spot }
					)
					moveTween:Play()
				else
					mainFrame.Position = spot
					kickUntil = now + 0.15
					glitchBurst(3)
				end
			end
		end)

		task.delay(HAUNT_SECONDS, finish, myToken)
	end

	ctx.remotes.GuyReveal.OnClientEvent:Connect(haunt)

	for _, name in ipairs({ "RoundEnded", "PlayerLost", "PlayerWon" }) do
		local remote = ctx.remotes[name]
		if remote then
			remote.OnClientEvent:Connect(clear)
		end
	end
	ctx.player.CharacterAdded:Connect(clear)

	self.clear = clear
	return self
end

return GuyRevealFlash
