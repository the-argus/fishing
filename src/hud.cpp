#include "hud.h"
#include "constants/render.h"
#include "constants/screen.h"
#include <math.h>
#include <raylib.h>
#include <raymath.h>
#include <rlgl.h>

static Model fishModel;
static Camera3D hudCamera;
static Shader hudShader;
static RenderTexture hudTexture;

static constexpr auto fishModelFile = "assets/fish.obj";
static constexpr auto vShader = "assets/shaders/hud.vs";
static constexpr auto fShader = "assets/shaders/hud.fs";
static Vector3 rotation{0};

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

	fishModel.transform = MatrixRotateXYZ(rotation);

	hudTexture = LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT);
}

void prepass() {}

void draw()
{
	int modifier = IsKeyDown(KEY_LEFT_SHIFT) ? -1 : 1;
	modifier *= 10 * DEG2RAD;

	if (IsKeyDown(KEY_I))
		rotation.x += modifier;
	if (IsKeyDown(KEY_O))
		rotation.y += modifier;
	if (IsKeyDown(KEY_P))
		rotation.z += modifier;

	fishModel.transform = MatrixRotateXYZ(rotation);

	// BeginTextureMode(hudTexture);

	// draw the 3D model onto the texture
	BeginMode3D(hudCamera);
	BeginShaderMode(hudShader);
	DrawModel(fishModel, Vector3{.x = 0.5, .y = -0.1, .z = 0.2}, 1, WHITE);
	EndShaderMode();
	EndMode3D();

	DrawText(
		TextFormat("X: %f\tY: %f\tZ: %f", rotation.x, rotation.y, rotation.z),
		10, 10, 12, WHITE);

	// EndTextureMode();

	// rlDisableDepthTest();
	DrawTexture(hudTexture.texture, GAME_WIDTH / 2, GAME_WIDTH / 2, WHITE);
	// rlEnableDepthTest();
}

void deinit()
{
	UnloadShader(hudShader);
	UnloadModel(fishModel);
	UnloadRenderTexture(hudTexture);
}
} // namespace hud
