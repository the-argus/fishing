#include "level.h"
#include "constants/physics.h"
#include <ode/ode.h>
#include "Fisherman.h"
#include <raylib.h>
#include <iostream>

static dWorldID world;
static dSpaceID space;
static dGeomID ground;
static dGeomID ground_box;

static void nearCallback(void *unused, dGeomID o1, dGeomID o2) { return; }

namespace level {
void init()
{
	dInitODE();
	world = dWorldCreate();
	space = dHashSpaceCreate(0);
	dWorldSetGravity(world, 0, 0, -GRAVITY);

	// TODO - figure out what the a b c d arguments here are even for
	ground = dCreatePlane(space, 0, 0, 1, 0);
	ground_box = dCreateBox(space, 10, 10, 1);
	dGeomSetPosition(ground_box, -5, -5, 0);

	// rotation of ground box
	dMatrix3 R;
	dRFromAxisAndAngle(R, 0, 1, 1, 0);
	dGeomSetRotation(ground_box, R);

    Fisherman fisherman = Fisherman::getInstance();
	fisherman.setup(world, space);
	fisherman.setPos(12, 22, 16);
	fisherman.getPosV3();
}

// TODO: make sure its not bad to use a variable update amount
void update()
{
	dSpaceCollide(space, 0, nearCallback);
	dWorldStep(world, GetFrameTime());
}

void deinit()
{
	dSpaceDestroy(space);
	dWorldDestroy(world);
	dCloseODE();
}

} // namespace level
