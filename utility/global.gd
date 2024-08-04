class_name Global
extends Object

enum PhysicsLayers {
	ENVIRONMENT = 1,
	INTERACTION = 2,
	ALLY = 3
}

const PLAYER_SPEED: float = 50
const TILE_SIZE := Vector2i(32, 16)

const RETICLE_BLOCKED_ALTAS_COORDS := Vector2i(0,3)
const RETICLE_ATTACK_ALTAS_COORDS := Vector2i(0,2)
const RETICLE_MOVE_ALTAS_COORDS := Vector2i(0,1)
const RETICLE_SPECIAL_ALTAS_COORDS := Vector2i(0,3)
const BATTLE_MAP_ATLAS_COORDS := Vector2.ZERO
const GAME_SIZE := Vector2i(640,360)
