#pragma once
#include <cstdint>

namespace sfx {

enum Bank : uint8_t
{
	FishHit = 0,
	HookFish,
	WallHit,
};

void init();

void play(Bank sound);

void deinit();

} // namespace sfx
