# lua-fensteraudio

> The most minimal cross-platform audio playback library - now in Lua!

[![LuaRocks](https://img.shields.io/luarocks/v/jonasgeiler/fensteraudio?style=for-the-badge&color=%232c3e67)](https://luarocks.org/modules/jonasgeiler/fensteraudio)
[![Downloads](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fluarocks.org%2Fmodules%2Fjonasgeiler%2Ffensteraudio&query=%2F%2Fdiv%5B%40class%3D%22metadata_columns_inner%22%5D%2Fdiv%5B%40class%3D%22column%22%5D%5Blast()%5D%2Ftext()&style=for-the-badge&label=Downloads&color=099dff&cacheSeconds=86400)](https://luarocks.org/modules/jonasgeiler/fensteraudio)
[![License](https://img.shields.io/github/license/jonasgeiler/lua-fensteraudio?style=for-the-badge&color=%232c3e67)](./LICENSE.md)

> [!WARNING]
> WORK IN PROGRESS

## Installation

From LuaRocks server:

```shell
luarocks install fensteraudio
```

From source:

```shell
git clone https://github.com/jonasgeiler/lua-fensteraudio.git
cd lua-fensteraudio
luarocks make
```

## Simple Example

Here is a simple example that plays random noise:

```lua
-- noise.lua
local fensteraudio = require('fensteraudio')

local audiodevice = fensteraudio.open()
local volume = 0.01 -- BE CAREFUL! High volume can damage your ears or equipment.

local samples = {}
while true do
	local available = audiodevice:available()
	if available > 0 then
		for i = 1, available do
			samples[i] = math.random(-1, 1) * volume
		end

		audiodevice:write(samples, available)
	end
end
```

To run the example:

```
lua noise.lua
```

You should hear a bunch of random noise. If not, carefully turn up the system
volume until you hear something. If you still don't hear anything, try
carefully increasing the `volume` variable in the script.

## Demos

Check out the [./demos](./demos) folder for more elaborate example applications!  
To run a demo use:

```shell
lua demos/<demo>.lua
```

Some of the demos are user-contributed. If you have a demo you'd like to share,
feel free to [create a pull request](https://github.com/jonasgeiler/lua-fensteraudio/new/main/demos)!

## Type Definitions

Work in progress.

## API Documentation

Work in progress.

## Development

I am developing on Linux, so I will only be able to provide a guide for Linux.

### Building

Building the library from the source code requires:

- GCC or similar (f.e. `apt install build-essential`)
- ALSA Development Files (f.e. `apt install libasound2-dev`)
- Lua (f.e. `apt install lua5.4`)
- Lua Development Files (f.e. `apt install liblua5.4-dev`)
- LuaRocks (f.e. `apt install luarocks`)

To build the library from the source code, use:

```shell
luarocks make
```

> [!TIP]
> If you have multiple Lua versions installed on your system, you can specify
> the version to build for with the `--lua-version` LuaRocks flag. For
> example, to build for Lua 5.4, use:
>
> ```shell
> luarocks --lua-version=5.4 make
> ```

### Testing

Before you can run the test you should [build the library](#building) first.

Afterward, to run the tests, use:

```shell
luarocks test
```

> [!TIP]
> If you have multiple Lua versions installed on your system, you can specify
> the version to use for testing with the `--lua-version` LuaRocks flag. For
> example, to test with Lua 5.4, use:
>
> ```shell
> luarocks --lua-version=5.4 test
> ```

### Testing using Docker

If you don't want to install the dependencies above on your system, or want to
test on all Lua versions simultaneously in a clean environment, you can use
Docker with Docker Compose.

Just run the following command to build the Docker images for all Lua
versions and run the tests on each:

```shell
docker compose up --build --force-recreate --abort-on-container-failure
```

## Credits

Many thanks to [Serge Zaitsev (@zserge)](https://github.com/zserge) for creating
the original [fenster_audio](https://github.com/zserge/fenster) library and
making it available to the public. This Lua binding wouldn't have been possible
without their work.

## License

This project is licensed under the [MIT License](./LICENSE.md). Feel free to use
it in your own proprietary or open-source projects. If you have any questions,
please open an issue or discussion!
