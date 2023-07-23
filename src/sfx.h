#pragma once
#include <cstdint>

namespace sfx {

enum Bank : uint8_t
{
	FishHit = 0,
	HookFish,
	WallHit,
	LineReel,
};

void init();

void play(Bank sound);

bool isPlaying(Bank sound);

void deinit();

} // namespace sfx
