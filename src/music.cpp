#include "music.h"
#include <raylib.h>

namespace music {

static Music mainTrack;
static constexpr auto mainTrackFileName = "assets/music/fish.ogg";

void init()
{
	InitAudioDevice();
	mainTrack = LoadMusicStream(mainTrackFileName);
	SetMusicVolume(mainTrack, 1);
	PlayMusicStream(mainTrack);
}

void update() { UpdateMusicStream(mainTrack); }

void deinit()
{
	UnloadMusicStream(mainTrack);
	CloseAudioDevice();
}
} // namespace music
