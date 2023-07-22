#include <update_cam.h>
#include <rcamera.h>
#include "constants/camera.h"
#include "Fisherman.h"

void UpdateCam(Camera3D *camera)
{
	Vector2 mousePositionDelta = GetMouseDelta();

	CameraYaw(camera, -mousePositionDelta.x * MOUSE_SENSITIVITY, false);
	CameraPitch(camera, -mousePositionDelta.y * MOUSE_SENSITIVITY, true, false, false);

    camera->position = Fisherman::getInstance().getPosV3();
}
