describe('fenster_audio', function()
	local fenster_audio = require('fenster_audio')

	describe('fenster_audio.open(...)', function()
		it('should return a audioplayer userdata #needsspeaker', function()
			local audioplayer = fenster_audio.open()
			finally(function() audioplayer:close() end)
			assert.is_userdata(audioplayer)
		end)
	end)
end)
