# lua-fensteraudio

> The most minimal cross-platform audio playback library - now in Lua!

> [!WARNING]
> WORK IN PROGRESS

## Notes

- I have to convert wav files to the right sample rate (and channel count)
  before I can play them:
  `mkdir resampled && for f in *.wav; do ffmpeg -i "$f" -ar 44100 -ac 1 "resampled/$f"; done`

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
