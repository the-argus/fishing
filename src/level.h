#pragma once

#include <ode/ode.h>

namespace level {

void init();

void update();

void draw();

void deinit();

dBodyID createBody();

dGeomID createGeomBox(int lx, int ly, int lz);

bool onGround(dBodyID body);

}; // namespace level
