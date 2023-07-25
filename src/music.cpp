#include "music.h"
#include <raylib.h>
#include "sfx.h"

namespace music {

static Music mainTrack;
static constexpr auto mainTrackFileName = "assets/music/fish.ogg";

void init()
{
	InitAudioDevice();
	mainTrack = LoadMusicStream(mainTrackFileName);
	sfx::init();
	SetMusicVolume(mainTrack, 1);
	PlayMusicStream(mainTrack);
}

void update() { UpdateMusicStream(mainTrack); }

void deinit()
{
	sfx::deinit();
	UnloadMusicStream(mainTrack);
	CloseAudioDevice();
}
} // namespace music
