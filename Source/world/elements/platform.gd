extends StaticBody3D
class_name Platform

func up_direction() -> Vector3:
	return $GravArea.global_basis.y
