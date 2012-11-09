/*
** See Copyright Notice in lua.h
*/

#include <ctype.h>
#include <stdio.h>

#define luac_c
#define LUA_CORE

#include "ldebug.h"
#include "lobject.h"
#include "lopcodes.h"
#include "lundump.h"

extern int hsmethod__call(lua_State *state);
// extern int hsluamodded__debug(lua_State *state);

LUAI_FUNC int lua_neutralize_longjmp(lua_State *state) {
  int result = hsmethod__call(state);
//   hsluamodded__debug(state);
  if (result < 0) {
    return lua_error(state);
  } else {
    return result;
  }
}
