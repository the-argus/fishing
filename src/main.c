#include <chipmunk/chipmunk.h>
#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif
#include <raylib.h>
#include <stdio.h>

void update();
void init();
void deinit();

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
  while (true) {
    update();
  }
#endif
}

void init() {
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(1920, 1080, "abmoog");
  SetTargetFPS(60);
}

void update() {}

void deinit() { CloseWindow(); }

#ifdef __EMSCRIPTEN__
void emsc_set_window_size(int width, int height) {
  SetWindowSize(width, height);
}
#endif
