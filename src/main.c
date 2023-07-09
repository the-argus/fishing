#include <chipmunk/chipmunk.h>
#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif
#include "physics.h"
#include <raylib.h>
#include <stdio.h>

static ShapeHandle ground;

void update();
void init();
void deinit();

#define SCREEN_WIDTH 600
#define SCREEN_HEIGHT 600

#ifdef __EMSCRIPTEN__
int emsc_main()
#else
int main()
#endif
{
  printf("Hello, abmoog\n");
  init();
#ifdef __EMSCRIPTEN__
  emscripten_set_main_loop(update, 0, 1);
#else
  while (!WindowShouldClose()) {
    update();
  }
#endif
}

void init() {
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "abmoog");
  SetTargetFPS(60);

  physics_init();

  ground = physics_shape_static_box_new(SCREEN_WIDTH, 10, 10);
  cpShape *raw = physics_shape_get_raw(ground);
}

void update() {
  physics_step();

  BeginDrawing();
  ClearBackground(BLACK);
  DrawRectanglePro((Rectangle){.width = 100,
                               .height = 100,
                               .x = (int)(GetTime() * 200) % SCREEN_WIDTH,
                               .y = SCREEN_HEIGHT / 2.0},
                   (Vector2){0, 0}, sin(GetTime()) * RAD2DEG, RED);
  EndDrawing();
}

void deinit() {
  physics_deinit();
  CloseWindow();
}

#ifdef __EMSCRIPTEN__
void emsc_set_window_size(int width, int height) {
  SetWindowSize(width, height);
}
#endif
