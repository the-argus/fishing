#pragma once
#include <cstdint>

namespace sound {

void init();

void update();

void deinit();

enum Effect : uint8_t
{
	FishHit = 0,
	HookFish,
	WallHit,
	LineReel,
};

void play(Effect sound);

bool isPlaying(Effect sound);

} // namespace sound
