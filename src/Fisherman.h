#pragma once
#include <raylib.h>
#include <ode/ode.h>

class Fisherman
{
  public:
	/// Creates a new fisherman and registers it as the singleton
	static Fisherman &createInstance();
	/// Gets a reference to the registered singleton
	static Fisherman &getInstance();
	/// Removes the geometries and bodies from the physics world
	static void destroyInstance();

  public:
	void setPos(int x, int y, int z);
	Vector3 getPosV3();

	void update();

  private:
	Fisherman() noexcept;

  private:
	dBodyID m_body;
	dGeomID m_geom;
	dMass m_mass;
};
