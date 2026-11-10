class_name PoseRig
extends Node3D
## Keyframed procedural animation shared by every biped. Keys are Euler XYZ
## rotations per joint; "lift" is a root offset (y up) in fractions of `unit`.

const POSED := ["upper", "armR", "foreR", "hand_R", "armL", "foreL", "legR", "shinR", "footR", "legL", "shinL", "footL"]

## Actions whose legs are posed freely, so the feet are not pinned to the ground.
const UNGROUNDED := ["roll", "death", "rest", "slam", "comet"]

# Gait curves as [phase, value] pairs. Phase 0 is heel strike; toe-off is near 0.6.
const WALK_KNEE := [[0.0, 0.1], [0.14, 0.34], [0.4, 0.08], [0.6, 0.6], [0.74, 1.2], [0.9, 0.3], [1.0, 0.1]]
const RUN_KNEE := [[0.0, 0.32], [0.14, 0.72], [0.34, 0.3], [0.5, 0.8], [0.72, 2.0], [0.9, 0.75], [1.0, 0.32]]
const WALK_FOOT := [[0.0, -0.32], [0.1, 0.0], [0.42, 0.04], [0.6, 0.75], [0.76, 0.35], [0.92, -0.2], [1.0, -0.32]]
const RUN_FOOT := [[0.0, -0.12], [0.1, 0.05], [0.34, 0.2], [0.5, 1.0], [0.72, 0.9], [0.92, -0.05], [1.0, -0.12]]

const ACTIONS := {
	"summon": [
		[0.0, {"armR": Vector3(-2.3, 0, -0.55), "foreR": Vector3(-1.0, 0, 0), "hand_R": Vector3(0.3, 0, 0), "upper": Vector3(-0.1, -0.35, 0)}],
		[0.42, {"armR": Vector3(-2.9, 0, -0.85), "foreR": Vector3(-0.3, 0, 0), "hand_R": Vector3(0.4, 0, 0), "upper": Vector3(-0.22, -0.5, 0)}],
		[0.66, {"armR": Vector3(-0.95, 0, 0.75), "foreR": Vector3(-0.35, 0, 0), "hand_R": Vector3(0.05, 0, 0), "upper": Vector3(0.2, 0.32, 0)}, "snap"],
		[1.0, {"armR": Vector3(-0.3, 0, 0.42), "foreR": Vector3(-0.95, 0, 0), "hand_R": Vector3(-0.35, 0, 0), "upper": Vector3(0.05, 0, 0)}],
	],
	"sheathe": [
		[0.0, {"armR": Vector3(-1.2, 0, 0.1), "foreR": Vector3(-1.2, 0, 0), "hand_R": Vector3(-0.4, 0, 0), "upper": Vector3(0, -0.1, 0)}],
		[0.3, {"armR": Vector3(-1.9, 0, -0.5), "foreR": Vector3(-1.0, 0, 0), "hand_R": Vector3(-0.2, 0, 0), "upper": Vector3(-0.1, -0.25, 0)}],
		[0.8, {"armR": Vector3(-1.75, 0, -0.45), "foreR": Vector3(-1.1, 0, 0), "hand_R": Vector3(-0.2, 0, 0), "upper": Vector3(-0.05, -0.2, 0)}],
		[1.0, {"armR": Vector3(-0.3, 0, 0.1), "foreR": Vector3(-0.5, 0, 0), "hand_R": Vector3(0, 0, 0), "upper": Vector3(0, 0, 0)}],
	],
	"ascend": [
		[0.0, {"armR": Vector3(-0.9, 0, 0.7), "foreR": Vector3(-1.7, 0, 0), "armL": Vector3(-0.9, 0, -0.7), "foreL": Vector3(-1.7, 0, 0), "upper": Vector3(0.35, 0, 0), "legR": Vector3(-0.5, 0, 0.06), "shinR": Vector3(0.9, 0, 0), "legL": Vector3(-0.5, 0, -0.06), "shinL": Vector3(0.9, 0, 0), "lift": Vector3.ZERO}],
		[0.56, {"armR": Vector3(-1.0, 0, 0.85), "foreR": Vector3(-1.9, 0, 0), "armL": Vector3(-1.0, 0, -0.85), "foreL": Vector3(-1.9, 0, 0), "upper": Vector3(0.55, 0, 0), "legR": Vector3(-0.9, 0, 0.06), "shinR": Vector3(1.5, 0, 0), "legL": Vector3(-0.9, 0, -0.06), "shinL": Vector3(1.5, 0, 0), "lift": Vector3.ZERO}],
		[0.66, {"armR": Vector3(-2.7, 0, -0.45), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-2.7, 0, 0.45), "foreL": Vector3(-0.1, 0, 0), "upper": Vector3(-0.35, 0, 0), "legR": Vector3(-0.05, 0, 0.05), "shinR": Vector3(0.12, 0, 0), "legL": Vector3(-0.05, 0, -0.05), "shinL": Vector3(0.12, 0, 0), "lift": Vector3(0, 0.2, 0)}, "snap"],
		[1.0, {"armR": Vector3(-2.7, 0, -0.45), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-2.7, 0, 0.45), "foreL": Vector3(-0.1, 0, 0), "upper": Vector3(-0.35, 0, 0), "legR": Vector3(-0.05, 0, 0.05), "shinR": Vector3(0.12, 0, 0), "legL": Vector3(-0.05, 0, -0.05), "shinL": Vector3(0.12, 0, 0), "lift": Vector3(0, 0.24, 0)}],
	],
	"sky_spread": [
		[0.0, {"armR": Vector3(-0.8, 0, 0.3), "foreR": Vector3(-1.0, 0, 0), "armL": Vector3(-0.8, 0, -0.3), "foreL": Vector3(-1.0, 0, 0), "upper": Vector3(0.1, 0, 0), "lift": Vector3.ZERO}],
		[0.2, {"armR": Vector3(-2.4, 0, -0.7), "foreR": Vector3(-0.2, 0, 0), "armL": Vector3(-2.4, 0, 0.7), "foreL": Vector3(-0.2, 0, 0), "upper": Vector3(-0.22, 0, 0), "legR": Vector3(0.05, 0, 0.05), "shinR": Vector3(0.1, 0, 0), "legL": Vector3(0.05, 0, -0.05), "shinL": Vector3(0.1, 0, 0), "lift": Vector3(0, 0.2, 0)}],
		[1.0, {"armR": Vector3(-2.5, 0, -0.75), "foreR": Vector3(-0.15, 0, 0), "armL": Vector3(-2.5, 0, 0.75), "foreL": Vector3(-0.15, 0, 0), "upper": Vector3(-0.26, 0, 0), "legR": Vector3(0.05, 0, 0.05), "shinR": Vector3(0.1, 0, 0), "legL": Vector3(0.05, 0, -0.05), "shinL": Vector3(0.1, 0, 0), "lift": Vector3(0, 0.26, 0)}],
	],
	"comet": [
		[0.0, {"armR": Vector3(-2.9, 0, 0.1), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-2.9, 0, -0.1), "foreL": Vector3(-0.1, 0, 0), "upper": Vector3(0.2, 0, 0), "root": Vector3(0.9, 0, 0), "legR": Vector3(0.25, 0, 0), "shinR": Vector3(0.3, 0, 0), "legL": Vector3(0.1, 0, 0), "shinL": Vector3(0.5, 0, 0)}],
		[1.0, {"armR": Vector3(-2.95, 0, 0.1), "foreR": Vector3(-0.05, 0, 0), "armL": Vector3(-2.95, 0, -0.1), "foreL": Vector3(-0.05, 0, 0), "upper": Vector3(0.2, 0, 0), "root": Vector3(1.15, 0, 0), "legR": Vector3(0.3, 0, 0), "shinR": Vector3(0.25, 0, 0), "legL": Vector3(0.15, 0, 0), "shinL": Vector3(0.45, 0, 0)}],
	],
	"boss_beam": [
		[0.0, {"armR": Vector3(0.1, 0, -0.5), "foreR": Vector3(-0.8, 0, 0), "armL": Vector3(0.1, 0, 0.5), "foreL": Vector3(-0.8, 0, 0), "upper": Vector3(0.3, 0, 0)}],
		[0.28, {"armR": Vector3(0.6, 0, -0.7), "foreR": Vector3(-0.5, 0, 0), "armL": Vector3(0.6, 0, 0.7), "foreL": Vector3(-0.5, 0, 0), "upper": Vector3(-0.3, 0, 0)}],
		[1.0, {"armR": Vector3(0.65, 0, -0.75), "foreR": Vector3(-0.45, 0, 0), "armL": Vector3(0.65, 0, 0.75), "foreL": Vector3(-0.45, 0, 0), "upper": Vector3(-0.34, 0, 0)}],
	],
	"edge": [
		[0.0, {"armR": Vector3(-1.6, 0, 0.4), "foreR": Vector3(-0.9, 0, 0), "hand_R": Vector3(-0.2, 0, 0), "armL": Vector3(-1.0, 0, -0.7), "foreL": Vector3(-0.8, 0, 0), "upper": Vector3(-0.1, -0.2, 0), "root": Vector3.ZERO, "legR": Vector3(0.2, 0, 0.08), "shinR": Vector3(0.4, 0, 0), "legL": Vector3(-0.4, 0, -0.08), "shinL": Vector3(0.5, 0, 0)}],
		[0.46, {"armR": Vector3(-3.05, 0, 0.3), "foreR": Vector3(-0.3, 0, 0), "hand_R": Vector3(-0.2, 0, 0), "armL": Vector3(-1.4, 0, -0.95), "foreL": Vector3(-0.4, 0, 0), "upper": Vector3(-0.32, -0.2, 0), "root": Vector3(-0.05, 0, 0), "legR": Vector3(0.3, 0, 0.08), "shinR": Vector3(0.5, 0, 0), "legL": Vector3(-0.55, 0, -0.08), "shinL": Vector3(0.65, 0, 0)}],
		[0.58, {"armR": Vector3(-0.75, 0, 0.3), "foreR": Vector3(-0.1, 0, 0), "hand_R": Vector3(0.1, 0, 0), "armL": Vector3(0.4, 0, 0.3), "foreL": Vector3(-0.7, 0, 0), "upper": Vector3(0.5, 0.1, 0), "root": Vector3(0.1, 0.05, 0), "legR": Vector3(-0.9, 0, 0.1), "shinR": Vector3(1.05, 0, 0), "legL": Vector3(0.6, 0, -0.1), "shinL": Vector3(0.35, 0, 0)}, "snap"],
		[1.0, {"armR": Vector3(-0.7, 0, 0.35), "foreR": Vector3(-0.25, 0, 0), "hand_R": Vector3(0.05, 0, 0), "armL": Vector3(0.3, 0, 0.25), "foreL": Vector3(-0.7, 0, 0), "upper": Vector3(0.4, 0.08, 0), "root": Vector3(0.08, 0.04, 0), "legR": Vector3(-0.85, 0, 0.1), "shinR": Vector3(1.0, 0, 0), "legL": Vector3(0.55, 0, -0.1), "shinL": Vector3(0.32, 0, 0)}],
	],
	"erasure": [
		[0.0, {"armL": Vector3(-0.9, 0, -0.4), "foreL": Vector3(-1.7, 0, 0), "armR": Vector3(0.1, 0, -0.5), "foreR": Vector3(-0.5, 0, 0), "upper": Vector3(-0.08, 0.5, 0), "lift": Vector3.ZERO}],
		[0.14, {"armL": Vector3(-1.58, 0, -0.08), "foreL": Vector3(-0.04, 0, 0), "armR": Vector3(0.1, 0, -0.75), "foreR": Vector3(-0.3, 0, 0), "upper": Vector3(0.14, -0.35, 0), "lift": Vector3(0, 0.14, 0)}, "snap"],
		[1.0, {"armL": Vector3(-1.58, 0, -0.08), "foreL": Vector3(-0.04, 0, 0), "armR": Vector3(0.1, 0, -0.75), "foreR": Vector3(-0.3, 0, 0), "upper": Vector3(0.1, -0.3, 0), "lift": Vector3(0, 0.18, 0)}],
	],
	"bigbang": [
		[0.0, {"armR": Vector3(-1.0, 0, -0.5), "foreR": Vector3(-0.5, 0, 0), "armL": Vector3(-1.0, 0, 0.5), "foreL": Vector3(-0.5, 0, 0), "upper": Vector3(0, 0, 0), "lift": Vector3.ZERO}],
		[0.28, {"armR": Vector3(-1.4, 0, -1.25), "foreR": Vector3(-0.15, 0, 0), "armL": Vector3(-1.4, 0, 1.25), "foreL": Vector3(-0.15, 0, 0), "upper": Vector3(-0.16, 0, 0), "lift": Vector3(0, 0.3, 0)}],
		[0.58, {"armR": Vector3(-1.25, 0, 0.9), "foreR": Vector3(-1.75, 0, 0), "armL": Vector3(-1.25, 0, -0.9), "foreL": Vector3(-1.75, 0, 0), "upper": Vector3(0.34, 0, 0), "lift": Vector3(0, 0.38, 0)}],
		[0.64, {"armR": Vector3(-1.75, 0, -1.4), "foreR": Vector3(-0.08, 0, 0), "armL": Vector3(-1.75, 0, 1.4), "foreL": Vector3(-0.08, 0, 0), "upper": Vector3(-0.38, 0, 0), "lift": Vector3(0, 0.56, 0)}, "snap"],
		[1.0, {"armR": Vector3(-1.75, 0, -1.4), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-1.75, 0, 1.4), "foreL": Vector3(-0.1, 0, 0), "upper": Vector3(-0.3, 0, 0), "lift": Vector3(0, 0.5, 0)}],
	],
	"cut1": [
		[0.0, {"armR": Vector3(-1.9, 0, -0.7), "foreR": Vector3(-1.2, 0, 0), "hand_R": Vector3(0.1, 0, -0.3), "armL": Vector3(-0.7, 0, -0.3), "foreL": Vector3(-1.3, 0, 0), "upper": Vector3(-0.1, -0.85, 0), "root": Vector3(0, -0.4, 0), "legR": Vector3(0.35, 0, 0.08), "shinR": Vector3(0.7, 0, 0), "legL": Vector3(-0.45, 0, -0.08), "shinL": Vector3(0.7, 0, 0)}],
		[0.3, {"armR": Vector3(-2.35, 0, -0.95), "foreR": Vector3(-1.5, 0, 0), "hand_R": Vector3(0.2, 0, -0.45), "armL": Vector3(-0.9, 0, -0.5), "foreL": Vector3(-1.6, 0, 0), "upper": Vector3(-0.22, -1.25, 0), "root": Vector3(-0.04, -0.6, 0), "legR": Vector3(0.5, 0, 0.08), "shinR": Vector3(0.95, 0, 0), "legL": Vector3(-0.6, 0, -0.08), "shinL": Vector3(0.9, 0, 0)}],
		[0.44, {"armR": Vector3(-1.05, 0, 1.75), "foreR": Vector3(-0.05, 0, 0), "hand_R": Vector3(0.85, 0, 0.1), "armL": Vector3(0.55, 0, 0.4), "foreL": Vector3(-0.7, 0, 0), "upper": Vector3(0.5, 0.95, 0), "root": Vector3(0.12, 0.5, 0), "legR": Vector3(-1.0, 0, 0.12), "shinR": Vector3(1.15, 0, 0), "legL": Vector3(0.75, 0, -0.12), "shinL": Vector3(0.35, 0, 0)}, "snap"],
		[0.7, {"armR": Vector3(-0.9, 0, 1.95), "foreR": Vector3(-0.2, 0, 0), "hand_R": Vector3(0.6, 0, 0.0), "armL": Vector3(0.5, 0, 0.35), "foreL": Vector3(-0.8, 0, 0), "upper": Vector3(0.44, 1.0, 0), "root": Vector3(0.1, 0.52, 0), "legR": Vector3(-0.95, 0, 0.12), "shinR": Vector3(1.1, 0, 0), "legL": Vector3(0.7, 0, -0.12), "shinL": Vector3(0.33, 0, 0)}],
		[1.0, {"armR": Vector3(-0.8, 0, 1.2), "foreR": Vector3(-0.8, 0, 0), "hand_R": Vector3(0.1, 0, 0), "armL": Vector3(0.05, 0, 0.1), "foreL": Vector3(-0.7, 0, 0), "upper": Vector3(0.14, 0.35, 0), "root": Vector3(0.02, 0.2, 0), "legR": Vector3(-0.5, 0, 0.1), "shinR": Vector3(0.6, 0, 0), "legL": Vector3(0.3, 0, -0.1), "shinL": Vector3(0.3, 0, 0)}],
	],
	"cut2": [
		[0.0, {"armR": Vector3(-1.2, 0, 2.0), "foreR": Vector3(-0.9, 0, 0), "hand_R": Vector3(0.5, 0, 0.25), "armL": Vector3(0.1, 0, 0.2), "foreL": Vector3(-0.9, 0, 0), "upper": Vector3(0.05, 0.8, 0), "root": Vector3(0, 0.4, 0), "legR": Vector3(-0.55, 0, 0.1), "shinR": Vector3(0.75, 0, 0), "legL": Vector3(0.35, 0, -0.1), "shinL": Vector3(0.4, 0, 0)}],
		[0.26, {"armR": Vector3(-1.3, 0, 2.3), "foreR": Vector3(-1.2, 0, 0), "hand_R": Vector3(0.6, 0, 0.4), "armL": Vector3(0.2, 0, 0.3), "foreL": Vector3(-1.0, 0, 0), "upper": Vector3(0.0, 1.05, 0), "root": Vector3(0, 0.5, 0), "legR": Vector3(-0.6, 0, 0.1), "shinR": Vector3(0.85, 0, 0), "legL": Vector3(0.4, 0, -0.1), "shinL": Vector3(0.5, 0, 0)}],
		[0.46, {"armR": Vector3(-1.5, 0, -1.0), "foreR": Vector3(-0.08, 0, 0), "hand_R": Vector3(0.95, 0, -0.15), "armL": Vector3(-0.7, 0, -0.5), "foreL": Vector3(-1.5, 0, 0), "upper": Vector3(0.2, -0.85, 0), "root": Vector3(0.06, -0.45, 0), "legR": Vector3(0.55, 0, 0.1), "shinR": Vector3(0.35, 0, 0), "legL": Vector3(-0.85, 0, -0.1), "shinL": Vector3(0.95, 0, 0)}, "snap"],
		[0.72, {"armR": Vector3(-1.25, 0, -1.25), "foreR": Vector3(-0.45, 0, 0), "hand_R": Vector3(0.7, 0, 0), "armL": Vector3(-0.6, 0, -0.45), "foreL": Vector3(-1.4, 0, 0), "upper": Vector3(0.14, -0.95, 0), "root": Vector3(0.04, -0.5, 0), "legR": Vector3(0.5, 0, 0.1), "shinR": Vector3(0.32, 0, 0), "legL": Vector3(-0.8, 0, -0.1), "shinL": Vector3(0.9, 0, 0)}],
		[1.0, {"armR": Vector3(-0.8, 0, -0.1), "foreR": Vector3(-0.9, 0, 0), "hand_R": Vector3(0.1, 0, 0), "armL": Vector3(-0.2, 0, -0.1), "foreL": Vector3(-0.8, 0, 0), "upper": Vector3(0.08, -0.4, 0), "root": Vector3(0, -0.2, 0), "legR": Vector3(0.3, 0, 0.1), "shinR": Vector3(0.3, 0, 0), "legL": Vector3(-0.5, 0, -0.1), "shinL": Vector3(0.6, 0, 0)}],
	],
	"cut3": [
		[0.0, {"armR": Vector3(-2.3, 0, 0.5), "foreR": Vector3(-1.2, 0, 0), "hand_R": Vector3(-0.4, 0, 0), "armL": Vector3(-1.5, 0, -0.4), "foreL": Vector3(-1.1, 0, 0), "upper": Vector3(-0.15, -0.2, 0), "root": Vector3(-0.03, -0.08, 0), "legR": Vector3(0.2, 0, 0.08), "shinR": Vector3(0.45, 0, 0), "legL": Vector3(-0.4, 0, -0.08), "shinL": Vector3(0.5, 0, 0)}],
		[0.34, {"armR": Vector3(-3.0, 0, 0.55), "foreR": Vector3(-1.4, 0, 0), "hand_R": Vector3(-0.5, 0, 0), "armL": Vector3(-2.0, 0, -0.5), "foreL": Vector3(-1.2, 0, 0), "upper": Vector3(-0.35, -0.25, 0), "root": Vector3(-0.06, -0.1, 0), "legR": Vector3(0.28, 0, 0.08), "shinR": Vector3(0.55, 0, 0), "legL": Vector3(-0.48, 0, -0.08), "shinL": Vector3(0.6, 0, 0)}],
		[0.54, {"armR": Vector3(-1.0, 0, 0.55), "foreR": Vector3(-0.1, 0, 0), "hand_R": Vector3(0.05, 0, 0), "armL": Vector3(0.4, 0, 0.3), "foreL": Vector3(-0.7, 0, 0), "upper": Vector3(0.42, 0.12, 0), "root": Vector3(0.1, 0.1, 0), "legR": Vector3(-0.85, 0, 0.1), "shinR": Vector3(1.0, 0, 0), "legL": Vector3(0.55, 0, -0.1), "shinL": Vector3(0.3, 0, 0)}, "snap"],
		[0.76, {"armR": Vector3(-0.85, 0, 0.55), "foreR": Vector3(-0.25, 0, 0), "hand_R": Vector3(0.0, 0, 0), "armL": Vector3(0.35, 0, 0.3), "foreL": Vector3(-0.8, 0, 0), "upper": Vector3(0.36, 0.1, 0), "root": Vector3(0.08, 0.08, 0), "legR": Vector3(-0.8, 0, 0.1), "shinR": Vector3(0.95, 0, 0), "legL": Vector3(0.5, 0, -0.1), "shinL": Vector3(0.3, 0, 0)}],
		[1.0, {"armR": Vector3(-0.5, 0, 0.55), "foreR": Vector3(-0.8, 0, 0), "hand_R": Vector3(-0.1, 0, 0), "armL": Vector3(0.1, 0, 0.1), "foreL": Vector3(-0.6, 0, 0), "upper": Vector3(0.18, 0.03, 0), "root": Vector3(0.04, 0, 0), "legR": Vector3(-0.5, 0, 0.1), "shinR": Vector3(0.6, 0, 0), "legL": Vector3(0.3, 0, -0.1), "shinL": Vector3(0.28, 0, 0)}],
	],
	"cleave": [
		[0.0, {"armR": Vector3(-2.2, 0, -0.3), "foreR": Vector3(-0.9, 0, 0), "hand_R": Vector3(-0.1, 0, -0.2), "armL": Vector3(-1.2, 0, -0.9), "foreL": Vector3(-1.4, 0, 0), "upper": Vector3(-0.05, -0.8, 0), "root": Vector3(0, -0.4, 0), "legR": Vector3(0.35, 0, 0.1), "shinR": Vector3(0.6, 0, 0), "legL": Vector3(-0.4, 0, -0.1), "shinL": Vector3(0.55, 0, 0)}],
		[0.4, {"armR": Vector3(-2.85, 0, -0.45), "foreR": Vector3(-1.05, 0, 0), "hand_R": Vector3(-0.2, 0, -0.3), "armL": Vector3(-1.7, 0, -1.0), "foreL": Vector3(-1.6, 0, 0), "upper": Vector3(-0.25, -1.15, 0), "root": Vector3(-0.05, -0.55, 0), "legR": Vector3(0.45, 0, 0.1), "shinR": Vector3(0.8, 0, 0), "legL": Vector3(-0.5, 0, -0.1), "shinL": Vector3(0.7, 0, 0)}],
		[0.58, {"armR": Vector3(-0.95, 0, 1.4), "foreR": Vector3(-0.08, 0, 0), "hand_R": Vector3(0.45, 0, 0.1), "armL": Vector3(0.45, 0, 0.35), "foreL": Vector3(-0.6, 0, 0), "upper": Vector3(0.42, 0.8, 0), "root": Vector3(0.08, 0.45, 0), "legR": Vector3(-0.9, 0, 0.12), "shinR": Vector3(1.05, 0, 0), "legL": Vector3(0.6, 0, -0.12), "shinL": Vector3(0.32, 0, 0)}, "snap"],
		[0.8, {"armR": Vector3(-0.8, 0, 1.5), "foreR": Vector3(-0.2, 0, 0), "hand_R": Vector3(0.3, 0, 0.1), "armL": Vector3(0.38, 0, 0.3), "foreL": Vector3(-0.7, 0, 0), "upper": Vector3(0.36, 0.75, 0), "root": Vector3(0.07, 0.4, 0), "legR": Vector3(-0.85, 0, 0.12), "shinR": Vector3(1.0, 0, 0), "legL": Vector3(0.55, 0, -0.12), "shinL": Vector3(0.3, 0, 0)}],
		[1.0, {"armR": Vector3(-0.5, 0, 0.8), "foreR": Vector3(-0.8, 0, 0), "hand_R": Vector3(-0.1, 0, 0), "armL": Vector3(0.1, 0, 0.1), "foreL": Vector3(-0.6, 0, 0), "upper": Vector3(0.2, 0.3, 0), "root": Vector3(0.04, 0.15, 0), "legR": Vector3(-0.5, 0, 0.1), "shinR": Vector3(0.6, 0, 0), "legL": Vector3(0.3, 0, -0.1), "shinL": Vector3(0.28, 0, 0)}],
	],
	"slash1": [
		[0.0, {"hand_R": Vector3(0.5, 0, 0), "root": Vector3(0, -0.25, 0), "legR": Vector3(0.15, 0, 0), "shinR": Vector3(0.4, 0, 0), "legL": Vector3(-0.25, 0, 0), "shinL": Vector3(0.4, 0, 0), "armR": Vector3(-1.05, 0, -1.25), "foreR": Vector3(-0.5, 0, 0), "upper": Vector3(0, -0.8, 0)}],
		[0.3, {"hand_R": Vector3(0.6, 0, 0), "root": Vector3(0, -0.35, 0), "legR": Vector3(0.2, 0, 0), "shinR": Vector3(0.5, 0, 0), "legL": Vector3(-0.3, 0, 0), "shinL": Vector3(0.5, 0, 0), "armR": Vector3(-1.2, 0, -1.45), "foreR": Vector3(-0.55, 0, 0), "upper": Vector3(0, -0.9, 0)}],
		[0.52, {"hand_R": Vector3(1.0, 0, 0), "root": Vector3(0.05, 0.35, 0), "legR": Vector3(-0.65, 0, 0), "shinR": Vector3(0.8, 0, 0), "legL": Vector3(0.45, 0, 0), "shinL": Vector3(0.3, 0, 0), "armR": Vector3(-1.5, 0, 1.15), "foreR": Vector3(-0.1, 0, 0), "upper": Vector3(0.1, 0.8, 0)}],
		[1.0, {"hand_R": Vector3(0.6, 0, 0), "root": Vector3(0.03, 0.3, 0), "legR": Vector3(-0.55, 0, 0), "shinR": Vector3(0.7, 0, 0), "legL": Vector3(0.38, 0, 0), "shinL": Vector3(0.28, 0, 0), "armR": Vector3(-1.2, 0, 1.3), "foreR": Vector3(-0.3, 0, 0), "upper": Vector3(0.05, 0.7, 0)}],
	],
	"slash2": [
		[0.0, {"hand_R": Vector3(0.5, 0, 0), "root": Vector3(0, 0.3, 0), "legR": Vector3(-0.3, 0, 0), "shinR": Vector3(0.45, 0, 0), "legL": Vector3(0.2, 0, 0), "shinL": Vector3(0.4, 0, 0), "armR": Vector3(-1.3, 0, 1.2), "foreR": Vector3(-0.4, 0, 0), "upper": Vector3(0, 0.8, 0)}],
		[0.3, {"hand_R": Vector3(0.6, 0, 0), "root": Vector3(0, 0.38, 0), "legR": Vector3(-0.35, 0, 0), "shinR": Vector3(0.5, 0, 0), "legL": Vector3(0.25, 0, 0), "shinL": Vector3(0.45, 0, 0), "armR": Vector3(-1.4, 0, 1.4), "foreR": Vector3(-0.45, 0, 0), "upper": Vector3(0, 0.9, 0)}],
		[0.52, {"hand_R": Vector3(1.0, 0, 0), "root": Vector3(0.05, -0.35, 0), "legR": Vector3(0.45, 0, 0), "shinR": Vector3(0.3, 0, 0), "legL": Vector3(-0.65, 0, 0), "shinL": Vector3(0.8, 0, 0), "armR": Vector3(-1.45, 0, -1.2), "foreR": Vector3(-0.1, 0, 0), "upper": Vector3(0.1, -0.85, 0)}],
		[1.0, {"hand_R": Vector3(0.6, 0, 0), "root": Vector3(0.03, -0.3, 0), "legR": Vector3(0.38, 0, 0), "shinR": Vector3(0.28, 0, 0), "legL": Vector3(-0.55, 0, 0), "shinL": Vector3(0.7, 0, 0), "armR": Vector3(-1.1, 0, -1.3), "foreR": Vector3(-0.3, 0, 0), "upper": Vector3(0.05, -0.7, 0)}],
	],
	"slash3": [
		[0.0, {"armR": Vector3(-2.6, 0, 0.3), "foreR": Vector3(-0.8, 0, 0), "upper": Vector3(-0.2, -0.2, 0), "legR": Vector3(0.2, 0, 0), "shinR": Vector3(0.3, 0, 0), "legL": Vector3(-0.3, 0, 0), "shinL": Vector3(0.4, 0, 0), "lift": Vector3.ZERO}],
		[0.36, {"armR": Vector3(-3.0, 0, 0.3), "foreR": Vector3(-0.9, 0, 0), "upper": Vector3(-0.4, -0.25, 0), "legR": Vector3(0.3, 0, 0), "shinR": Vector3(0.4, 0, 0), "legL": Vector3(-0.5, 0, 0), "shinL": Vector3(0.5, 0, 0), "lift": Vector3(0, 0.05, 0)}],
		[0.56, {"armR": Vector3(-0.75, 0, 0.3), "foreR": Vector3(-0.15, 0, 0), "upper": Vector3(0.55, 0.05, 0), "legR": Vector3(-0.85, 0, 0), "shinR": Vector3(1.0, 0, 0), "legL": Vector3(0.65, 0, 0), "shinL": Vector3(0.5, 0, 0), "lift": Vector3(0, -0.1, 0)}],
		[1.0, {"armR": Vector3(-0.7, 0, 0.3), "foreR": Vector3(-0.3, 0, 0), "upper": Vector3(0.4, 0.05, 0), "legR": Vector3(-0.75, 0, 0), "shinR": Vector3(0.9, 0, 0), "legL": Vector3(0.55, 0, 0), "shinL": Vector3(0.4, 0, 0), "lift": Vector3(0, -0.07, 0)}],
	],
	"cast": [
		[0.0, {"armL": Vector3(-1.0, 0, 0.3), "foreL": Vector3(-1.2, 0, 0), "upper": Vector3(-0.1, -0.5, 0)}],
		[0.35, {"armL": Vector3(-1.0, 0, 0.1), "foreL": Vector3(-1.5, 0, 0), "upper": Vector3(-0.15, -0.6, 0)}],
		[0.55, {"armL": Vector3(-1.55, 0, -0.1), "foreL": Vector3(-0.05, 0, 0), "upper": Vector3(0.12, 0.4, 0)}],
		[1.0, {"armL": Vector3(-1.45, 0, -0.1), "foreL": Vector3(-0.2, 0, 0), "upper": Vector3(0.08, 0.3, 0)}],
	],
	"drink": [
		[0.0, {"armL": Vector3(-1.2, 0, -0.5), "foreL": Vector3(-1.5, 0, 0), "upper": Vector3(0, 0, 0)}],
		[0.4, {"armL": Vector3(-1.6, 0, -0.75), "foreL": Vector3(-1.9, 0, 0), "upper": Vector3(-0.22, 0, 0)}],
		[1.0, {"armL": Vector3(-1.5, 0, -0.75), "foreL": Vector3(-1.8, 0, 0), "upper": Vector3(-0.15, 0, 0)}],
	],
	"rest": [
		[0.0, {"legR": Vector3(-1.5, 0, 0), "shinR": Vector3(1.6, 0, 0), "footR": Vector3(0, 0, 0), "legL": Vector3(0.25, 0, 0), "shinL": Vector3(2.0, 0, 0), "footL": Vector3(0.6, 0, 0), "upper": Vector3(0.45, 0, 0), "armR": Vector3(-0.5, 0, 0.5), "foreR": Vector3(-0.6, 0, 0), "armL": Vector3(-0.5, 0, -0.5), "foreL": Vector3(-0.6, 0, 0), "lift": Vector3(0, -0.34, 0)}],
		[1.0, {"legR": Vector3(-1.5, 0, 0), "shinR": Vector3(1.6, 0, 0), "footR": Vector3(0, 0, 0), "legL": Vector3(0.25, 0, 0), "shinL": Vector3(2.0, 0, 0), "footL": Vector3(0.6, 0, 0), "upper": Vector3(0.45, 0, 0), "armR": Vector3(-0.5, 0, 0.5), "foreR": Vector3(-0.6, 0, 0), "armL": Vector3(-0.5, 0, -0.5), "foreL": Vector3(-0.6, 0, 0), "lift": Vector3(0, -0.34, 0)}],
	],
	"hit": [
		[0.0, {"upper": Vector3(-0.55, 0.25, 0), "armR": Vector3(0.4, 0, -0.4), "armL": Vector3(0.4, 0, 0.4)}],
		[1.0, {"upper": Vector3(-0.1, 0, 0), "armR": Vector3(0, 0, 0), "armL": Vector3(0, 0, 0)}],
	],
	"stagger": [
		[0.0, {"upper": Vector3(-0.75, 0.3, 0.15), "armR": Vector3(0.5, 0, -0.7), "armL": Vector3(0.6, 0, 0.7), "foreL": Vector3(-0.2, 0, 0), "legR": Vector3(-0.4, 0, 0), "shinR": Vector3(0.7, 0, 0), "legL": Vector3(0.4, 0, 0), "shinL": Vector3(0.5, 0, 0), "lift": Vector3(0, -0.06, 0)}],
		[1.0, {"upper": Vector3(-0.35, 0.1, 0), "armR": Vector3(0.1, 0, -0.3), "armL": Vector3(0.2, 0, 0.3), "foreL": Vector3(-0.4, 0, 0), "legR": Vector3(-0.2, 0, 0), "shinR": Vector3(0.4, 0, 0), "legL": Vector3(0.2, 0, 0), "shinL": Vector3(0.3, 0, 0), "lift": Vector3(0, -0.03, 0)}],
	],
	"slam": [
		[0.0, {"armR": Vector3(-2.9, 0, 0.3), "foreR": Vector3(-0.6, 0, 0), "armL": Vector3(-2.7, 0, -0.4), "foreL": Vector3(-0.6, 0, 0), "upper": Vector3(-0.4, 0, 0), "legR": Vector3(-0.9, 0, 0), "shinR": Vector3(1.4, 0, 0), "legL": Vector3(-0.3, 0, 0), "shinL": Vector3(1.2, 0, 0)}],
		[0.62, {"armR": Vector3(-3.1, 0, 0.3), "foreR": Vector3(-0.7, 0, 0), "armL": Vector3(-2.9, 0, -0.4), "foreL": Vector3(-0.7, 0, 0), "upper": Vector3(-0.5, 0, 0), "legR": Vector3(-0.9, 0, 0), "shinR": Vector3(1.4, 0, 0), "legL": Vector3(-0.3, 0, 0), "shinL": Vector3(1.2, 0, 0)}],
		[0.72, {"armR": Vector3(-0.5, 0, 0.3), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-0.4, 0, -0.4), "foreL": Vector3(-0.3, 0, 0), "upper": Vector3(0.75, 0, 0), "legR": Vector3(-1.2, 0, 0), "shinR": Vector3(1.6, 0, 0), "legL": Vector3(0.9, 0, 0), "shinL": Vector3(1.1, 0, 0)}],
		[1.0, {"armR": Vector3(-0.5, 0, 0.3), "foreR": Vector3(-0.2, 0, 0), "armL": Vector3(-0.4, 0, -0.4), "foreL": Vector3(-0.3, 0, 0), "upper": Vector3(0.6, 0, 0), "legR": Vector3(-1.0, 0, 0), "shinR": Vector3(1.3, 0, 0), "legL": Vector3(0.8, 0, 0), "shinL": Vector3(0.9, 0, 0)}],
	],
	"roll": [
		[0.0, {"legR": Vector3(-1.5, 0, 0), "shinR": Vector3(2.0, 0, 0), "legL": Vector3(-1.4, 0, 0), "shinL": Vector3(2.0, 0, 0), "armR": Vector3(-1.1, 0, 0.5), "foreR": Vector3(-1.3, 0, 0), "armL": Vector3(-1.1, 0, -0.5), "foreL": Vector3(-1.3, 0, 0), "upper": Vector3(0.6, 0, 0)}],
		[1.0, {"legR": Vector3(-1.5, 0, 0), "shinR": Vector3(2.0, 0, 0), "legL": Vector3(-1.4, 0, 0), "shinL": Vector3(2.0, 0, 0), "armR": Vector3(-1.1, 0, 0.5), "foreR": Vector3(-1.3, 0, 0), "armL": Vector3(-1.1, 0, -0.5), "foreL": Vector3(-1.3, 0, 0), "upper": Vector3(0.6, 0, 0)}],
	],
	"death": [
		[0.0, {"root": Vector3.ZERO, "upper": Vector3(-0.3, 0, 0), "armR": Vector3(0.2, 0, -0.5), "armL": Vector3(0.2, 0, 0.5), "legR": Vector3(0, 0, 0), "shinR": Vector3(0, 0, 0), "legL": Vector3(0, 0, 0), "shinL": Vector3(0, 0, 0)}],
		[0.25, {"root": Vector3(0.12, 0, 0), "upper": Vector3(0.6, 0, 0), "armR": Vector3(0, 0, -0.2), "armL": Vector3(0, 0, 0.2), "legR": Vector3(-1.3, 0, 0), "shinR": Vector3(1.6, 0, 0), "legL": Vector3(-0.8, 0, 0), "shinL": Vector3(1.8, 0, 0)}],
		[1.0, {"root": Vector3(1.5, 0, 0), "upper": Vector3(0.1, 0, 0), "armR": Vector3(0.1, 0, -0.6), "armL": Vector3(0.1, 0, 0.6), "legR": Vector3(-0.2, 0, 0), "shinR": Vector3(0.3, 0, 0), "legL": Vector3(0.1, 0, 0), "shinL": Vector3(0.2, 0, 0)}],
	],
}

var joints := {}
var root_joint: Node3D
var unit := 2.6 ## Model units per body height fraction used by "lift".
var pivot := Vector3(0, 2.6, 0) ## Point the body tumbles around.
var run_speed := 6.6
var thigh := 1.01 ## Model units, used to keep the planted foot on the ground.
var shin_length := 1.09
var leg_metres := 0.76 ## Hip to ankle in metres at scale 1.
var stance := {} ## Joint offsets held while moving (shield up, sword ready).
var idle_pose := {} ## Absolute pose held when standing still, if the body has its own.
var right_hand_free := false ## Empty right hand swings like the left; a held weapon does not.
var run_hold := {} ## Absolute pose the weapon arm settles into at a full run.
var guarding := false ## Keeps the off arm on the guard instead of the idle pose.
var speed := 0.0

var action := ""
var action_time := 0.0
var action_length := 1.0
var hold_action := false

var _rot := {}
var _phase := 0.0
var _clock := 0.0
var _smooth_speed := 0.0
var _direction := Vector2(0, 1) ## Local travel direction: x is the body's left, y its front.
var _last_yaw := 0.0
var _turn := 0.0
var _snapping := false


func register(joint_name: String, node: Node3D) -> Node3D:
	node.name = joint_name
	node.rotation_order = EULER_ORDER_XYZ
	joints[joint_name] = node
	_rot[joint_name] = Vector3.ZERO
	return node


## Bodies that can show a hit override this.
func flash_hit() -> void:
	pass


func play(p_action: String, length: float, hold := false) -> void:
	action = p_action
	action_time = 0.0
	action_length = max(length, 0.01)
	hold_action = hold


func stop_action() -> void:
	action = ""
	_rot["root"] = Vector3.ZERO
	_rot["lift"] = Vector3.ZERO


func action_progress() -> float:
	return clampf(action_time / action_length, 0.0, 1.0)


func _ensure_extras() -> void:
	if not _rot.has("root"):
		_rot["root"] = Vector3.ZERO
		_rot["lift"] = Vector3.ZERO


## Feeds the gait from the body's real velocity, so strafing and backing up read correctly.
func set_motion(world_velocity: Vector3) -> void:
	var local := Basis(Vector3.UP, rotation.y).inverse() * Vector3(world_velocity.x, 0, world_velocity.z)
	speed = local.length()
	if speed > 0.05:
		_direction = Vector2(local.x, local.z) / speed


static func _curve(table: Array, p: float) -> float:
	for i in table.size() - 1:
		if p <= table[i + 1][0]:
			var span: float = table[i + 1][0] - table[i][0]
			return lerpf(table[i][1], table[i + 1][1], smoothstep(0.0, 1.0, (p - table[i][0]) / span))
	return table[0][1]


func _relative_speed() -> float:
	return _smooth_speed / (leg_metres * absf(scale.x))


func _gait_amplitude(relative: float) -> float:
	var walking := lerpf(0.16, 0.62, clampf(relative / 3.9, 0.0, 1.0))
	return lerpf(walking, 0.9, smoothstep(3.8, 7.5, relative))


## Share of the gait cycle a foot spends planted.
static func _stance_share(running: float) -> float:
	return lerpf(0.6, 0.44, running)


## Thigh travel over the cycle: an even sweep backward while planted, so the
## foot keeps pace with the ground, then a smooth swing through. -1 is fully forward.
static func _hip_travel(p: float, share: float) -> float:
	if p < share:
		return lerpf(-1.0, 1.0, p / share)
	return lerpf(1.0, -1.0, smoothstep(0.0, 1.0, (p - share) / (1.0 - share)))


## Metres travelled in one full gait cycle (two steps).
func _cycle_metres(relative: float) -> float:
	var share := _stance_share(smoothstep(3.8, 7.5, relative))
	return maxf(0.2, 2.0 * leg_metres * absf(scale.x) * sin(_gait_amplitude(relative)) / share)


func _base_pose() -> Dictionary:
	var pose := {}
	for joint_name: String in POSED:
		pose[joint_name] = Vector3.ZERO
	pose["root"] = Vector3.ZERO
	pose["lift"] = Vector3.ZERO

	var relative := _relative_speed()
	var moving := smoothstep(0.06, 0.8, relative)
	var running := smoothstep(3.8, 7.5, relative)
	var amp := _gait_amplitude(relative)
	var breath := sin(_clock * 1.8)
	var cycle := fposmod(_phase / TAU, 1.0)
	var legs := {"L": cycle, "R": fposmod(cycle + 0.5, 1.0)}
	var inward := {"L": -1.0, "R": 1.0}

	for side: String in legs:
		var p: float = legs[side]
		var travel := _hip_travel(p, _stance_share(running))
		var hip := amp * travel * _direction.y - running * 0.16
		var knee := lerpf(_curve(WALK_KNEE, p), _curve(RUN_KNEE, p), running)
		var foot_pitch := lerpf(_curve(WALK_FOOT, p), _curve(RUN_FOOT, p), running)
		# A loose guard stance when standing: left foot leads, knees soft.
		var idle_hip := -0.26 if side == "L" else 0.14
		var idle_knee := 0.34 if side == "L" else 0.3
		var final_hip := lerpf(idle_hip, hip, moving)
		var final_knee := lerpf(idle_knee, knee, moving)
		pose["leg" + side] = Vector3(final_hip, 0, inward[side] * lerpf(0.06, 0.15, moving) - amp * 0.7 * travel * _direction.x * moving)
		pose["shin" + side] = Vector3(final_knee, 0, 0)
		pose["foot" + side] = Vector3(foot_pitch * moving - (final_hip + final_knee), 0, 0)

	# The pelvis follows the leading leg and the shoulders counter it.
	var left_reach := cos(TAU * legs["L"])
	var twist := lerpf(0.1, 0.2, running) * left_reach * moving * _direction.y
	pose["root"] = Vector3(running * 0.1 * _direction.y, -twist, sin(TAU * legs["L"]) * 0.03 * moving)
	if action == "":
		pose["root"].z -= clampf(_turn * 0.03, -0.14, 0.14) * moving
	pose["upper"] = Vector3(0.05 + running * 0.2 + moving * 0.04, twist * 2.1 - 0.16 * (1.0 - moving), 0)
	pose["upper"].x += breath * 0.012 * (1.0 - moving)

	# Arms swing against the legs; the elbows fold as the pace rises.
	var swing := amp * lerpf(0.75, 1.0, running) * left_reach * maxf(_direction.y, 0.25)
	pose["armL"] = Vector3(swing, 0, lerpf(-0.12, -0.42, moving) + breath * 0.02)
	pose["foreL"] = Vector3(-lerpf(0.3, 0.45, moving) - running * 1.0 - maxf(0.0, -swing) * 0.7, 0, 0)
	pose["armR"] = Vector3(-swing * 0.55, 0, -breath * 0.02)
	pose["foreR"] = Vector3(-running * 0.35, 0, 0)
	if right_hand_free:
		pose["armR"] = Vector3(-swing, 0, lerpf(0.12, 0.42, moving) - breath * 0.02)
		pose["foreR"] = Vector3(-lerpf(0.3, 0.45, moving) - running * 1.0 - maxf(0.0, swing) * 0.7, 0, 0)

	# In a run both feet leave the ground just after each push-off.
	pose["lift"] = Vector3(0, running * 0.035 * (0.5 + 0.5 * cos(TAU * 2.0 * cycle + 1.2)), 0)

	for joint_name: String in stance:
		pose[joint_name] += stance[joint_name]

	if running > 0.0 and not run_hold.is_empty():
		for joint_name: String in run_hold:
			pose[joint_name] = (pose[joint_name] as Vector3).lerp(run_hold[joint_name], running)
		pose["armR"].x -= swing * 0.14 * running

	var still := 1.0 - moving
	if still > 0.0 and not idle_pose.is_empty():
		for joint_name: String in idle_pose:
			if guarding and (joint_name == "armL" or joint_name == "foreL"):
				continue
			pose[joint_name] = (pose[joint_name] as Vector3).lerp(idle_pose[joint_name], still)
		for side: String in ["L", "R"]:
			var flat: float = -(pose["leg" + side].x + pose["shin" + side].x)
			pose["foot" + side].x = lerpf(pose["foot" + side].x, flat, still)
		# Slow, heavy breathing that lifts the chest and stirs the blade.
		pose["upper"] += Vector3(-breath * 0.03, 0, 0) * still
		pose["armR"] += Vector3(breath * 0.018, 0, 0) * still
		pose["armL"] += Vector3(-breath * 0.02, 0, breath * 0.02) * still
		pose["hand_R"] += Vector3(breath * 0.025, 0, 0) * still
	return pose


## How far the hips must drop so the lowest foot rests on the ground.
func _grounding(pose: Dictionary) -> float:
	var deepest := 0.0
	for side: String in ["L", "R"]:
		var hip: Vector3 = pose["leg" + side]
		var knee: float = pose["shin" + side].x
		deepest = maxf(deepest, (thigh * cos(hip.x) + shin_length * cos(hip.x + knee)) * cos(hip.z))
	return (deepest - (thigh + shin_length)) / unit


func _action_pose() -> Dictionary:
	var keys: Array = ACTIONS[action]
	var t := action_progress()
	var from: Array = keys[0]
	var to: Array = keys[keys.size() - 1]
	for i in keys.size() - 1:
		if t >= keys[i][0] and t <= keys[i + 1][0]:
			from = keys[i]
			to = keys[i + 1]
			break
	var span: float = to[0] - from[0]
	var raw := 0.0 if span <= 0.0 else clampf((t - from[0]) / span, 0.0, 1.0)
	# A "snap" key is reached by accelerating all the way in, like a released spring.
	_snapping = to.size() > 2
	var f := pow(raw, 2.4) if _snapping else smoothstep(0.0, 1.0, raw)
	var out := {}
	for joint_name: String in from[1]:
		var a: Vector3 = from[1][joint_name]
		var b: Vector3 = to[1].get(joint_name, a)
		out[joint_name] = a.lerp(b, f)
	return out


func update_pose(delta: float) -> void:
	_ensure_extras()
	_clock += delta
	_smooth_speed = lerpf(_smooth_speed, speed, 1.0 - exp(-11.0 * delta))
	var relative := _relative_speed()
	_phase += _smooth_speed / _cycle_metres(relative) * TAU * delta
	if delta > 0.0:
		var yaw_rate := wrapf(rotation.y - _last_yaw, -PI, PI) / delta
		_turn = lerpf(_turn, yaw_rate, 1.0 - exp(-8.0 * delta))
	_last_yaw = rotation.y

	var pose := _base_pose()
	var rate := 30.0
	var grounded := true
	if action != "":
		action_time += delta
		rate = 36.0
		var t := action_progress()
		var overlay := _action_pose()
		if _snapping:
			rate = 90.0
		var weight := 1.0 if hold_action else 1.0 - smoothstep(0.74, 1.0, t)
		for joint_name: String in overlay:
			pose[joint_name] = (pose[joint_name] as Vector3).lerp(overlay[joint_name], weight)
		grounded = not action in UNGROUNDED
		if grounded:
			for side: String in ["L", "R"]:
				if overlay.has("leg" + side):
					var level: float = -(pose["leg" + side].x + pose["shin" + side].x)
					pose["foot" + side] = (pose["foot" + side] as Vector3).lerp(Vector3(level, 0, 0), weight)
		if action == "roll":
			pose["root"] = Vector3(t * TAU, 0, 0)
			_rot["root"] = pose["root"]
		if t >= 1.0 and not hold_action:
			stop_action()
			pose["root"] = Vector3.ZERO
	if grounded:
		pose["lift"] += Vector3(0, _grounding(pose), 0)

	var k := 1.0 - exp(-rate * delta)
	for joint_name: String in pose:
		if not _rot.has(joint_name):
			continue
		_rot[joint_name] = (_rot[joint_name] as Vector3).lerp(pose[joint_name], k)
		if joints.has(joint_name):
			joints[joint_name].rotation = _rot[joint_name]

	var tumble := Basis.from_euler(_rot["root"], EULER_ORDER_XYZ)
	var lift: Vector3 = _rot["lift"] * unit
	var around := Vector3.ZERO if action == "death" else pivot
	root_joint.transform = Transform3D(tumble, around - tumble * around + lift)
