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

	dGeomID plane = dCreateBox(space, scale.x, scale.z, scale.y);

	TraceLog(LOG_INFO, "Scale X: %f, Y: %f, Z: %f", scale.x, scale.z, scale.y);
	TraceLog(LOG_INFO, "Translate X: %f, Y: %f, Z: %f", position.x, position.z,
			 position.y);
	TraceLog(LOG_INFO, "Rotation X: %f, Y: %f, Z: %f", eulerRotation.x,
			 eulerRotation.z, eulerRotation.y);

	dReal aabb[6];
	dGeomGetAABB(plane, aabb);
	TraceLog(LOG_INFO,
			 "INITIAL AABB: \n1: %f\t2: %f\t3: %f\t4: %f\t5: %f\t6: %f",
			 aabb[0], aabb[1], aabb[4], aabb[5], aabb[2], aabb[3]);

	// cube model is 1x1x1, so just pass in the scale directly
	dGeomSetPosition(plane, position.x, position.y, position.z);

	dGeomGetAABB(plane, aabb);
	TraceLog(LOG_INFO,
			 "TRANSLATED AABB: \n1: %f\t2: %f\t3: %f\t4: %f\t5: %f\t6: %f",
			 aabb[0], aabb[1], aabb[4], aabb[5], aabb[2], aabb[3]);

	Matrix rot = MatrixRotateXYZ(eulerRotation);

	dMatrix3 odeRotation;
	dRFromEulerAngles(odeRotation, eulerRotation.z, eulerRotation.y,
					  eulerRotation.z);

	dGeomSetRotation(plane, odeRotation);
	dGeomGetAABB(plane, aabb);
	TraceLog(LOG_INFO, "FINAL AABB: \n1: %f\t2: %f\t3: %f\t4: %f\t5: %f\t6: %f",
			 aabb[0], aabb[1], aabb[4], aabb[5], aabb[2], aabb[3]);

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
