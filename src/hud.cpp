#include "hud.h"
#include "constants/render.h"
#include <raylib.h>

static Model fishModel;
static Camera3D hudCamera;
static Shader hudShader;

static constexpr auto fishModelFile = "assets/fish.obj";
static constexpr auto vShader = "assets/shaders/hud.vs";
static constexpr auto fShader = "assets/shaders/hud.fs";

namespace hud {

void init()
{
	hudCamera = Camera3D{
		.position = (Vector3){1.0f, 0.0f, 10.0f},
		.target = (Vector3){0.0f, 0.0f, 0.0f},
		.up = (Vector3){0.0f, 1.0f, 0.0f},
		.fovy = (float)VIEWMODEL_FOV,
		.projection = CAMERA_PERSPECTIVE,
	};

	fishModel = LoadModel(fishModelFile);

	hudShader = LoadShader(vShader, fShader);
	hudShader.locs[SHADER_LOC_MATRIX_MVP] = GetShaderLocation(hudShader, "mvp");
	fishModel.materials[0].shader = hudShader;
}

void draw()
{
	BeginMode3D(hudCamera);

	BeginShaderMode(hudShader);

	DrawModelEx(fishModel, Vector3{.x = 0.5, .y = -0.1, .z = 0.2},
				Vector3{0, 0, 1}, DEG2RAD * 90.0f, Vector3{1, 1, 1}, WHITE);

	EndShaderMode();

	EndMode3D();
}

void deinit()
{
	UnloadShader(hudShader);
	UnloadModel(fishModel);
}
} // namespace hud
