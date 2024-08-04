class_name Global
extends Object

enum PhysicsLayers {
	ENVIRONMENT = 1,
	INTERACTION = 2,
	ALLY = 3
}

const PLAYER_SPEED: float = 50
const TILE_SIZE := Vector2i(32, 16)

const BATTLE_MAP_ATLAS_COORDS := Vector2.ZERO
const RETICLE_MOVE_ALTAS_COORDS := Vector2i(0,1)
const RETICLE_ATTACK_ALTAS_COORDS := Vector2i(0,2)
const RETICLE_BLOCKED_ALTAS_COORDS := Vector2i(0,3)
const RETICLE_CURE_1_ATLAS_COORD := Vector2i(0,4)
const RETICLE_CURE_2_ATLAS_COORD := Vector2i(0,5)
const RETICLE_SPECIAL_1_ALTAS_COORDS := Vector2i(0,6)
const RETICLE_SPECIAL_2_ATLAS_COORDS := Vector2i(0,7)
const GAME_SIZE := Vector2i(640,360)
