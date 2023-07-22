#include "PlaneSet.h"
#include <raymath.h>
#include <cassert>

// shared resources between PlaneSets
static Shader instancedPlaneShader;
static Model planeModel;
static size_t referenceCount = 0;
static const char *materialsFile = "assets/plane.mtl";
static const char *modelFile = "assets/plane.obj";
static const char *vShader = "assets/shaders/plane_instanced.vs";
static const char *fShader = "assets/shaders/plane_instanced.fs";

PlaneSet::PlaneSet() noexcept
{
	m_geoms.reserve(initialSize);
	m_transforms.reserve(initialSize);

	if (referenceCount == 0) {
		planeModel = LoadModel(modelFile);

		assert(planeModel.meshes != nullptr);

		instancedPlaneShader = LoadShader(vShader, fShader);
		instancedPlaneShader.locs[SHADER_LOC_MATRIX_MVP] =
			GetShaderLocation(instancedPlaneShader, "mvp");
		instancedPlaneShader.locs[SHADER_LOC_MATRIX_MODEL] =
			GetShaderLocationAttrib(instancedPlaneShader, "instanceTransform");
		planeModel.materials[0].shader = instancedPlaneShader;
	}
	referenceCount++;
}

PlaneSet::~PlaneSet() noexcept
{
	referenceCount--;

	for (const auto &geom : m_geoms) {
		dGeomDestroy(geom);
	}

	if (referenceCount == 0) {
		UnloadModel(planeModel);
		UnloadShader(instancedPlaneShader);
	}
}

void PlaneSet::draw()
{
	if (m_transforms.size() == 0)
		return;

	// draw the first mesh in the model with the first material, instanced
	DrawMeshInstanced(*planeModel.meshes, *planeModel.materials,
					  m_transforms.data(), m_transforms.size());
}

dGeomID PlaneSet::createPlane(dSpaceID space, PlaneOptions opt)
{
	const auto &scale = opt.scale;
	const auto &position = opt.position;
	const auto &eulerRotation = opt.eulerRotation;

	dGeomID plane = dCreateBox(space, scale.x, scale.y, scale.z);

	dGeomSetPosition(plane, position.x, position.y, position.z);

	Matrix rot = MatrixRotateXYZ(eulerRotation);

	// ODE uses 4x3 matrices for rotation instead of 4x4 like raylib. chop off
	// the fourth row. also the way this array is initialized means that its
	// written sideways. turn your head 90 degrees to read it properly
	// clang-format off
	dMatrix3 odeRotation = {
		rot.m0,     rot.m1,     rot.m2,
        rot.m4,     rot.m5,     rot.m6,
		rot.m8,     rot.m9,     rot.m10,
        rot.m12,    rot.m13,    rot.m14,
	};
	// clang-format on

	dGeomSetRotation(plane, odeRotation);

	m_geoms.push_back(plane);

	// next step is to get transforms for the plane
	// easy enough since we took raylib types as input and we use raylib
	// types for drawing.
	Matrix scaled = MatrixScale(scale.x, scale.y, scale.z);
	Matrix translation = MatrixTranslate(position.x, position.y, position.z);

	m_transforms.push_back(
		MatrixMultiply(MatrixMultiply(translation, rot), scaled));

	return plane;
}
