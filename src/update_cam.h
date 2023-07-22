#pragma once
#include <raylib.h>
#include <rcamera.h>
#include "constants/camera.h"

inline void UpdateCam(Camera3D *camera)
{
	Vector2 mousePositionDelta = GetMouseDelta();

	CameraYaw(camera, -mousePositionDelta.x * MOUSE_SENSITIVITY, false);
	CameraPitch(camera, -mousePositionDelta.y * MOUSE_SENSITIVITY, true, false,
				false);
}
