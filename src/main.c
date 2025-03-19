#include "../include/main.h"

#include <errno.h>
#include <lauxlib.h>
#include <lua.h>
#include <stdint.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "../lib/compat-5.3/compat-5.3.h"
#include "../lib/fenster_audio/fenster_audio.h"

// Macro to convert a macro value to string.
// Use like `"prefix" STRING(DEF) "suffix"`.
#define RAW_STRING(tokens) #tokens
#define STRING(tokens) RAW_STRING(tokens)

// Macros that ensure the same integer argument behavior in Lua 5.1/5.2
// and 5.3/5.4. In Lua 5.1/5.2 luaL_checkinteger/luaL_optinteger normally floor
// decimal numbers, while in Lua 5.3/5.4 they throw an error. These macros make
// sure to always throw an error if the number has a decimal part.
#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM <= 502
#define luaL_checkinteger(L, arg)                                              \
  (luaL_argcheck(L,                                                            \
                 floorl(luaL_checknumber(L, arg)) == luaL_checknumber(L, arg), \
                 arg, "number has no integer representation"),                 \
   luaL_checkinteger(L, arg))
#define luaL_optinteger(L, arg, def) \
  (lua_isnoneornil(L, arg) ? def : luaL_checkinteger(L, arg))
#endif

/** Name of the audioplayer userdata and metatable */
static const char *AUDIOPLAYER_METATABLE = "audioplayer*";

/** Userdata representing the fenster_audio audioplayer */
typedef struct audioplayer {
  // "private" members
  struct fenster_audio *p_fenster_audio;
} audioplayer;

/*
// Utility function to dump the Lua stack for debugging
static void _dumpstack(lua_State *L) {
  int top = lua_gettop(L);
  for (int i = 1; i <= top; i++) {
    printf("%d\t%s\t", i, luaL_typename(L, i));
    switch (lua_type(L, i)) {
      case LUA_TNUMBER:printf("%g\n", lua_tonumber(L, i));
        break;
      case LUA_TSTRING:printf("%s\n", lua_tostring(L, i));
        break;
      case LUA_TBOOLEAN:printf("%s\n", lua_toboolean(L, i) ? "true" : "false");
        break;
      case LUA_TNIL:printf("%s\n", "nil");
        break;
      default:printf("%p\n", lua_topointer(L, i));
        break;
    }
  }
}
 */

/**
 * Opens an audio player.
 * Returns an userdata representing the audio player with all the methods and
 * properties we defined on the metatable.
 * @param L Lua state
 * @return Number of return values on the Lua stack
 */
static int lfenster_audio_open(lua_State *L) {
  // use a temporary fenster_audio struct to copy into the "real" one later
  struct fenster_audio temp_fenster_audio = {0};

  // allocate memory for the "real" fenster_audio struct
  struct fenster_audio *p_fenster_audio = malloc(sizeof(struct fenster_audio));
  if (p_fenster_audio == NULL) {
    const int error = errno;
    return luaL_error(L, "failed to allocate memory of size %d for audioplayer (%d)",
                      sizeof(struct fenster_audio), error);
  }

  // copy temporary fenster_audio struct into the "real" one
  // TODO: i had to do this in lua-fenster because of const width/height,
  //       do I still need this?
  memcpy(p_fenster_audio, &temp_fenster_audio, sizeof(struct fenster_audio));

  // open window and check success
  const int result = fenster_audio_open(p_fenster_audio);
  if (result != 0) {
    free(p_fenster_audio);
    p_fenster_audio = NULL;
    return luaL_error(L, "failed to open audioplayer (%d)", result);
  }

  // create the window userdata and initialize it
  audioplayer *p_audioplayer = lua_newuserdata(L, sizeof(audioplayer));
  p_audioplayer->p_fenster_audio = p_fenster_audio;
  luaL_setmetatable(L, AUDIOPLAYER_METATABLE);
  return 1;
}

/** Macro to get the audioplayer userdata from the Lua stack */
#define check_audioplayer(L) (luaL_checkudata(L, 1, AUDIOPLAYER_METATABLE))

/** Macro to check if the audioplayer is closed */
#define is_audioplayer_closed(p_audioplayer) ((p_audioplayer)->p_fenster_audio == NULL)

/**
 * Utility function to get the audioplayer userdata from the Lua stack and check
 * if the audioplayer is open.
 * @param L Lua state
 * @return The audioplayer userdata
 */
static audioplayer *check_open_audioplayer(lua_State *L) {
  audioplayer *p_audioplayer = check_audioplayer(L);
  if (is_audioplayer_closed(p_audioplayer)) {
    luaL_error(L, "attempt to use a closed audioplayer");
  }
  return p_audioplayer;
}

/**
 * Close the audioplayer. Does nothing if the audioplayer is already closed.
 * The __gc and __close meta methods also call this function, so the user
 * likely won't need to call this function manually.
 * @param L Lua state
 * @return Number of return values on the Lua stack
 */
static int audioplayer_close(lua_State *L) {
  audioplayer *p_audioplayer = check_open_audioplayer(L);

  // close and free audioplayer
  fenster_audio_close(p_audioplayer->p_fenster_audio);
  free(p_audioplayer->p_fenster_audio);
  p_audioplayer->p_fenster_audio = NULL;

  return 0;
}

/**
 * Utility function to get the number of samples from the Lua stack and check if
 * it's within bounds.
 * @param L Lua state
 * @return The number of samples
 */
static lua_Integer check_num_samples(lua_State *L) {
  const lua_Integer num_samples = luaL_checkinteger(L, 3);
  luaL_argcheck(L, num_samples >= 0 && num_samples < FENSTER_AUDIO_BUFSZ, 3,
                "sample number must be in range 0-" STRING(FENSTER_AUDIO_BUFSZ));
  return num_samples;
}

/**
 * TODO
 * @param L Lua state
 * @return Number of return values on the Lua stack
 */
static int audioplayer_write(lua_State *L) {
  audioplayer *p_audioplayer = check_open_audioplayer(L);
  const lua_Integer num_samples = check_num_samples(L);

  // Get array of numbers from argument 2
  luaL_checktype(L, 2, LUA_TTABLE);
  const lua_Unsigned buf_len = lua_rawlen(L, 2);
  float *buf = malloc(buf_len * sizeof(float));
  if (buf == NULL) {
      return luaL_error(L, "failed to allocate memory of size %d for audio buffer",
                      buf_len * sizeof(float));
  }
  for (lua_Unsigned i = 0; i < buf_len; i++) {
      lua_pushinteger(L, i + 1);
      lua_gettable(L, 2);
      buf[i] = (float) luaL_checknumber(L, -1);
      lua_pop(L, 1);
  }

  fenster_audio_write(p_audioplayer->p_fenster_audio, buf, num_samples);

  return 0;
}

/**
 * Index function for the audioplayer userdata. Checks if the key exists in the
 * methods metatable and returns the method if it does. Otherwise, checks for
 * properties and returns the property value if it exists.
 * @param L Lua state
 * @return Number of return values on the Lua stack
 */
static int audioplayer_index(lua_State *L) {
  audioplayer *p_audioplayer = check_open_audioplayer(L);
  const char *key = luaL_checkstring(L, 2);

  // check if the key exists in the methods metatable
  luaL_getmetatable(L, AUDIOPLAYER_METATABLE);
  lua_pushvalue(L, 2);
  lua_rawget(L, -2);
  if (lua_isnil(L, -1)) {
    // key not found in the methods metatable, check for properties
    if (strcmp(key, "available") == 0) {
      // retrieve the available space in the audio buffer
      lua_pushinteger(L, fenster_audio_available(p_audioplayer->p_fenster_audio));
    } else {
      // no matching key is found, return nil
      lua_pushnil(L);
    }
  }
  return 1;  // return either the method or the property value
}

/**
 * Close the window when the audioplayer userdata is garbage collected.
 * Just calls the close method but ignores if the audioplayer is already closed.
 * @param L Lua state
 * @return Number of return values on the Lua stack
 */
static int audioplayer_gc(lua_State *L) {
  audioplayer *p_audioplayer = check_audioplayer(L);

  // ignore if the audioplayer is already closed
  if (!is_audioplayer_closed(p_audioplayer)) {
    audioplayer_close(L);
  }

  return 0;
}

/**
 * Returns a string representation of the audioplayer userdata.
 * @param L Lua state
 * @return Number of return values on the Lua stack
 */
static int audioplayer_tostring(lua_State *L) {
  audioplayer *p_audioplayer = check_audioplayer(L);

  if (is_audioplayer_closed(p_audioplayer)) {
    lua_pushliteral(L, "audioplayer (closed)");
  } else {
    lua_pushfstring(L, "audioplayer (%p)", p_audioplayer);
  }
  return 1;
}

/** Functions for the fenster_audio Lua module */
static const struct luaL_Reg lfenster_audio_functions[] = {
    {"open", lfenster_audio_open},

    // methods can also be used as functions with the userdata as first argument
    {"close", audioplayer_close},
    {"write", audioplayer_write},

    {NULL, NULL}};

/** Methods for the audioplayer userdata */
static const struct luaL_Reg audioplayer_methods[] = {
    {"close", audioplayer_close},
    {"write", audioplayer_write},

    // metamethods
    {"__index", audioplayer_index},
    {"__gc", audioplayer_gc},
#if LUA_VERSION_NUM >= 504
    {"__close", audioplayer_gc},
#endif
    {"__tostring", audioplayer_tostring},

    {NULL, NULL}};

/**
 * Entry point for the fenster_audio Lua module.
 * @param L Lua state
 * @return Number of return values on the Lua stack
 */
FENSTER_AUDIO_EXPORT int luaopen_fenster_audio(lua_State *L) {
  // create the audioplayer metatable
  const int result = luaL_newmetatable(L, AUDIOPLAYER_METATABLE);
  if (result == 0) {
    return luaL_error(L, "audioplayer metatable already exists (%s)",
                      AUDIOPLAYER_METATABLE);
  }
  luaL_setfuncs(L, audioplayer_methods, 0);

  // create and return the fenster_audio Lua module
  luaL_newlib(L, lfenster_audio_functions);
  lua_pushinteger(L, FENSTER_SAMPLE_RATE);
  lua_setfield(L, -2, "samplerate");
  lua_pushinteger(L, FENSTER_AUDIO_BUFSZ);
  lua_setfield(L, -2, "buffersize");
  return 1;
}
