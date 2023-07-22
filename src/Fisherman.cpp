#include "Fisherman.h"
#include "constants/player.h"
#include "render_pipeline.h"
#include "level.h"
#include <raymath.h>
#include <optional>
#include <cassert>

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
	dMass mass;
	dMassSetBox(&mass, 1, PLAYER_WIDTH, PLAYER_HEIGHT, PLAYER_LENGTH);
	dMassAdjust(&mass, PLAYER_MASS);

	dGeomSetBody(m_geom, m_body);
	dBodySetMass(m_body, &mass);
}

void Fisherman::destroyInstance()
{
	auto &target = getInstance();
	dBodyDestroy(target.m_body);
	dGeomDestroy(target.m_geom);
	fisherman = std::nullopt;
}

void Fisherman::update()
{
	// Set camera's position to body
	Camera3D camera = render::getCamera();
	camera.position = getPosV3();

	Vector3 force = {0};
	Vector2 input = {0};

	// Set input based on keys
	if (IsKeyDown(KEY_W))
		input.x += 1;
	if (IsKeyDown(KEY_S))
		input.x -= 1;
	if (IsKeyDown(KEY_A))
		input.y -= 1;
	if (IsKeyDown(KEY_D))
		input.y += 1;

	double angle_x = 1.0;

	// Can't seem to get angle from camera easily, will worry about tomorrow
	force.x = sin(angle_x) * PLAYER_MOVEMENT_SPEED;
	force.z = cos(angle_x) * PLAYER_MOVEMENT_SPEED;
	Vector3 h_force =
		Vector3CrossProduct(Vector3Normalize(force), (Vector3){0, 1, 0});

	force = Vector3Scale(force, input.x);

	h_force = Vector3Scale(h_force, input.y);

	force = Vector3Add(force, h_force);

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
