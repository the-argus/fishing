#include <update_cam.h>
#include <rcamera.h>
#include "constants/camera.h"

// Shamelessly modified from rcamera.h
void UpdateCam(Camera3D *camera)
{
	Vector2 mousePositionDelta = GetMouseDelta();

	CameraYaw(camera, -mousePositionDelta.x * MOUSE_SENSITIVITY,
			  false);
	CameraPitch(camera, -mousePositionDelta.y * MOUSE_SENSITIVITY, true, false,
				false);
}
