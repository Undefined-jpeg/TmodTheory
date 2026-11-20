--[[
	AssetConfig (ModuleScript, ReplicatedStorage.BaldiShared.AssetConfig)

	PASTE YOUR ASSET IDS HERE — this is the one file you edit to skin the
	whole game with your own images and sounds.

	Every entry left as "" falls back to a built-in placeholder (plain
	colors / engine sounds), so the game always runs. Replace entries one
	at a time as you finish assets.

	An image id looks like:  "rbxassetid://1234567890"
	To get one: Studio -> Asset Manager -> Import your image (Decal),
	right-click it -> Copy Asset ID.

	Sound ids use the same format. Leave "" to keep the built-in sound.
]]

local AssetConfig = {}

-- ========== UI images ==========
AssetConfig.IMAGES = {
	-- full-screen backgrounds
	MENU_BACKGROUND = "", -- main menu (like the original game's title art)
	COUNTDOWN_BACKGROUND = "", -- "Get ready..." screen
	WIN_BACKGROUND = "", -- ESCAPED! screen
	LOSE_BACKGROUND = "", -- CAUGHT! screen
	DETENTION_BACKGROUND = "", -- detention overlay (semi-transparent works best)
	FROST_OVERLAY = "", -- Frosty chill overlay (transparent PNG, icy edges)
	SILVER_OVERLAY = "", -- Silver grab minigame backdrop (semi-transparent PNG)
	GUY_JUMPSCARE = "", -- full-screen flash when Guy's fake notebook reveals him

	-- HUD pieces
	NOTEBOOK_ICON = "", -- little notebook next to the counter (top left)
	NICKEL_ICON = "", -- coin icon (top right)
	ITEM_SLOT = "", -- background of each item square (top right)
	STAMINA_BACK = "", -- stamina bar backplate
	STAMINA_FILL = "", -- stamina bar fill (tinted green/yellow/red by code)

	-- buttons / panels
	PLAY_BUTTON = "", -- the main menu PLAY button
	PANEL = "", -- "HOW TO PLAY" panel background
	VENDING_PANEL = "", -- vending machine popup background

	-- item pictures (shown inside slots and the vending popup)
	ITEMS = {
		BSODA = "",
		ZESTY = "",
		SCISSORS = "",
		ALARM = "",
	},
}

-- ========== sounds ==========
-- Every sound used in the game is listed here.
-- SOUNDS = the live ids read by code (SoundController on the client,
-- SoundLoader on the server). Blank "" = a built-in fallback sound.
AssetConfig.SOUNDS = {
	-- ---- UI / player feedback (client, SoundController) ----
	click = "", -- every button press, menu tab, settings toggle, countdown tick, minigame key presses (blank = built-in click)
	collect = "92310241720920", -- notebook collected, correct minigame step (pitch rises with progress)
	nickel = "81504088112864", -- picking up a nickel / getting nickels in the menu
	buy = "79799813816040", -- shop or vending purchase succeeds; chain broken; gum shaken off
	error = "128439264970971", -- wrong answer, failed purchase, not enough nickels, minigame mistake
	exhausted = "", -- stamina runs out (blank = built-in)
	caught = "121772808146519", -- you got caught (lose screen); also Guy's reveal flash (pitched up)
	detention = "94032705036369", -- detention overlay appears
	frost = "", -- Frosty chills you; also stands in for the gum splat (blank = built-in)
	use = "", -- using an item from your slots (blank = built-in)
	win = "74847848109563", -- ESCAPED! win screen (blank = rising arpeggio jingle)
	grab = "85544033053701", -- Silver grabs you / chain minigame starts
	swept = "117464548961127", -- a sweeper hits you (blank = built-in)

	-- ---- NPC / world sounds (server, SoundLoader) ----
	chase = "127057612541110", -- ChatRevive's repeating slap while he chases
	whistle = "122770925166313", -- LP's alert when he starts chasing
	sweep = "", -- looping noise a sweeper makes mid-sweep (blank = built-in swoosh)
	alarm = "132508047928242", -- placed Alarm Clock ringing loop
	tension = "91401410847788", -- dread loop that swells as ChatRevive closes in
	guy = "140669892908919", -- Guy's reveal scream (fake notebook, or failed-notebook haunt)
	trap = "", -- Sportage setting a trap (blank = built-in)
}

-- Sounds that live as Sound objects in the map/models (not read from here
-- by code yet - listed so you know every asset in the game).
-- Edit the Sound object itself to change these.
AssetConfig.WORLD_SOUNDS = {
	-- BaldiMap.Doors."Blue Door" / "Faculty Door" (DoorMain.Open / .Close)
	classroomDoorOpen = "1807420037", -- a classroom/faculty door opens when you walk through
	classroomDoorClose = "2119898278", -- that door shuts again behind you
	-- BaldiMap.Doors.SwingingDoor, Geometry.ExitDoor, YellowDoors (DoorMain.Open)
	swingingDoor = "1865627915", -- hallway swinging doors and the exit doors pushed open
	-- Workspace.Assets.Door.BlueDoor (Open / Close) - prefab door templates
	blueDoorOpen = "1807420037", -- prefab blue door opening
	blueDoorClose = "2119898278", -- prefab blue door closing
	-- BaldiAssets.Npcs.Guidelines.HumanoidRootPart.ambience (looped, volume 3)
	guidelinesAmbience = "140669892908919", -- constant 3D hum around Guidelines; louder as you get closer
	-- ChaseTension fallback when SOUNDS.tension is blank
	tensionFallback = "rbxasset://sounds/snap.mp3", -- built-in heartbeat thump
}

-- Cosmetic notebook skins (GameConfig COSMETICS, field `sound`).
-- Played when YOU collect a notebook with that skin equipped.
AssetConfig.COSMETIC_SOUNDS = {
	notebook_classic = "", -- none
	notebook_spiral = "", -- none
	notebook_comp = "", -- none (Tablet)
	notebook_graph = "138857089980331", -- Tripple T skin collect sound
	notebook_galaxy = "", -- none (Pixelated)
}

return AssetConfig
