local assert = assert
local tostring = tostring
local io = io
local string = string
local table = table

local wav = {}

---Load a WAV file.
---TODO: Make Lua 5.1 and 5.2 compatible (no string.unpack)
---@version >5.3
---@param path string
---@return number[]
---@nodiscard
function wav.load(path)
	local audio = assert(io.open(path, 'rb'))

	local master_riff_chunk = audio:read(12)
	assert(master_riff_chunk, 'Invalid master RIFF chunk, possibly early EOF: ' .. tostring(master_riff_chunk))
	---@type string, integer, string
	local file_type_chunk_id, file_size, file_format_id =
		string.unpack('<c4I4c4', master_riff_chunk)
	assert(file_type_chunk_id == 'RIFF', 'Invalid file type chunk ID, expected "RIFF": ' .. tostring(file_type_chunk_id))
	assert(file_format_id == 'WAVE', 'Invalid file format ID, expected "WAVE": ' .. tostring(file_format_id))

	local total_file_size = file_size + 8
	local found_format_chunk = false
	local found_data_chunk = false
	local audio_buffer = {} ---@type number[]
	while audio:seek() < total_file_size do
		local chunk_header = audio:read(8)
		assert(chunk_header, 'Invalid chunk header, possibly early EOF: ' .. tostring(chunk_header))
		---@type string, integer
		local chunk_id, chunk_size = string.unpack('<c4I4', chunk_header)

		if chunk_id == 'fmt ' then
			if found_format_chunk then
				error('Duplicate "fmt " chunk found')
			end
			found_format_chunk = true

			local format_chunk = audio:read(chunk_size)
			assert(format_chunk, 'Invalid format chunk, possibly early EOF: ' .. tostring(format_chunk))
			---@type integer, integer, integer, integer, integer, integer
			local audio_format, nbr_channels, sample_rate, byte_per_sec, byte_per_chunk, bits_per_sample =
				string.unpack('<I2I2I4I4I2I2', format_chunk)
			assert(audio_format == 1, 'Invalid audio format, expected 1 (PCM integer): ' .. tostring(audio_format))
			assert(nbr_channels == 1, 'Invalid number of channels, expected 1 (Mono): ' .. tostring(nbr_channels))
			assert(sample_rate == 44100, 'Invalid sample rate, expected 44100 (Hz): ' .. tostring(sample_rate))
			assert(bits_per_sample == 16, 'Invalid bits per sample, expected 16: ' .. tostring(bits_per_sample))
			local expected_byte_per_chunk = nbr_channels * bits_per_sample / 8
			assert(
				byte_per_chunk == expected_byte_per_chunk,
				'Invalid byte per chunk, expected ' .. tostring(expected_byte_per_chunk) .. ': '
				.. tostring(byte_per_chunk)
			)
			local expected_byte_per_sec = sample_rate * expected_byte_per_chunk
			assert(
				byte_per_sec == expected_byte_per_sec,
				'Invalid byte per second, expected ' .. tostring(expected_byte_per_sec) .. ': '
				.. tostring(byte_per_sec)
			)
		elseif chunk_id == 'data' then
			if found_data_chunk then
				error('Duplicate "data" chunk found')
			end
			found_data_chunk = true

			local chunk_end = audio:seek() + chunk_size
			while audio:seek() < chunk_end do
				local integer_sample_raw = audio:read(2)
				if not integer_sample_raw then
					error('Invalid sample, possibly early EOF: ' .. tostring(integer_sample_raw))
				end
				local integer_sample = string.unpack('<i2', integer_sample_raw) ---@type integer

				local float_sample = integer_sample / 32768
				table.insert(audio_buffer, float_sample)
			end
		else
			audio:seek('cur', chunk_size) -- Skip unknown chunks
		end
	end
	assert(found_format_chunk, 'No "fmt " chunk found')
	assert(found_data_chunk, 'No "data" chunk found')
	assert(
		audio:seek() == total_file_size,
		'Invalid ending position, expected ' .. tostring(total_file_size) .. ': ' .. tostring(audio:seek())
	)

	audio:close()
	return audio_buffer
end

return wav
