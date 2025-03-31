local tostring = tostring
local io = io
local string = string
local math = math

local wav = {}

---Load a WAV file.
---@param path string
---@return number[]|nil, string|nil
---@nodiscard
function wav.load(path)
	local wav_file, wav_file_err = io.open(path, 'rb')
	if not wav_file then
		return nil, 'Failed to open WAV file: ' .. tostring(wav_file_err)
	end

	---Read the next n bytes as a string.
	---@param bytes integer
	---@param name string
	---@return string|nil, string|nil
	---@nodiscard
	local function read_string(bytes, name)
		local str = wav_file:read(bytes) ---@type string
		if not str or #str ~= bytes then
			return nil, 'Failed to read ' .. tostring(name) .. ', possibly early EOF'
		end
		return str, nil
	end

	---Read the next n bytes as an unsigned integer.
	---@param bytes integer
	---@param name string
	---@return integer|nil, string|nil
	---@nodiscard
	local function read_uint(bytes, name)
		local raw, raw_err = read_string(bytes, name)
		if not raw then return nil, raw_err end
		local uint = 0
		for i = 1, bytes do
			local byte = string.byte(raw, i)
			if not byte then
				return nil, 'Failed to read ' .. tostring(name) .. ' bytes, possibly early EOF'
			end
			uint = uint + byte * math.floor(0x100 ^ (i - 1))
		end
		if uint ~= uint or uint == math.huge or uint == -math.huge then
			return nil, 'Invalid ' .. tostring(name) .. ', got Inf/NaN: ' .. tostring(uint)
		end
		return uint, nil
	end

	---Read the next n bytes as a signed integer.
	---@param bytes integer
	---@param name string
	---@return integer|nil, string|nil
	---@nodiscard
	local function read_int(bytes, name)
		local int, int_err = read_uint(bytes, name)
		if not int then return nil, int_err end
		local max_uint = math.floor(0x100 ^ bytes)
		local max_int = math.floor(max_uint / 2)
		if int >= max_int then
			int = int - max_uint
		end
		if int ~= int or int == math.huge or int == -math.huge then
			return nil, 'Invalid ' .. tostring(name) .. ', got Inf/NaN: ' .. tostring(int)
		end
		return int, nil
	end

	--[[ Read master "RIFF" chunk ]]
	-- Read "FileTypeBlocID"
	local file_type_chunk_id, file_type_chunk_id_err = read_string(4, 'file type chunk ID')
	if not file_type_chunk_id then return nil, file_type_chunk_id_err end
	if file_type_chunk_id ~= 'RIFF' then
		return nil, 'Invalid file type chunk ID, expected "RIFF": ' .. tostring(file_type_chunk_id)
	end
	-- Read "FileSize"
	local file_size, file_size_err = read_uint(4, 'file size')
	if not file_size then return nil, file_size_err end
	if file_size < 36 then
		return nil, 'Invalid file size, expected at least 36 bytes: ' .. tostring(file_size)
	end
	-- Read "FileFormatID"
	local file_format_id, file_format_id_err = read_string(4, 'file format ID')
	if not file_format_id then return nil, file_format_id_err end
	if file_format_id ~= 'WAVE' then
		return nil, 'Invalid file format ID, expected "WAVE": ' .. tostring(file_format_id)
	end

	local format_chunk_position = -1
	local data_chunk_position = -1
	local data_chunk_size = -1
	while wav_file:seek() <= file_size do
		--[[ Read chunk header ]]
		-- Read "BlocID"
		local chunk_id, chunk_id_err = read_string(4, 'chunk ID')
		if not chunk_id then return nil, chunk_id_err end
		-- Read "BlocSize"
		local chunk_size, chunk_size_err = read_uint(4, 'chunk size')
		if not chunk_size then return nil, chunk_size_err end
		local expected_max_chunk_size = (file_size + 8) - wav_file:seek()
		if chunk_size > expected_max_chunk_size then
			return nil,
				'Invalid chunk size, expected at most ' .. tostring(expected_max_chunk_size) .. ': '
				.. tostring(chunk_size)
		end

		-- Save position, if it is a known chunk
		if chunk_id == 'fmt ' then
			if format_chunk_position ~= -1 then
				return nil, 'Duplicate "fmt " chunk found'
			end
			format_chunk_position = wav_file:seek()
		elseif chunk_id == 'data' then
			if data_chunk_position ~= -1 then
				return nil, 'Duplicate "data" chunk found'
			end
			data_chunk_position = wav_file:seek()
			data_chunk_size = chunk_size
		end

		-- Skip to next chunk
		local _, next_chunk_jump_err = wav_file:seek('cur', chunk_size)
		if next_chunk_jump_err then
			return nil, 'Failed to jump to next chunk: ' .. tostring(next_chunk_jump_err)
		end
	end
	if format_chunk_position == -1 then
		return nil, 'Missing "fmt " chunk'
	end
	if data_chunk_position == -1 or data_chunk_size == -1 then
		return nil, 'Missing "data" chunk'
	end

	--[[ Read "fmt " chunk ]]
	local _, format_chunk_jump_err = wav_file:seek('set', format_chunk_position)
	if format_chunk_jump_err then
		return nil, 'Failed to jump to "fmt " chunk: ' .. tostring(format_chunk_jump_err)
	end
	-- Read "AudioFormat"
	local audio_format, audio_format_err = read_uint(2, 'audio format')
	if not audio_format then return nil, audio_format_err end
	if audio_format ~= 1 then
		return nil, 'Invalid audio format, expected 1 (PCM integer): ' .. tostring(audio_format)
	end
	-- Read "NbrChannels"
	local nbr_channels, nbr_channels_err = read_uint(2, 'number of channels')
	if not nbr_channels then return nil, nbr_channels_err end
	if nbr_channels ~= 1 then
		return nil, 'Invalid number of channels, expected 1 (Mono): ' .. tostring(nbr_channels)
	end
	-- Read "Frequency"
	local sample_rate, sample_rate_err = read_uint(4, 'sample rate')
	if not sample_rate then return nil, sample_rate_err end
	if sample_rate ~= 44100 then
		return nil, 'Invalid sample rate, expected 44100 (Hz): ' .. tostring(sample_rate)
	end
	-- Read "BytePerSec"
	local byte_per_sec, byte_per_sec_err = read_uint(4, 'byte per second')
	if not byte_per_sec then return nil, byte_per_sec_err end
	-- Read "BytePerBloc"
	local byte_per_chunk, byte_per_chunk_err = read_uint(2, 'byte per chunk')
	if not byte_per_chunk then return nil, byte_per_chunk_err end
	-- Read "BitsPerSample"
	local bits_per_sample, bits_per_sample_err = read_uint(2, 'bits per sample')
	if not bits_per_sample then return nil, bits_per_sample_err end
	if bits_per_sample ~= 16 then
		return nil, 'Invalid bits per sample, expected 16: ' .. tostring(bits_per_sample)
	end
	-- Remaining checks
	local expected_byte_per_chunk = nbr_channels * bits_per_sample / 8
	if byte_per_chunk ~= expected_byte_per_chunk then
		return nil,
			'Invalid byte per chunk, expected ' .. tostring(expected_byte_per_chunk) .. ': ' .. tostring(byte_per_chunk)
	end
	local expected_byte_per_sec = sample_rate * expected_byte_per_chunk
	if byte_per_sec ~= expected_byte_per_sec then
		return nil,
			'Invalid byte per second, expected ' .. tostring(expected_byte_per_sec) .. ': ' .. tostring(byte_per_sec)
	end

	--[[ Read "data" chunk ]]
	local _, data_chunk_jump_err = wav_file:seek('set', data_chunk_position)
	if data_chunk_jump_err then
		return nil, 'Failed to jump to "data" chunk: ' .. tostring(data_chunk_jump_err)
	end
	local chunk_end = wav_file:seek() + data_chunk_size
	local samples = {} ---@type number[]
	local samples_index = 1
	while wav_file:seek() < chunk_end do
		local integer_sample, sample_err = read_int(2, 'sample')
		if not integer_sample then return nil, sample_err end
		local float_sample = integer_sample / 32768
		samples[samples_index] = float_sample
		samples_index = samples_index + 1
	end
	local expected_samples_length = data_chunk_size / (bits_per_sample / 8)
	if #samples ~= expected_samples_length then
		return nil,
			'Invalid number of samples, expected ' .. tostring(expected_samples_length) .. ': ' .. tostring(#samples)
	end

	wav_file:close()
	return samples, nil
end

return wav
