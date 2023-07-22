#pragma once

#include <raylib.h>

typedef void (*DrawFunction)();
typedef void (*DrawHudFunction)();

namespace render {

void init();

void render(DrawFunction draw, DrawHudFunction drawHud);

void deinit();

Camera3D &getCamera();

} // namespace render
