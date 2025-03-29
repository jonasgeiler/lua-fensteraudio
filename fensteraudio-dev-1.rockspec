rockspec_format = '3.0'
package = 'fensteraudio'
version = 'dev-1' -- this will be replaced by the release workflow
source = {
	url = 'git+https://github.com/jonasgeiler/lua-fensteraudio',
	branch = 'main', -- this will be replaced by the release workflow
}
description = {
	summary = 'The most minimal cross-platform audio playback library - now in Lua!',
	detailed = '' ..
		'A Lua binding for the fenster_audio (https://github.com/zserge/fenster) ' ..
		'C library, providing a minimal cross-platform audio playback library for ' ..
		'playing samples and sounds.',
	license = 'MIT',
	homepage = 'https://github.com/jonasgeiler/lua-fensteraudio',
	issues_url = 'https://github.com/jonasgeiler/lua-fensteraudio/issues',
	maintainer = 'Jonas Geiler',
	labels = {
		-- TODO: Define keywords here and on luarocks.org
		'audio', 'sound', 'alsa'
	},
}
dependencies = {
	'lua >= 5.1, <= 5.4',
}
build_dependencies = {
	platforms = {
		macosx = {
			'luarocks-build-extended',
		},
	},
}
external_dependencies = {
	platforms = {
		linux = {
			ALSA = {
				library = 'asound',
			},
		},
		win32 = {
			WINMM = {
				library = 'winmm',
			},
		},
	},
}
build = {
	type = 'builtin',
	modules = {
		fensteraudio = {
			sources = 'src/main.c',
		},
	},
	platforms = {
		linux = {
			modules = {
				fensteraudio = {
					libraries = {
						'asound',
					},
					incdirs = {
						'$(ALSA_INCDIR)',
					},
					libdirs = {
						'$(ALSA_LIBDIR)',
					},
				},
			},
		},
		win32 = {
			modules = {
				fensteraudio = {
					libraries = {
						'winmm',
					},
					incdirs = {
						'$(WINMM_INCDIR)',
					},
					libdirs = {
						'$(WINMM_LIBDIR)',
					},
				},
			},
		},
		macosx = {
			type = 'extended',
			modules = {
				fensteraudio = {
					variables = {
						LIBFLAG_EXTRAS = {
							'-framework', 'AudioToolbox',
						},
					},
				},
			},
		},
	},
}
test = {
	type = 'busted',
	flags = '--verbose',
}
