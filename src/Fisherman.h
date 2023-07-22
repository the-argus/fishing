#pragma once
#include <raylib.h>
#include <ode/ode.h>

class Fisherman
{
  public:
	static Fisherman &getInstance();

    void setup(dWorldID &world, dSpaceID &space);
	void setPos(int x, int y, int z);
	Vector3 getPosV3();
  
private:
	dBodyID body;
	dMass mass;
	dGeomID geom;

	Fisherman();
};
