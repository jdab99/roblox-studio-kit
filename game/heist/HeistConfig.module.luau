-- Heist settings + level table (ReplicatedStorage.HeistConfig). Add levels here; the server reads Levels[n].
local Config = {}

Config.Sounds = {
	Siren = "rbxassetid://127714289075929",
	Glass = "rbxassetid://128763165071133",
	Bell = "rbxassetid://140176777321375",
	Blaster = "rbxassetid://96160724494413",
	HitMarker = "rbxassetid://125235091454234",
	Reload = "rbxassetid://139798971373512",
}

-- NPC looks (HumanoidDescription catalog ids) + Blocky-style faces (assets/faces/face_ids.json)
Config.GuardLook = {Shirt = 15438617003, Pants = 10915602283, Hat = "104751413508452"}
Config.CopLook = {Shirt = 74614200094847, Pants = 10915602283, Hat = "113169407574034"}
Config.Faces = {
	calm = 82374946742835,     -- sneaky (bored guard)
	suspicious = 123471687600628, -- shocked
	alert = 125197693534047,   -- angry
	knocked = 81022056057673,  -- scared, with the cartoon stars
}

Config.BagSlots = 6            -- how much one player can carry
Config.BaseSpeed = 16
Config.SpeedPerSlot = 1        -- each slot carried slows you down
Config.MinSpeed = 9
Config.SneakMultiplier = 0.55  -- C / Ctrl to sneak
Config.SprintMultiplier = 1.45 -- Shift to sprint

Config.Player = {
	MaxHealth = 100,
	RegenDelay = 4,            -- seconds without being hit before healing starts
	RegenRate = 12,            -- health per second
	DownTime = 1.2,            -- knocked down before being dragged to the cage
}

Config.Blaster = {
	Ammo = 8, ReloadTime = 1.5, FireInterval = 0.17, Range = 260,
	NoiseRadius = 45,          -- firing is LOUD: guards in this radius come to look
	StunTime = 10,             -- knocked out guards/cops get up after this
}

Config.Guard = {
	Range = 34, Fov = 50,          -- degrees each side of forward
	SeeRate = 0.75,                -- suspicion per second at mid range
	SneakRate = 0.45,              -- multiplier when the player is sneaking
	Decay = 0.35,
	CatchDistance = 4,
	WalkSpeed = 7, ChaseSpeed = 14, ReactTime = 0.9, -- freeze with a "!" before chasing
}
Config.Camera = {Range = 46, Cone = 17, SpotTime = 0.5, SweepDegrees = 38, SweepTime = 8}

-- police backup after the alarm: waves get bigger, tougher and better shots
Config.Police = {
	FirstWave = 25,            -- seconds after the alarm
	WaveEvery = 22,
	MaxAlive = 8,
	Wave = function(n)
		return {
			count = math.min(1 + n, 4),
			hits = 1 + math.floor((n - 1) / 2),          -- blaster hits to knock one out
			spread = math.max(2.2, 7.5 - n),              -- degrees of aim wobble
			damage = 5 + n * 2,
			interval = math.max(0.6, 1.6 - n * 0.15),     -- seconds between shots
			react = math.max(0.3, 0.9 - n * 0.1),         -- delay after first seeing you
			speed = 13 + n,
		}
	end,
}

Config.Levels = {
	{
		Name = "Glimmer & Co. Jewelers",
		Quota = 2500,          -- team must bank this much at the van
		TimeLimit = 480,       -- whole heist must finish before sunrise
		LobbyTime = 12,
		WrongCodeLimit = 3,
	},
}

return Config
