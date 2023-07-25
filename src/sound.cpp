#include "sound.h"
#include <raylib.h>
#include <array>

typedef struct
{
	Sound sound;
	const char *filename;
} SoundPair;

/// NOTE: this must match the enum declaration order in the header
static std::array soundPairs{
	SoundPair{.filename = "assets/sfx/fishHit.ogg"},
	SoundPair{.filename = "assets/sfx/hookFish.ogg"},
	SoundPair{.filename = "assets/sfx/wallHit.ogg"},
	SoundPair{.filename = "assets/sfx/lineReel_loopable.ogg"},
};

static Music mainTrack;
static constexpr auto mainTrackFileName = "assets/music/fish.ogg";

namespace sound {
void init()
{
	InitAudioDevice();

	mainTrack = LoadMusicStream(mainTrackFileName);
	for (auto &pair : soundPairs) {
		pair.sound = LoadSound(pair.filename);
	}

	SetMusicVolume(mainTrack, 1);
	PlayMusicStream(mainTrack);
}

void update() { UpdateMusicStream(mainTrack); }

void deinit()
{
	for (auto &pair : soundPairs) {
		UnloadSound(pair.sound);
	}
	UnloadMusicStream(mainTrack);
	CloseAudioDevice();
}

void play(Effect index)
{
	PlaySound(soundPairs[index].sound);
	TraceLog(LOG_INFO, "playing sound %d", (int)index);
}

bool isPlaying(Effect index) { return IsSoundPlaying(soundPairs[index].sound); }

} // namespace sound
