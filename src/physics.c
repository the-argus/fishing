#include "physics.h"
#include <chipmunk/chipmunk.h>
#include <chipmunk/chipmunk_structs.h>

#define PHYSICS_BODIES 512
#define PHYSICS_SHAPES 512

static cpSpace *space;

static cpBody body_pool[PHYSICS_BODIES];
static BodyHandle body_next_available_index = 0;

// cpPolyShape is the largest of the shape types. cast them to cpShapes though
static cpPolyShape shape_pool[PHYSICS_SHAPES];
static ShapeHandle shape_next_available_index = 0;

void physics_init() { space = cpSpaceNew(); }

void physics_step() { cpSpaceStep(space, 1.0 / 60); }

void physics_deinit() { cpSpaceDestroy(space); }

BodyHandle physics_body_new(cpFloat mass, cpFloat moment) {
  cpBodyInit(body_pool + body_next_available_index, mass, moment);
  body_next_available_index += 1;
  return body_next_available_index - 1;
}

ShapeHandle physics_shape_box_new(BodyHandle body, cpFloat width,
                                  cpFloat height, cpFloat radius) {
  cpBoxShapeInit(shape_pool + shape_next_available_index, body_pool + body,
                 width, height, radius);
  shape_next_available_index += 1;
  return shape_next_available_index - 1;
}

ShapeHandle physics_shape_static_box_new(cpFloat width, cpFloat height,
                                         cpFloat radius) {
  cpBoxShapeInit(shape_pool + shape_next_available_index,
                 cpSpaceGetStaticBody(space), width, height, radius);
  shape_next_available_index += 1;
  return shape_next_available_index - 1;
}

cpBody *physics_body_get_raw(BodyHandle handle) { return body_pool + handle; }
cpShape *physics_shape_get_raw(ShapeHandle handle) {
  return (cpShape *)(shape_pool + handle);
}
