#include "render_pipeline.h"
#include <raylib.h>
#include "constants/screen.h"
#include "constants/render.h"
#include "hud.h"
#include "update_cam.h"

static Camera3D camera;
static RenderTexture2D mainTarget;
static float screenScale;

#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))

namespace render {

void init()
{
	camera = Camera3D{
		.position = (Vector3){0.0f, 10.0f, 10.0f},
		.target = (Vector3){0.0f, 0.0f, 0.0f},
		.up = (Vector3){0.0f, 1.0f, 0.0f},
		.fovy = (float)FOV,
		.projection = CAMERA_PERSPECTIVE,
	};
	DisableCursor();

	mainTarget = LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT);

	hud::init();
}

void deinit()
{
	UnloadRenderTexture(mainTarget);
	hud::deinit();
}

void render(DrawFunction draw)
{
	UpdateCam(&camera);
	screenScale = MIN((float)GetScreenWidth() / GAME_WIDTH,
					  (float)GetScreenHeight() / GAME_HEIGHT);

	hud::prepass();

	// clang-format off
    BeginTextureMode(mainTarget);
        ClearBackground(BLACK);
        BeginMode3D(camera);
            draw();
        EndMode3D();
    
        hud::draw();
    EndTextureMode();
	// clang-format on

	// Resize the game's main render texture and draw it to the window.
	BeginDrawing();
	// color of the bars around the rendertexture
	ClearBackground(WHITE);
	// draw the render texture scaled
	DrawTexturePro(
		mainTarget.texture,
		Rectangle{
			.x = 0.0f,
			.y = 0.0f,
			.width = (float)mainTarget.texture.width,
			.height = (float)-mainTarget.texture.height,
		},
		Rectangle{
			.x = (GetScreenWidth() - ((float)GAME_WIDTH * screenScale)) * 0.5f,
			.y =
				(GetScreenHeight() - ((float)GAME_HEIGHT * screenScale)) * 0.5f,
			.width = (float)GAME_WIDTH * screenScale,
			.height = (float)GAME_HEIGHT * screenScale,
		},
		Vector2{0, 0}, 0.0f, WHITE);
	EndDrawing();
}

Camera3D &getCamera() { return camera; }

} // namespace render
