#pragma once

#include "raylib.h"
#include <ode/ode.h>
#include <vector>

class PlaneSet
{
  public:
	explicit PlaneSet() noexcept;
	explicit PlaneSet(Material) noexcept;
	~PlaneSet() noexcept;

	void draw();

	dGeomID createPlane(dSpaceID space, float a, float b, float c, float d);

  private:
	static constexpr size_t initialSize = 256;

	std::vector<Matrix> m_transforms;
	std::vector<dGeomID> m_geoms;
	Material m_material;

	Shader *m_instancedPlaneShader;
	Mesh *m_planeMesh;
};
