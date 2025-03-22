local fensteraudio = require('fensteraudio')

-- Create a sample rate and duration for the song
local sampleRate = fensteraudio.samplerate
local duration = 4 -- seconds
local numSamples = sampleRate * duration

-- Frequency values for a simple melody (C Major scale notes)
local melody = { 262, 294, 330, 349, 392, 440, 494, 523 } -- C4 to C5
local bpm = 120
local beatDuration = 60 / bpm

-- Generate PCM audio data
local audioData = {}
for i = 0, numSamples - 1 do
	local time = i / sampleRate
	local noteIndex = math.floor(time / beatDuration) % #melody + 1
	local frequency = melody[noteIndex]
	local amplitude = 0.5 -- Volume level
	local sample = amplitude * math.sin(2 * math.pi * frequency * time)
	audioData[i] = sample
end

local audiodevice = fensteraudio.open()

local audio = {} ---@type number[]
local pos = 0
while true do
	local available = audiodevice:available()
	if available > 0 then
		for i = 0, available do
			audio[i] = audioData[pos]

			pos = pos + 1
			if pos == numSamples then
				pos = 0
			end
		end
		audiodevice:write(audio, available)
	end
end
