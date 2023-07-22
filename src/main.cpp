#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif
#include <raylib.h>
#include <stdio.h>
#include "render_pipeline.h"
#include "constants/screen.h"
#include "level.h"

void update();
void init();
void deinit();


#ifdef __EMSCRIPTEN__
int emsc_main()
#else
int main()
#endif
{
	printf("Hello, World\n");
	init();
#ifdef __EMSCRIPTEN__
	emscripten_set_main_loop(update, 0, 1);
#else
	while (!WindowShouldClose()) {
		update();
	}
#endif
}

void init()
{
	// SetConfigFlags(FLAG_MSAA_4X_HINT);
	SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT);
	InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "fishing");
	SetTargetFPS(60);

	render::init();
	level::init();
}

void draw() { DrawGrid(10, 1.0f); }

void draw_hud() {}

void update()
{
	level::update();
    render::render(draw, draw_hud); 
}

void deinit()
{
	level::deinit();
	render::deinit();
	CloseWindow();
}

#ifdef __EMSCRIPTEN__
void emsc_set_window_size(int width, int height)
{
	SetWindowSize(width, height);
}
#endif
