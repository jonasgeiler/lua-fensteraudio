local fenster = require('fenster')
local fensteraudio = require('fensteraudio')

local function load_wav(path)
	local audio = assert(io.open(path, "rb"))

	-- Read WAV header
	assert(audio:read(4) == "RIFF", "Invalid WAV file") -- "RIFF"
	audio:read(4) -- File size (skip)
	assert(audio:read(4) == "WAVE", "Invalid WAV format") -- "WAVE"

	-- Search for "fmt " chunk
	while true do
		local chunk_id = audio:read(4)
		local chunk_size = string.unpack("<I4", audio:read(4)) -- Little-endian uint32
		if chunk_id == "fmt " then break end
		audio:seek("cur", chunk_size) -- Skip irrelevant chunks
	end

	local format, num_channels, sample_rate, _, _, bits_per_sample =
		string.unpack("<I2I2I4I4I2I2", audio:read(16))

	assert(format == 1, "Unsupported WAV format (must be PCM)")
	assert(bits_per_sample == 16, "Only 16-bit PCM supported")

	-- Search for "data" chunk
	while true do
		local chunk_id = audio:read(4)
		local chunk_size = string.unpack("<I4", audio:read(4))
		if chunk_id == "data" then break end
		audio:seek("cur", chunk_size) -- Skip irrelevant chunks
	end

	-- Read PCM samples
	local audio_buffer = {}
	while true do
		local lo, hi = audio:read(1), audio:read(1)
		if not lo or not hi then break end

		local sample = string.byte(lo) + (string.byte(hi) * 256)
		if sample >= 32768 then sample = sample - 65536 end
		local float_sample = sample / 32768.0

		table.insert(audio_buffer, float_sample)
	end

	audio:close()
	return audio_buffer, num_channels, sample_rate
end

-- Load the audio
local dirname = './' .. (debug.getinfo(1, 'S').source:match('^@?(.*[/\\])') or '') ---@type string
local audio_path = dirname .. 'assets/chime.wav'
local audio_buffer, num_channels, sample_rate = load_wav(audio_path)
local audio_buffer_len = #audio_buffer

print(audio_buffer, num_channels, sample_rate)

local window = fenster.open(400, 400)
local audiodevice = fensteraudio.open()

local start_playing = false
local playing = false
local audio_buffer_pos = 0
while window:loop() and not window.keys[27] do
	if window.keys[32] then
		start_playing = true
	elseif start_playing then
		start_playing = false
		playing = true
		audio_buffer_pos = 0
		print('Start')
	end

	if playing then
		local available = audiodevice.available
		if available > 0 then
			local curr_audio_buffer = {} ---@type number[]
			local curr_audio_buffer_len = math.min(available, audio_buffer_len - audio_buffer_pos)
			for i = 0, curr_audio_buffer_len do
				curr_audio_buffer[i] = audio_buffer[audio_buffer_pos]

				audio_buffer_pos = audio_buffer_pos + 1
				if audio_buffer_pos == audio_buffer_len then
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

	for x = 0, 400 - 1 do
		for y = 0, 400 - 1 do
			window:set(x, y, fenster.rgb(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
		end
	end
end
