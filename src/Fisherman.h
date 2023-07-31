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

	// move and copy are not deleted, they are used internally. since the
	// constructor is private though it doesn't matter since you can only get
	// a reference to the singleton

  public:
	void setPos(Vector3);
	Vector3 getPosV3();

	void update();
	static void draw();

  private:
	Fisherman() noexcept;
	void applyMovement();

	static constexpr Vector3 jumpForce{0.0, 2000.0, 0.0};
	static constexpr int density = 1;
	static constexpr Vector3 physicsSize{1, 2, 1};
	static constexpr size_t mass = 10;
	static constexpr int movementImpulse = 500;

  private:
	dBodyID m_body;
	dGeomID m_geom;
	dMass m_mass; // TODO: I'm 90% sure this can be removed, ODE doesn't keep
				  // a pointer to it
};
