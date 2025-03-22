#ifndef FENSTERAUDIO_MAIN_H
#define FENSTERAUDIO_MAIN_H

#include <lua.h>

#ifdef _WIN32
#define FENSTERAUDIO_EXPORT __declspec(dllexport)
#else
#define FENSTERAUDIO_EXPORT extern
#endif

#ifdef __cplusplus
extern "C" {
#endif

FENSTERAUDIO_EXPORT int luaopen_fensteraudio(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif  // FENSTERAUDIO_MAIN_H
