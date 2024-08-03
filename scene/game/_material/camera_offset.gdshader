shader_type canvas_item;

global uniform vec2 cam_offset;

void vertex() {
	VERTEX += cam_offset;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
