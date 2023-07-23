#include "Fisherman.h"
#include "constants/player.h"
#include "render_pipeline.h"
#include "level.h"
#include "sfx.h"
#include <rcamera.h>
#include <raymath.h>
#include <optional>
#include <cassert>
#include <iostream>

static std::optional<Fisherman> fisherman = std::nullopt;

Fisherman &Fisherman::getInstance()
{
	assert(fisherman.has_value());
	return fisherman.value();
}

Fisherman &Fisherman::createInstance()
{
	assert(!fisherman.has_value());

	fisherman = Fisherman();

	return getInstance();
}

Fisherman::Fisherman() noexcept
	: m_body(level::createBody()),
	  m_geom(level::createGeomBox(PLAYER_WIDTH, PLAYER_HEIGHT, PLAYER_LENGTH))
{
	dMassSetBox(&m_mass, PLAYER_DENSITY, PLAYER_WIDTH, PLAYER_HEIGHT,
				PLAYER_LENGTH);
	dMassAdjust(&m_mass, PLAYER_MASS);

	dGeomSetBody(m_geom, m_body);
	dBodySetMass(m_body, &m_mass);
}

void Fisherman::destroyInstance()
{
	auto &target = getInstance();
	dBodyDestroy(target.m_body);
	dGeomDestroy(target.m_geom);
	fisherman = std::nullopt;
}

static Vector3 myForce{0};

void Fisherman::draw()
{
	if (Vector3LengthSqr(myForce) == 0)
		return;

	Vector3 playerPos = getInstance().getPosV3();
	DrawLine3D(Vector3Add({0, -1, 0}, playerPos),
			   Vector3Add(playerPos, myForce), GREEN);

	const dReal *force = dBodyGetForce(getInstance().m_body);
	auto actualForce = Vector3{.x = force[0], .y = force[1], .z = force[2]};

	Vector3 translated = Vector3Add({0.1, 0, 0}, playerPos);
	DrawLine3D(translated, Vector3Add(translated, actualForce), RED);

	myForce = {0};
}

void Fisherman::update()
{
	// Set camera's position to body
	Camera3D &camera = render::getCamera();

	// transform both the camera and its target by the same amount
	Vector3 fisherPosition = getPosV3();
	Vector3 delta = Vector3Subtract(fisherPosition, camera.position);
	camera.position = Vector3Add(delta, camera.position);
	camera.target = Vector3Add(delta, camera.target);

	Vector3 force{0};
	Vector2 input{0};

	// Set input based on keys
	if (IsKeyDown(KEY_W))
		input.x += 1;
	if (IsKeyDown(KEY_S))
		input.x -= 1;
	if (IsKeyDown(KEY_A))
		input.y -= 1;
	if (IsKeyDown(KEY_D))
		input.y += 1;

	if (IsKeyPressed(KEY_M))
		sfx::play(sfx::Bank::FishHit);

	if (Vector2LengthSqr(input) == 0)
		return;

	Vector3 v1 = camera.position;
	Vector3 v2 = camera.target;

	float dx = v2.x - v1.x;
	float dy = v2.y - v1.y;
	float dz = v2.z - v1.z;

	float angle_x = atan2f(dx, dz);

	force.x = sin(angle_x) * PLAYER_MOVEMENT_SPEED;
	force.z = cos(angle_x) * PLAYER_MOVEMENT_SPEED;
	assert(Vector3LengthSqr(force) != 0);
	Vector3 h_force =
		Vector3CrossProduct(Vector3Normalize(force), (Vector3){0, 1, 0});

	force = Vector3Scale(force, input.x);
	h_force = Vector3Scale(h_force, input.y);

	force = Vector3Add(force, h_force);
	myForce = force;

	dBodyAddRelForce(m_body, force.x, force.y, force.z);
}

void Fisherman::setPos(int x, int y, int z)
{
	dBodySetPosition(m_body, x, y, z);
}

Vector3 Fisherman::getPosV3()
{
	auto *pos = dBodyGetPosition(m_body);

	return Vector3{.x = pos[0], .y = pos[1], .z = pos[2]};
}
