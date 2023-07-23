#pragma once

#include <raylib.h>

typedef void (*DrawFunction)();

namespace render {

void init();

void render(DrawFunction draw);

void deinit();

Camera3D &getCamera();

} // namespace render
