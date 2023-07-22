#pragma once

#include "raylib.h"
#include <ode/ode.h>
#include <vector>

class PlaneSet
{
  public:
	explicit PlaneSet() noexcept;
	~PlaneSet() noexcept;

	void draw();

	struct PlaneOptions
	{
		Vector3 position;
		Vector3 scale;
		Vector3 eulerRotation;
	};

	// the rotation to use for a horizontal plane (floor or ceiling)
	static constexpr Vector3 flatPlaneRotation{.x = 90, .y = 0, .z = 0};

	dGeomID createPlane(dSpaceID space, PlaneOptions);

  private:
	// the initial size of the vector. speeds up plane creation at level load
	// time
	static constexpr size_t initialSize = 32;

	std::vector<Matrix> m_transforms;
	std::vector<dGeomID> m_geoms;
};
