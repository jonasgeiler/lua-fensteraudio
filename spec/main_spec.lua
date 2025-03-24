---@diagnostic disable: discard-returns, missing-parameter, param-type-mismatch, missing-fields, assign-type-mismatch
describe('fensteraudio', function()
	local fensteraudio = require('fensteraudio')

	describe('fensteraudio.samplerate', function()
		it('should be an integer and one of the common sample rates', function()
			local common_sample_rates = {
				[8000] = true,
				[11025] = true,
				[16000] = true,
				[22050] = true,
				[32000] = true,
				[44100] = true,
				[48000] = true,
				[88200] = true,
				[96000] = true,
				[176400] = true,
				[192000] = true,
				[352800] = true,
				[384000] = true,
			}

			assert.is_number(fensteraudio.samplerate)
			assert.is_true(common_sample_rates[fensteraudio.samplerate])
		end)
	end)

	describe('fensteraudio.buffersize', function()
		it('should be an integer and a power of 2', function()
			assert.is_number(fensteraudio.buffersize)
			assert.is_true(fensteraudio.buffersize > 0)
			local x = math.log(fensteraudio.buffersize) / math.log(2)
			assert.are_equal(x, math.floor(x))
		end)
	end)

	describe('fensteraudio.open(...)', function()
		it('should return a audiodevice userdata #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)
			assert.is_userdata(audiodevice)
		end)
	end)

	describe('audiodevice:close(...) / fensteraudio.close(...)', function()
		it('should throw when no arguments were given when not using as method', function()
			assert.has_error(function() fensteraudio.close() end)
		end)

		it('should throw when audiodevice is not a audiodevice userdata when not using as method', function()
			assert.has_error(function() fensteraudio.close(25) end)
			assert.has_error(function() fensteraudio.close(2.5) end)
			assert.has_error(function() fensteraudio.close('ERROR') end)
			assert.has_error(function() fensteraudio.close(true) end)
			assert.has_error(function() fensteraudio.close({}) end)
			assert.has_error(function() fensteraudio.close(function() end) end)
			assert.has_error(function() fensteraudio.close(io.stdout) end)
		end)

		it('should throw when audiodevice is used after closing #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			fensteraudio.close(audiodevice)
			assert.has_error(function() fensteraudio.close(audiodevice) end)
			assert.has_error(function() fensteraudio.available(audiodevice) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }) end)

			local audiodevice2 = fensteraudio.open()
			audiodevice2:close()
			assert.has_error(function() audiodevice2:close() end)
			assert.has_error(function() audiodevice2:available() end)
			assert.has_error(function() audiodevice2:write({ 0 }) end)
		end)
	end)

	describe('audiodevice:available(...) / fensteraudio.available(...)', function()
		it('should throw when no arguments were given when not using as method', function()
			assert.has_error(function() fensteraudio.available() end)
		end)

		it('should throw when audiodevice is not a audiodevice userdata when not using as method', function()
			assert.has_error(function() fensteraudio.available(25) end)
			assert.has_error(function() fensteraudio.available(2.5) end)
			assert.has_error(function() fensteraudio.available('ERROR') end)
			assert.has_error(function() fensteraudio.available(true) end)
			assert.has_error(function() fensteraudio.available({}) end)
			assert.has_error(function() fensteraudio.available(function() end) end)
			assert.has_error(function() fensteraudio.available(io.stdout) end)
		end)

		it('should return an integer #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			assert.is_number(fensteraudio.available(audiodevice))
			assert.is_number(audiodevice:available())
		end)
	end)

	describe('audiodevice:write(...) / fensteraudio.write(...)', function()
		it('should throw when no arguments were given when not using as method', function()
			assert.has_error(function() fensteraudio.write() end)
		end)

		it('should throw when audiodevice is not a audiodevice userdata when not using as method', function()
			assert.has_error(function() fensteraudio.write(25, { 0 }) end)
			assert.has_error(function() fensteraudio.write(2.5, { 0 }) end)
			assert.has_error(function() fensteraudio.write('ERROR', { 0 }) end)
			assert.has_error(function() fensteraudio.write(true, { 0 }) end)
			assert.has_error(function() fensteraudio.write({}, { 0 }) end)
			assert.has_error(function() fensteraudio.write(function() end, { 0 }) end)
			assert.has_error(function() fensteraudio.write(io.stdout, { 0 }) end)
		end)

		it('should throw when samples is not a table #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			assert.has_error(function() fensteraudio.write(audiodevice, 'ERROR') end)
			assert.has_error(function() fensteraudio.write(audiodevice, true) end)
			assert.has_error(function() fensteraudio.write(audiodevice, function() end) end)
			assert.has_error(function() fensteraudio.write(audiodevice, io.stdout) end)
			assert.has_error(function() fensteraudio.write(audiodevice, 0) end)
			assert.has_error(function() fensteraudio.write(audiodevice, 2.5) end)

			assert.has_error(function() audiodevice:write('ERROR') end)
			assert.has_error(function() audiodevice:write(true) end)
			assert.has_error(function() audiodevice:write(function() end) end)
			assert.has_error(function() audiodevice:write(io.stdout) end)
			assert.has_error(function() audiodevice:write(0) end)
			assert.has_error(function() audiodevice:write(2.5) end)
		end)

		it('should throw when one of the samples is not a number #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			assert.has_error(function() fensteraudio.write(audiodevice, { 'ERROR' }) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { true }) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { function() end }) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { io.stdout }) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0, 0, 'zero', 0, 0 }) end)

			assert.has_error(function() audiodevice:write({ 'ERROR' }) end)
			assert.has_error(function() audiodevice:write({ true }) end)
			assert.has_error(function() audiodevice:write({ function() end }) end)
			assert.has_error(function() audiodevice:write({ io.stdout }) end)
			assert.has_error(function() audiodevice:write({ 0, 0, 'zero', 0, 0 }) end)
		end)

		it('should throw when samplesend is not an integer #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, 'ERROR') end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, true) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, {}) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, function() end) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, io.stdout) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, 2.5) end)

			assert.has_error(function() audiodevice:write({ 0 }, 'ERROR') end)
			assert.has_error(function() audiodevice:write({ 0 }, true) end)
			assert.has_error(function() audiodevice:write({ 0 }, {}) end)
			assert.has_error(function() audiodevice:write({ 0 }, function() end) end)
			assert.has_error(function() audiodevice:write({ 0 }, io.stdout) end)
			assert.has_error(function() audiodevice:write({ 0 }, 2.5) end)
		end)

		it('should throw when samples are too many #needsspeaker', function()
			local samples = {}
			for _ = 1, fensteraudio.buffersize + 1 do
				table.insert(samples, 0)
			end

			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			assert.has_error(function() fensteraudio.write(audiodevice, samples) end)

			assert.has_error(function() audiodevice:write(samples) end)
		end)

		it('should throw when one of the samples is out of range #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			assert.has_error(function() fensteraudio.write(audiodevice, { 0, 1.1, 0 }) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0, -1.1, 0 }) end)

			assert.has_error(function() audiodevice:write({ 0, 1.1, 0 }) end)
			assert.has_error(function() audiodevice:write({ 0, -1.1, 0 }) end)
		end)

		it('should throw when samplesend is out of range #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, -1) end)
			assert.has_error(function() fensteraudio.write(audiodevice, { 0 }, 2) end)

			assert.has_error(function() audiodevice:write({ 0 }, -1) end)
			assert.has_error(function() audiodevice:write({ 0 }, 2) end)
		end)

		it('should write samples successfully #needsspeaker', function()
			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			fensteraudio.write(audiodevice, { 0 })
			fensteraudio.write(audiodevice, { 0 }, 1)
			fensteraudio.write(audiodevice, { 0, 0.1, 0, -0.1, 0 }, 3)

			audiodevice:write({ 0 })
			audiodevice:write({ 0 }, 1)
			audiodevice:write({ 0, 0.1, 0, -0.1, 0 }, 3)
		end)

		it('should allow metatable objects for samples #needsspeaker', function()
			local noise_generator = {}
			function noise_generator.new(duration)
				local self = setmetatable({}, noise_generator)
				self.duration = duration
				return self
			end

			function noise_generator:__len()
				return self.duration
			end

			function noise_generator:__index(_)
				return math.random(-1, 1)
			end

			local noise = noise_generator.new(10)

			local audiodevice = fensteraudio.open()
			finally(function() audiodevice:close() end)

			fensteraudio.write(audiodevice, noise)

			audiodevice:write(noise)
		end)
	end)
end)
