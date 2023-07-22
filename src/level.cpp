#include "level.h"
#include "constants/physics.h"
#include "Fisherman.h"
#include "PlaneSet.h"
#include <ode/ode.h>
#include <raylib.h>
#include <array>
#include <optional>

static dWorldID world;
static dSpaceID space;
static std::optional<PlaneSet> planes = std::nullopt;

static constexpr std::array walls = {
	// ground
	PlaneSet::PlaneOptions{
		.position = {.x = 0, .y = 0, .z = 0},
		.scale = {.x = 10, .y = 0.1, .z = 10},
		.eulerRotation = PlaneSet::flatPlaneRotation,
	},
	PlaneSet::PlaneOptions{
		.position = {.x = 10, .y = 5, .z = 0},
		.scale = {.x = 0.1, .y = 10, .z = 10},
		.eulerRotation = {},
	},
	PlaneSet::PlaneOptions{
		.position = {.x = 0, .y = 5, .z = 10},
		.scale = {.x = 10, .y = 10, .z = 0.1},
		.eulerRotation = {.x = 0, .y = DEG2RAD * 90, .z = 0},
	},
	PlaneSet::PlaneOptions{
		.position = {.x = -10, .y = 5, .z = 0},
		.scale = {.x = 0.1, .y = 10, .z = 10},
		.eulerRotation = {},
	},
	PlaneSet::PlaneOptions{
		.position = {.x = 0, .y = 5, .z = -10},
		.scale = {.x = 10, .y = 10, .z = 0.1},
		.eulerRotation = {.x = 0, .y = DEG2RAD * 90, .z = 0},
	},
};

static void nearCallback(void *unused, dGeomID o1, dGeomID o2) { return; }

namespace level {

dBodyID createBody() { return dBodyCreate(world); }

dGeomID createGeomBox(int lx, int ly, int lz)
{
	return dCreateBox(space, lx, ly, lz);
}

void init()
{
	dInitODE();
	world = dWorldCreate();
	space = dHashSpaceCreate(0);
	dWorldSetGravity(world, 0, GRAVITY, 0);

	planes.emplace();

	for (const auto &wall : walls) {
		planes->createPlane(space, wall);
	}

	// create fisherman
	Fisherman fisherman = Fisherman::createInstance();
	fisherman.setPos(0, 10, 0);
}

// TODO: make sure its not bad to use a variable update amount
void update()
{
	dSpaceCollide(space, 0, nearCallback);
	float deltaTime = GetFrameTime();
	dWorldStep(world, deltaTime > 0 ? deltaTime : 1);

	Fisherman::getInstance().update();
}

void draw() { planes->draw(); }

void deinit()
{
	Fisherman::destroyInstance();
	planes = std::nullopt;
	dSpaceDestroy(space);
	dWorldDestroy(world);
	dCloseODE();
}

} // namespace level
