#ifndef ABMOOG_PHYSICS
#define ABMOOG_PHYSICS

#include "chipmunk/chipmunk_structs.h"
#include <chipmunk/chipmunk.h>

void physics_init();
void physics_step();
void physics_deinit();

typedef uint8_t BodyHandle;
typedef uint8_t ShapeHandle;

BodyHandle physics_body_new(cpFloat mass, cpFloat moment);
ShapeHandle physics_shape_box_new(BodyHandle body, cpFloat width,
                                  cpFloat height, cpFloat radius);
ShapeHandle physics_shape_static_box_new(cpFloat width, cpFloat height,
                                         cpFloat radius);

cpBody *physics_body_get_raw(BodyHandle handle);
cpShape *physics_shape_get_raw(ShapeHandle handle);

#endif
