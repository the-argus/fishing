#include "render_pipeline.h"
#include <raylib.h>
#include "constants/screen.h"
#include "constants/render.h"

static Camera3D camera;

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
}

void render(DrawFunction draw, DrawHudFunction drawHud)
{
	UpdateCamera(&camera, CAMERA_FIRST_PERSON);
	BeginMode3D(camera);
	ClearBackground(BLACK);
	draw();
    EndMode3D();

	BeginDrawing();
	drawHud();
	EndDrawing();
}

Camera3D &getCamera();

} // namespace render
