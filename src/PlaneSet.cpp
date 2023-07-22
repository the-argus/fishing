#include "PlaneSet.h"
#include <optional>

static std::optional<Shader> instancedPlaneShader = std::nullopt;
static std::optional<Mesh> planeMesh = std::nullopt;
static size_t referenceCount = 0;

PlaneSet::PlaneSet(Material mat) noexcept : PlaneSet() { m_material = mat; }

PlaneSet::PlaneSet() noexcept
{
	m_geoms.reserve(initialSize);
	m_availableIndices.reserve(initialSize);
	m_transforms.reserve(initialSize);
	for (size_t i = 0; i < initialSize; i++) {
		m_availableIndices.push_back(i);
	}

	m_material = {
		.shader =
			{
				.id = 0,
				.locs = 0,
			},
		.maps = nullptr,
		.params = {},
	};

	if (!instancedPlaneShader.has_value()) {
		instancedPlaneShader = {.id = 0, .locs = {}};
	}

	if (!planeMesh.has_value()) {
		planeMesh = GenMeshPlane(10, 10, 1, 1);
	}

	m_planeMesh = &planeMesh;
	m_instancedPlaneShader = &instancedPlaneShader;
	referenceCount++;
}

PlaneSet::~PlaneSet() noexcept
{
	referenceCount--;

	for (const auto *geom : m_geoms) {
		dGeomDestroy(geom);
	}

	if (referenceCount == 0) {
		UnloadMesh(planeMesh.get());
		UnloadShader(instancedPlaneShader.get());
	}
}

void PlaneSet::draw()
{
	BeginShaderMode(instancedPlaneShader);
	DrawMeshInstanced(planeMesh, m_material, m_transforms.data(),
					  m_transforms.size());
}

dGeomID PlaneSet::createPlane(dSpaceID space, float a, float b, float c,
							  float d)
{
	dGeomID plane = dCreatePlane(space, a, b, c, d);
}
