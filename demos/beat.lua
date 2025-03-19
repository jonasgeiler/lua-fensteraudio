local fenster_audio = require('fenster_audio')

local audioplayer = fenster_audio.open()

local audio = {} ---@type number[]

local u = 0
while true do
	local available_samples = audioplayer.available
	if available_samples > 0 then
		for i = 0, available_samples do
			u = u + 1
			local x = math.floor(u * 80 / 441)
			audio[i] = ((((x >> 10) & 42) * x) & 0xff) / 256
		end
		audioplayer:write(audio, available_samples)
	end
end
