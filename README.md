# lua-fenster-audio

> The most minimal cross-platform audio playback library - now in Lua!

> [!WARNING]
> WORK IN PROGRESS

## Notes

- I have to convert wav files to the right sample rate (and channel count) before I can play them:
  `mkdir resampled && for f in *.wav; do ffmpeg -i "$f" -ar 44100 -ac 1 "resampled/$f"; done`
