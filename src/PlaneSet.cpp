#include "PlaneSet.h"
#include <raymath.h>
#include <cassert>

// shared resources between PlaneSets
static Shader instancedPlaneShader;
static Model planeModel;
static size_t referenceCount = 0;
static const char *materialsFile = "assets/cube.mtl";
static const char *modelFile = "assets/cube.obj";
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

	TraceLog(LOG_INFO, "Scale X: %f, Y: %f, Z: %f", scale.x, scale.y, scale.z);
	TraceLog(LOG_INFO, "Translate X: %f, Y: %f, Z: %f", position.x, position.y,
			 position.z);
	TraceLog(LOG_INFO, "Rotation X: %f, Y: %f, Z: %f", eulerRotation.x,
			 eulerRotation.y, eulerRotation.z);

	dReal aabb[6];
	dGeomGetAABB(plane, aabb);
	TraceLog(LOG_INFO,
			 "INITIAL AABB: \n1: %f\t2: %f\t3: %f\t4: %f\t5: %f\t6: %f",
			 aabb[0], aabb[1], aabb[2], aabb[3], aabb[4], aabb[5]);

	// cube model is 1x1x1, so just pass in the scale directly
	dGeomSetPosition(plane, position.x, position.z, position.y);

	dGeomGetAABB(plane, aabb);
	TraceLog(LOG_INFO,
			 "TRANSLATED AABB: \n1: %f\t2: %f\t3: %f\t4: %f\t5: %f\t6: %f",
			 aabb[0], aabb[1], aabb[2], aabb[3], aabb[4], aabb[5]);

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
	dGeomGetAABB(plane, aabb);
	TraceLog(LOG_INFO, "FINAL AABB: \n1: %f\t2: %f\t3: %f\t4: %f\t5: %f\t6: %f",
			 aabb[0], aabb[1], aabb[2], aabb[3], aabb[4], aabb[5]);

	m_geoms.push_back(plane);

	// next step is to get transforms for the plane
	// easy enough since we took raylib types as input and we use raylib
	// types for drawing.
	Matrix scaled = MatrixScale(scale.x, scale.y, scale.z);
	Matrix translation = MatrixTranslate(position.x, position.y, position.z);

	m_transforms.push_back(
		MatrixMultiply(MatrixMultiply(rot, scaled), translation));

	return plane;
}
