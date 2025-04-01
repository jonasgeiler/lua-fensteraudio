local fenster = require('fenster')
local fensteraudio = require('fensteraudio')

-- Hack to get the current script directory
local dirname = './' .. (debug.getinfo(1, 'S').source:match('^@?(.*[/\\])') or '') ---@type string
-- Add the project root directory to the package path
package.path = dirname .. '../?.lua;' .. package.path

local wav = require('demos.lib.wav')

-- Load the audio
local audio_path = dirname .. 'assets/chime.wav'
local audio_buffer = wav.load(audio_path)
local audio_buffer_len = #audio_buffer

local window = fenster.open(400, 400)
local audiodevice = fensteraudio.open()

local start_playing = false
local playing = false
local audio_buffer_pos = 1
local curr_audio_buffer = {} ---@type number[]
while window:loop() and not window.keys[27] do
	if window.keys[32] then
		start_playing = true
	elseif start_playing then
		start_playing = false
		playing = true
		audio_buffer_pos = 1
		print('Start')
	end

	if playing then
		local available = audiodevice:available()
		if available > 0 then
			local curr_audio_buffer_len = math.min(available, audio_buffer_len - (audio_buffer_pos - 1))
			if curr_audio_buffer_len > 0 then
				for i = 1, curr_audio_buffer_len do
					curr_audio_buffer[i] = audio_buffer[audio_buffer_pos]

					audio_buffer_pos = audio_buffer_pos + 1
					if audio_buffer_pos > audio_buffer_len then
						playing = false
						print('Stop')
						break
					end
				end
				if playing then
					audiodevice:write(curr_audio_buffer, curr_audio_buffer_len)
				end
			end
		end
	end

	for x = 0, 400 - 1 do
		for y = 0, 400 - 1 do
			window:set(x, y, fenster.rgb(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
		end
	end
end
