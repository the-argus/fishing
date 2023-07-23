#include "level.h"
#include "constants/physics.h"
#include "Fisherman.h"
#include "PlaneSet.h"
#include <raymath.h>
#include <ode/ode.h>
#include <raylib.h>
#include <array>
#include <optional>
#include <cassert>

static dWorldID world;
static dSpaceID space;
static dGeomID debugGroundPlane;
static dJointGroupID contactGroup;
static dThreadingImplementationID threading;
static dThreadingThreadPoolID pool;
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

static void initContact(dContact *contact)
{
	contact->surface.mode = dContactSoftCFM | dContactApprox1;
	// contact->surface.mu = 0.5;
	contact->surface.soft_cfm = 0.01;
	contact->surface.mu = dInfinity;
	contact->surface.mu2 = 0;
	contact->surface.bounce = 0;
}

static void nearCallback(void *unused, dGeomID o1, dGeomID o2)
{
	int i;

	bool o1IsPlane = planes->isPlane(o1);
	bool o2IsPlane = planes->isPlane(o2);
	bool o1IsGround = o1 == debugGroundPlane;
	bool o2IsGround = o2 == debugGroundPlane;

	bool noPlane = (!o1IsPlane && !o2IsPlane);
	bool noGround = (!o1IsGround && !o2IsGround);

	// only collide things with the ground
	if (noGround && noPlane) {
		return;
	}

	dBodyID b1 = dGeomGetBody(o1);
	dBodyID b2 = dGeomGetBody(o2);

	size_t n_contacts = 3;
	dContact contact[n_contacts]; // up to 3 contacts per box
	int numc = dCollide(o1, o2, n_contacts, &contact[0].geom, sizeof(dContact));
	for (i = 0; i < numc; i++) {
		initContact(&contact[i]);
		dJointID c = dJointCreateContact(world, contactGroup, &contact[i]);
		dJointAttach(c, b1, b2);
	}
}

namespace level {

bool onGround(dBodyID body)
{
	dGeomID geom = dBodyGetFirstGeom(body);

	assert(!planes->isPlane(geom));

	auto &groundPlanes = planes->getPlanes();

	float bestCollision = -(~0);
	for (const auto &plane : groundPlanes) {
		dContact contact;
		initContact(&contact);
		int num_collisions =
			dCollide(geom, plane, 1, &contact.geom, sizeof(dContactGeom));

		if (num_collisions > 0) {
			Vector3 normal{
				.x = contact.geom.normal[0],
				.y = contact.geom.normal[1],
				.z = contact.geom.normal[2],
			};
			// ensure the collision was with a face which is pointing up
			float upness = Vector3DotProduct(normal, (Vector3){0, 1, 0});

			if (upness > bestCollision) {
				bestCollision = upness;
			}
		}
	}
	return bestCollision > ON_GROUND_THRESHHOLD;
}

dBodyID createBody() { return dBodyCreate(world); }

dGeomID createGeomBox(int lx, int ly, int lz)
{
	return dCreateBox(space, lx, ly, lz);
}

void init()
{
	if (dInitODE2(0) == 0) {
		TraceLog(LOG_FATAL, "Failed to initialize ODE physics engine.");
		std::abort();
	}
	world = dWorldCreate();
	space = dHashSpaceCreate(0);
	dWorldSetGravity(world, 0, -GRAVITY, 0);
	dWorldSetCFM(world, 1e-5);
    dWorldSetMaxAngularSpeed(world, 0);

	contactGroup = dJointGroupCreate(0);

	planes.emplace();

	for (const auto &wall : walls) {
		planes->createPlane(space, wall);
	}

	debugGroundPlane = dCreatePlane(space, 0, 1, 0, 0);

	// create fisherman
	Fisherman fisherman = Fisherman::createInstance();
	fisherman.setPos(0, 30, 0);

	// NOTE: allocating all data, probably not necessary and can be
	// decreased given some testing/research
	if (!dAllocateODEDataForThread(dAllocateMaskAll))
		TraceLog(LOG_WARNING, "Physics thread allocation failure");
}

// TODO: make sure its not bad to use a variable update amount
void update()
{
	dSpaceCollide(space, 0, &nearCallback);
	// don't move faster than 60fps (.016ms step time)
	dWorldStep(world, std::max(GetFrameTime(), 0.016f));

	Fisherman::getInstance().update();
	dJointGroupEmpty(contactGroup);
}

void draw()
{
	planes->draw();
	Fisherman::draw();
}

void deinit()
{
	Fisherman::destroyInstance();
	planes = std::nullopt;
	dJointGroupDestroy(contactGroup);
	dGeomDestroy(debugGroundPlane);
	dSpaceDestroy(space);
	dWorldDestroy(world);
	dCloseODE();
}

} // namespace level
