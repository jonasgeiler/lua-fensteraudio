#ifndef FENSTER_AUDIO_MAIN_H
#define FENSTER_AUDIO_MAIN_H

#include <lua.h>

#ifdef _WIN32
#define FENSTER_AUDIO_EXPORT __declspec(dllexport)
#else
#define FENSTER_AUDIO_EXPORT extern
#endif

#ifdef __cplusplus
extern "C" {
#endif

FENSTER_AUDIO_EXPORT int luaopen_fenster_audio(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif  // FENSTER_AUDIO_MAIN_H
