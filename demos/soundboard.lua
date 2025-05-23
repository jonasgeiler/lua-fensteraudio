local fensteraudio = require('fensteraudio')

-- Hack to get the current script directory
local dirname = './' .. (debug.getinfo(1, 'S').source:match('^@?(.*[/\\])') or '') ---@type string
-- Add the project root directory to the package path
package.path = dirname .. '../?.lua;' .. package.path

local wav = require('demos.lib.wav')

---@type string[] List of sound files
---
--- NOTE: I have to convert wav files to the right sample rate (and channel count) before I can play them:
--- `mkdir resampled && for f in *.wav; do ffmpeg -i "$f" -ar 44100 -ac 1 "resampled/$f"; done`
local sound_files = {
	'bad_boing.wav',
	'banner.wav',
	'boodoodaloop.wav',
	'brush.wav',
	'camera.wav',
	'cash_register.wav',
	'cast_a_spell_sound.wav',
	'chime.wav',
	'click_error.wav',
	'coins_clinking.wav',
	'coin.wav',
	'complete.wav',
	'crowd_cheer.wav',
	'ding_ding.wav',
	'donk.wav',
	'drumroll.wav',
	'girl_yeaaaaah.wav',
	'hammer.wav',
	'horray_fireworks.wav',
	'icon_incorrect_hit.wav',
	'incorrect.wav',
	'laser_shot2.wav',
	'laser_shot.wav',
	'minty_attack.wav',
	'oh_no.wav',
	'one.wav',
	'plus_sfx.wav',
	'protect_sound.wav',
	'reminder.wav',
	'sheep_baah.wav',
	'short_magic_shot.wav',
	'smack.wav',
	'splash_big.wav',
	'splash_small.wav',
	'ugh.wav',
	'victory_confetti.wav',
	'voltage.wav',
	'water_ripples.wav',
	'wave_alert.wav',
	'wave.wav',
	'whoosh.wav',
	'wildrumble_healing.wav',
	'window_break.wav',
}

---Prints there list of available sound files
local function print_list()
	print('Available sound files:')
	local max_index_length = #tostring(#sound_files)
	for i = 1, #sound_files do
		local index_length = #tostring(i)
		print(string.rep(' ', max_index_length - index_length) .. i .. '. ' .. sound_files[i])
	end
end

---Print the list initially
print_list()

-- Open an audiodevice
local audiodevice = fensteraudio.open()

-- Soundboard interface loop
while true do
	collectgarbage() -- Collect garbage to make sure loaded audio is released

	-- Prompt the user to enter the sound file index
	io.write('> Enter the name or index of the sound file to play (or "h" for help): ')
	io.flush()

	-- Read the sound file index
	local sound_file_index_raw = io.read()

	-- Handle special commands
	if not sound_file_index_raw or sound_file_index_raw == '' then
		-- Do nothing
	elseif sound_file_index_raw == 'q'
		or sound_file_index_raw == 'quit'
		or sound_file_index_raw == 'e'
		or sound_file_index_raw == 'exit' then
		break
	elseif sound_file_index_raw == 'l'
		or sound_file_index_raw == 'ls'
		or sound_file_index_raw == 'list' then
		print_list()
	elseif sound_file_index_raw == 'h'
		or sound_file_index_raw == 'help' then
		print('Enter the name or index of a sound file to play it.')
		print('Enter "l" or "list" to list the available sound files.')
		print('Enter "q" or "quit" to quit.')
	else
		-- Parse the sound file index
		local sound_file_index = tonumber(sound_file_index_raw)
		local found = true
		if not sound_file_index or sound_file_index < 1 or sound_file_index > #sound_files then
			found = false
			for i = 1, #sound_files do
				if sound_files[i] == sound_file_index_raw then
					found = true
					sound_file_index = i
					break
				end
			end
		end
		if not found then
			print('Invalid sound file index or name.')
		else
			-- Get the name of the sound file
			local sound_file = sound_files[sound_file_index]

			-- Load the audio
			local samples, samples_err = wav.load(dirname .. 'assets/' .. sound_file)
			if not samples then
				print('Error loading sound file: ' .. samples_err)
			else
				local samples_length = #samples
				local samples_position = 1

				-- Play the audio
				print('Playing "' .. sound_file .. '"...')
				local curr_samples = {} ---@type number[]
				while samples_position <= samples_length do
					local available = audiodevice:available()
					if available > 0 then
						local curr_samples_length = math.min(available, samples_length - (samples_position - 1))
						if curr_samples_length > 0 then
							for i = 1, curr_samples_length do
								curr_samples[i] = samples[samples_position]
								samples_position = samples_position + 1
							end
							audiodevice:write(curr_samples, curr_samples_length)
						end
					end
				end
			end
		end
	end
end
