#include "sfx.h"
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

namespace sfx {

void init()
{
	for (auto &pair : soundPairs) {
		pair.sound = LoadSound(pair.filename);
	}
}

void play(Bank index)
{
	PlaySound(soundPairs[index].sound);
	TraceLog(LOG_INFO, "playing sound %d", (int)index);
}

bool isPlaying(Bank index) { return IsSoundPlaying(soundPairs[index].sound); }

void deinit()
{
	for (auto &pair : soundPairs) {
		UnloadSound(pair.sound);
	}
}

} // namespace sfx
