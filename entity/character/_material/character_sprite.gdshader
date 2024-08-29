shader_type canvas_item;

uniform bool highlighted;
uniform vec4 border_color: source_color;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec4 u_col = texture(TEXTURE, vec2(UV.x, UV.y - TEXTURE_PIXEL_SIZE.y));
	vec4 d_col = texture(TEXTURE, vec2(UV.x, UV.y + TEXTURE_PIXEL_SIZE.y));
	vec4 l_col = texture(TEXTURE, vec2(UV.x - TEXTURE_PIXEL_SIZE.x, UV.y));
	vec4 r_col = texture(TEXTURE, vec2(UV.x + TEXTURE_PIXEL_SIZE.x, UV.y));
	vec4 lu_col = texture(TEXTURE, vec2(UV.x - TEXTURE_PIXEL_SIZE.x, UV.y - TEXTURE_PIXEL_SIZE.y));
	vec4 ru_col = texture(TEXTURE, vec2(UV.x + TEXTURE_PIXEL_SIZE.x, UV.y - TEXTURE_PIXEL_SIZE.y));
	vec4 ld_col = texture(TEXTURE, vec2(UV.x - TEXTURE_PIXEL_SIZE.x, UV.y + TEXTURE_PIXEL_SIZE.y));
	vec4 rd_col = texture(TEXTURE, vec2(UV.x + TEXTURE_PIXEL_SIZE.x, UV.y + TEXTURE_PIXEL_SIZE.y));
	if (highlighted && u_col.a + d_col.a + l_col.a + r_col.a + lu_col.a + ru_col.a + ld_col.a + rd_col.a < 8.0 && col.a != 0.0 && col.r + col.b + col.g < .5)
	{
		int highlight_uv;
		highlight_uv = int(TIME * 50.0) % int(1.0/TEXTURE_PIXEL_SIZE.y);
		int pixel_uv = int(UV.y * (1.0/TEXTURE_PIXEL_SIZE.y));
		if (abs(pixel_uv - highlight_uv) < 4)
			COLOR = border_color; 
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
