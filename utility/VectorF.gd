class_name VectorF
extends Node

static func snap_direction(direction: Vector2, eight_direction:= false) -> Vector2:
	var theta : float = direction.angle()
	var eight_direction_vec := Vector2.INF
	
	if direction != Vector2.ZERO:
		# use is equal approx to force a proper less than on floating points
		if (theta < (-PI * .75) and not is_equal_approx(theta, -PI *  3.0/4.0)):
			direction = Vector2.LEFT
			if eight_direction:
				if theta > -PI * 7.0/8.0:
					eight_direction_vec = Vector2(-1,1)
		elif (theta < -PI * 1.0/4.0 and not is_equal_approx(theta, -PI *  1.0/4.0)):
			direction = Vector2.UP
			if eight_direction:
				if theta < -PI * 5.0/8.0:
					eight_direction_vec = Vector2(-1,1)
				elif theta > -PI * 3.0/8.0:
					eight_direction_vec = Vector2(1,1)
		elif (theta < PI * 1.0/4.0 and not is_equal_approx(theta, PI *  1.0/4.0)):
			direction = Vector2.RIGHT
			if eight_direction:
				if theta < -PI * 7.0/8.0:
					eight_direction_vec = Vector2(1,1)
				elif theta > PI * 1.0/8.0:
					eight_direction_vec = Vector2(1,-1)
		elif (theta < PI * 3.0/4.0 and not is_equal_approx(theta, PI *  3.0/4.0)):
			direction = Vector2.DOWN
			if eight_direction:
				if theta < PI * 3.0/8.0:
					eight_direction_vec = Vector2(1,-1)
				elif theta > PI * 5.0/8.0:
					eight_direction_vec = Vector2(-1,-1)
		else:
			direction = Vector2.LEFT
			if eight_direction:
				if theta < PI * 7.0/8.0:
					eight_direction_vec = Vector2(-1,-1)

	return eight_direction_vec if not eight_direction_vec == Vector2.INF else direction
