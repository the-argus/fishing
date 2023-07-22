#include "Fisherman.h"
#include "constants/player.h"

Fisherman &Fisherman::getInstance()
{
	static Fisherman fisherman;
	return fisherman;
}

Fisherman::Fisherman()
{

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

void Fisherman::setPos(int x, int y, int z) 
{ 
    dBodySetPosition(body, x, y, z); 
}

Vector3 Fisherman::getPosV3()
{
	auto* pos = dBodyGetPosition(body);

	return Vector3{.x = pos[0], .y = pos[1], .z = pos[2]};
}
