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
	contact->surface.mu = 0.5;
	contact->surface.soft_cfm = 0.01;
}

static void nearCallback(void *unused, dGeomID o1, dGeomID o2)
{
	int i;

	if (o1 == o2)
		return;

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

	dGeomID staticGeom;
	dGeomID dynamicGeom;
	if (noGround) {
		staticGeom = o1IsPlane ? o1 : o2;
		dynamicGeom = !o1IsPlane ? o1 : o2;
	} else {
		staticGeom = o1IsGround ? o1 : o2;
		dynamicGeom = !o1IsGround ? o1 : o2;
	}

	assert(staticGeom != dynamicGeom);

	dBodyID b1 = dGeomGetBody(o1);
	dBodyID b2 = dGeomGetBody(o2);

	dContact contact[3]; // up to 3 contacts per box
	for (i = 0; i < 3; i++) {
		initContact(&contact[i]);
	}
	int numc = dCollide(dynamicGeom, staticGeom, 3, &contact[0].geom,
						sizeof(dContact));
	for (i = 0; i < numc; i++) {
		dJointID c = dJointCreateContact(world, contactGroup, contact + i);
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
	dInitODE();
	world = dWorldCreate();
	space = dHashSpaceCreate(0);
	dWorldSetGravity(world, 0, -GRAVITY, 0);

	contactGroup = dJointGroupCreate(0);

	planes.emplace();

	for (const auto &wall : walls) {
		planes->createPlane(space, wall);
	}

	debugGroundPlane = dCreatePlane(space, 0, 1, 0, 0);

	// create fisherman
	Fisherman fisherman = Fisherman::createInstance();
	fisherman.setPos(0, 30, 0);
}

// TODO: make sure its not bad to use a variable update amount
void update()
{
	dSpaceCollide(space, 0, nearCallback);
	float deltaTime = GetFrameTime();
	dWorldStep(world, deltaTime > 0 ? deltaTime : 0.16);

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
