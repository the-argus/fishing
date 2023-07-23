#pragma once

#include "raylib.h"
#include <ode/ode.h>
#include <vector>

class PlaneSet
{
  public:
	explicit PlaneSet() noexcept;
	~PlaneSet() noexcept;

	PlaneSet(const PlaneSet &) = delete;
	PlaneSet(PlaneSet &&) = delete;

	void draw();

	struct PlaneOptions
	{
		Vector3 position;
		Vector3 scale;
		Vector3 eulerRotation;
	};

	// the rotation to use for a horizontal plane (floor or ceiling)
	static constexpr Vector3 flatPlaneRotation{
		.x = 0, .y = 0, .z = DEG2RAD * 90};

	dGeomID createPlane(dSpaceID space, PlaneOptions);

	/// returns true if the geometry is in this PlaneSet.
	inline bool isPlane(dGeomID target) const
	{
		for (const auto geom : m_geoms) {
			if (geom == target)
				return true;
		}
		return false;
	}

	inline const std::vector<dGeomID> &getPlanes() { return m_geoms; }

  private:
	// the initial size of the vector. speeds up plane creation at level load
	// time
	static constexpr size_t initialSize = 32;

	std::vector<Matrix> m_transforms;
	std::vector<dGeomID> m_geoms;
};
