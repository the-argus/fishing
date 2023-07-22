#include "Fisherman.h"
#include "constants/player.h"
#include "render_pipeline.h"
#include <raymath.h>

Fisherman &Fisherman::getInstance()
{
	static Fisherman fisherman;
	return fisherman;
}

Fisherman::Fisherman()
{

}

void Fisherman::update() 
{ 
    Camera3D camera = render::getCamera();
    Vector3 force = {0};
	Vector2 input = {0};

    // Set camera's position to body
    camera.position = getPosV3(); 
    
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
	Vector3 h_force = Vector3CrossProduct(Vector3Normalize(force), (Vector3){0, 1, 0});

    force = Vector3Scale(force, input.x);

    h_force = Vector3Scale(h_force, input.y);

    force = Vector3Add(force, h_force);

    dBodyAddRelForce(body, force.x, force.y, force.z);  
}

void Fisherman::setup(dWorldID &world, dSpaceID &space)
{
	body = dBodyCreate(world);
	dMassSetBox(&mass, 1, PLAYER_WIDTH, PLAYER_HEIGHT, PLAYER_LENGTH);
	dMassAdjust(&mass, PLAYER_MASS);
	geom = dCreateBox(space, PLAYER_WIDTH, PLAYER_HEIGHT, PLAYER_LENGTH);
	dGeomSetBody(geom, body);
	dBodySetMass(body, &mass);
}

void Fisherman::setPos(int x, int y, int z) { dBodySetPosition(body, x, y, z); }

Vector3 Fisherman::getPosV3()
{
	auto *pos = dBodyGetPosition(body);

	return Vector3{.x = pos[0], .y = pos[1], .z = pos[2]};
}
