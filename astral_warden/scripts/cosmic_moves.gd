class_name CosmicMoves
extends RefCounted
## The twelve powers exactly as keyed in cosmic_warrior.html, and ARGON's six from gemini_aegis.html:
## poses, timing and effect channels. ARGON's moves carry "argon", so the stage plays them in its colours.
## A channel is a list of [share of the move, value]. `fx` lists [share of the move, effect, argument].

const POSES := {
	"guard": [-0.12, -0.08, 0.1, -0.4, 0.06],
	"wind": [-0.277, 1.439, -0.354, -2.252, -0.823],
	"punch": [-0.956, 0.819, -1.157, -0.24, -0.168],
	"cast": [-1.79, -0.02, -0.653, 0.12, 0.377],
	"skyHand": [-1.206, -1.807, 1.326, 0.012, 0.555],
	"wide": [1.851, 1.04, 1.088, -1.461, 1.328],
	"skySpread": [-1.448, -1.166, 1.302, -0.274, 1.092],
	"cross": [-0.14, -1.86, 0.514, -1.534, 0.345],
	"swordUp": [-2.498, 0.666, -0.773, -0.305, -1.696],
	"swordDown": [-0.849, 0.201, -0.836, -0.407, -0.247],
	"sweepOut": [-1.767, 0.991, 0.093, -1.508, 0.778],
	"sweepIn": [-0.174, -1.941, 0.807, -0.764, 0.528],
	"dive": [0.251, 0.541, -0.279, 0.12, 0.455],
}
const SAMPLES := 72
const LEG_LENGTH := 2.1
const LIFT_PER_LEAP := 1.8 / (1.9 * 2.6) ## Web root offset, in the rig's "lift" units.

static var _moves := {}


static func _pk(m: Dictionary, channel: String, keys: Array) -> void:
	if not m.has(channel):
		m[channel] = []
	m[channel].append_array(keys)


static func _arm(m: Dictionary, side: int, seq: Array) -> void:
	var s := "L" if side > 0 else "R"
	for i in 5:
		var keys := []
		for key: Array in seq:
			keys.append([key[0], POSES[key[1]][i] - POSES["guard"][i]])
		_pk(m, s + "xyzfr"[i], keys)


static func _both(m: Dictionary, seq: Array) -> void:
	_arm(m, 1, seq)
	_arm(m, -1, seq)


static func track(q: float, keys: Array) -> float:
	if q <= keys[0][0]:
		return keys[0][1]
	for i in range(1, keys.size()):
		var a: float = keys[i - 1][0]
		var b: float = keys[i][0]
		if q <= b:
			var u := 1.0 if b == a else (q - a) / (b - a)
			return lerpf(keys[i - 1][1], keys[i][1], u * u * (3.0 - 2.0 * u))
	return keys[keys.size() - 1][1]


static func channel(m: Dictionary, name: String, q: float) -> float:
	return track(q, m[name]) if m.has(name) else 0.0


static func all() -> Dictionary:
	if _moves.is_empty():
		_build()
	return _moves


static func _build() -> void:
	var m := {"dur": 1.55, "fx": [[0.42, "nova"]]}
	_arm(m, -1, [[0, "guard"], [0.28, "wind"], [0.42, "punch"], [0.72, "punch"], [1, "guard"]])
	_arm(m, 1, [[0, "guard"], [1, "guard"]])
	_pk(m, "twist", [[0, 0], [0.28, -0.42], [0.42, 0.75], [0.72, 0.6], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.28, -0.1], [0.42, 0.16], [0.72, 0.12], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.42, 0.4], [0.8, 0.4], [1, 0]])
	_moves["nova"] = m

	m = {"dur": 2.7, "fx": [[0.6, "crater"]]}
	_both(m, [[0, "guard"], [0.2, "dive"], [0.58, "dive"], [0.74, "guard"], [1, "guard"]])
	_pk(m, "leap", [[0.06, 0], [0.3, 12.5], [0.42, 12.5], [0.6, 0]])
	_pk(m, "drop", [[0, 0], [0.06, 0.3], [0.18, -0.1], [0.6, 0.75], [0.76, 0.75], [1, 0]])
	_pk(m, "rootX", [[0.3, 0], [0.44, 0.34], [0.6, 0.34], [0.7, 0]])
	_pk(m, "kx", [[0.3, 0], [0.46, -1.2], [0.6, -1.2], [0.72, 0]])
	_pk(m, "ks", [[0.3, 0], [0.46, 0.3], [0.6, 0.3], [0.72, 0]])
	_pk(m, "tail", [[0.4, 0], [0.46, 3], [0.6, 3], [0.62, 0]])
	_pk(m, "wide", [[0, 0], [0.3, 1.2], [0.7, 1.2], [1, 0]])
	_moves["comet"] = m

	m = {"dur": 3.0, "fx": [[0.5, "cleave", 0.0], [0.78, "cleave", 1.2]]}
	_pk(m, "blade", [[0.04, 0], [0.2, 1], [0.9, 1], [1, 0]])
	_arm(m, -1, [[0, "guard"], [0.24, "swordUp"], [0.42, "swordUp"], [0.5, "swordDown"], [0.6, "swordDown"], [0.7, "sweepOut"], [0.78, "sweepIn"], [0.9, "sweepIn"], [1, "guard"]])
	_arm(m, 1, [[0, "guard"], [0.24, "wide"], [0.9, "wide"], [1, "guard"]])
	_pk(m, "twist", [[0, 0], [0.24, -0.25], [0.42, -0.3], [0.5, 0.35], [0.6, 0.3], [0.7, -0.8], [0.78, 0.95], [0.9, 0.8], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.24, -0.16], [0.42, -0.2], [0.5, 0.26], [0.6, 0.2], [0.78, 0.1], [1, 0]])
	_pk(m, "leap", [[0.14, 0], [0.34, 1.4], [0.46, 1.4], [0.52, 0]])
	_pk(m, "Bt", [[0.43, 0], [0.45, 1], [0.5, 1], [0.54, 0], [0.71, 0], [0.73, 1], [0.78, 1], [0.82, 0]])
	_pk(m, "Bp", [[0.16, 0], [0.4, 0.6], [0.5, 2], [0.62, 0.5], [0.78, 2], [0.92, 0.4], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.2, 1.25], [0.9, 1.25], [1, 0]])
	_moves["galaxy"] = m

	m = {"dur": 2.5, "fx": []}
	_both(m, [[0, "guard"], [0.13, "cast"], [0.88, "cast"], [1, "guard"]])
	_pk(m, "leap", [[0, 0], [0.13, 1.3], [0.88, 1.3], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.13, -0.06], [0.88, -0.06], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.13, 0.5], [0.9, 0.5], [1, 0]])
	for i in 26:
		m["fx"].append([0.16 + i * 0.027, "throwStar", -1.0 if i % 2 == 1 else 1.0])
	_moves["barrage"] = m

	m = {"dur": 3.6, "fx": []}
	_arm(m, -1, [[0, "guard"], [0.14, "skyHand"], [0.82, "skyHand"], [1, "guard"]])
	_arm(m, 1, [[0, "guard"], [0.14, "wide"], [0.82, "wide"], [1, "guard"]])
	_pk(m, "dom", [[0.04, 0], [0.2, 1], [0.86, 1], [1, 0]])
	_pk(m, "leap", [[0, 0], [0.14, 1.1], [0.82, 1.1], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.14, -0.14], [0.82, -0.14], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.2, 1.4], [0.86, 1.4], [1, 0]])
	for i in 26:
		m["fx"].append([0.2 + i * 0.022 + (i % 3) * 0.004, "meteor"])
	_moves["starfall"] = m

	m = {"dur": 3.8, "fx": [[0.76, "holeBlast"]]}
	_both(m, [[0, "guard"], [0.14, "cast"], [0.78, "cast"], [1, "guard"]])
	_pk(m, "dom", [[0.06, 0], [0.24, 0.85], [0.76, 0.85], [0.86, 0]])
	_pk(m, "bh", [[0.12, 0], [0.6, 1], [0.72, 1], [0.76, 0]])
	_pk(m, "lean", [[0, 0], [0.14, -0.14], [0.76, -0.2], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.2, 1], [0.86, 1], [1, 0]])
	_pk(m, "leap", [[0, 0], [0.14, 0.7], [0.8, 0.7], [1, 0]])
	_moves["hole"] = m

	m = {"dur": 4.8, "fx": [[0.67, "supernova"]]}
	_both(m, [[0, "guard"], [0.2, "wide"], [0.52, "skySpread"], [0.64, "cross"], [0.68, "wide"], [0.86, "wide"], [1, "guard"]])
	_pk(m, "leap", [[0.06, 0], [0.26, 3.4], [0.64, 3.4], [0.86, 3], [1, 0]])
	_pk(m, "dom", [[0.04, 0], [0.26, 1], [0.9, 1], [1, 0]])
	_pk(m, "core", [[0.2, 0], [0.64, 2.2], [0.68, 0]])
	_pk(m, "sn", [[0.66, 0], [0.9, 1]])
	_pk(m, "white", [[0.64, 0], [0.68, 1], [0.72, 0.55], [0.86, 0]])
	_pk(m, "lean", [[0, 0], [0.26, -0.12], [0.6, -0.2], [0.66, 0.22], [0.86, 0], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.26, 1.5], [0.92, 1.5], [1, 0]])
	_moves["supernova"] = m

	m = {"dur": 6.0, "fx": [[0.15, "seed"], [0.72, "peak"]]}
	_both(m, [[0, "guard"], [0.12, "cast"], [0.3, "skySpread"], [0.86, "skySpread"], [1, "guard"]])
	_pk(m, "dom", [[0.05, 0], [0.2, 1], [0.93, 1], [1, 0]])
	_pk(m, "gal", [[0.14, 0], [0.7, 1], [0.93, 1], [1, 0]])
	_pk(m, "leap", [[0, 0], [0.2, 3], [0.86, 3], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.3, -0.16], [0.86, -0.16], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.3, 1.5], [0.9, 1.5], [1, 0]])
	_pk(m, "core", [[0.1, 0], [0.3, 0.4], [0.86, 0.25], [1, 0]])
	for i in 26:
		m["fx"].append([0.28 + i * 0.022, "birth"])
	_moves["genesis"] = m

	m = {"dur": 6.4, "fx": [[0.86, "collide"]]}
	_both(m, [[0, "guard"], [0.14, "wide"], [0.5, "skySpread"], [0.78, "skySpread"], [0.84, "cross"], [0.92, "wide"], [1, "guard"]])
	_pk(m, "dom", [[0.04, 0], [0.16, 1], [0.95, 1], [1, 0]])
	_pk(m, "mv", [[0.08, 0], [0.55, 1], [0.86, 1], [0.87, 0]])
	_pk(m, "mvC", [[0.72, 0], [0.86, 1]])
	_pk(m, "leap", [[0, 0], [0.16, 3.4], [0.92, 3.4], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.5, -0.2], [0.8, -0.2], [0.86, 0.2], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.2, 1.8], [0.95, 1.8], [1, 0]])
	_pk(m, "white", [[0.85, 0], [0.87, 0.95], [0.97, 0]])
	_moves["multiverse"] = m

	m = {"dur": 4.8, "fx": [[0.61, "worldCut"]]}
	_pk(m, "blade", [[0.04, 0], [0.18, 1], [0.92, 1], [1, 0]])
	_pk(m, "bladeS", [[0.14, 0], [0.42, 5], [0.86, 5], [0.98, 0]])
	_arm(m, -1, [[0, "guard"], [0.3, "swordUp"], [0.54, "swordUp"], [0.61, "swordDown"], [0.86, "swordDown"], [1, "guard"]])
	_arm(m, 1, [[0, "guard"], [0.3, "wide"], [0.86, "wide"], [1, "guard"]])
	_pk(m, "twist", [[0, 0], [0.3, -0.3], [0.54, -0.36], [0.61, 0.4], [0.86, 0.3], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.3, -0.18], [0.54, -0.24], [0.61, 0.32], [0.86, 0.22], [1, 0]])
	_pk(m, "leap", [[0.1, 0], [0.4, 4.4], [0.55, 4.4], [0.62, 0]])
	_pk(m, "dom", [[0.08, 0], [0.3, 1], [0.94, 1], [1, 0]])
	_pk(m, "Bp", [[0.14, 0], [0.5, 0.9], [0.61, 3], [0.8, 1], [1, 0]])
	_pk(m, "Bt", [[0.55, 0], [0.57, 1], [0.62, 1], [0.66, 0]])
	_pk(m, "rift", [[0.595, 0], [0.62, 1.6], [0.84, 1], [0.97, 0]])
	_pk(m, "white", [[0.59, 0], [0.615, 0.85], [0.7, 0]])
	_pk(m, "wide", [[0, 0], [0.3, 1.9], [0.92, 1.9], [1, 0]])
	_moves["edge"] = m

	m = {"dur": 4.4, "fx": [[0.3, "snap"], [0.905, "restore"]]}
	_arm(m, -1, [[0, "guard"], [0.2, "punch"], [0.92, "punch"], [1, "guard"]])
	_arm(m, 1, [[0, "guard"], [0.2, "wide"], [0.92, "wide"], [1, "guard"]])
	_pk(m, "leap", [[0, 0], [0.2, 2], [0.92, 2], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.3, 0.8], [0.9, 0.8], [1, 0]])
	_pk(m, "shatter", [[0.3, 0], [0.6, 0.66], [0.8, 1], [0.9, 1], [0.905, 0]])
	_pk(m, "white", [[0.87, 0], [0.905, 1], [0.99, 0]])
	_moves["erasure"] = m

	m = {"dur": 7.4, "fx": [[0.605, "bang"]]}
	_both(m, [[0, "guard"], [0.22, "wide"], [0.5, "cross"], [0.585, "cross"], [0.62, "wide"], [0.9, "wide"], [1, "guard"]])
	_pk(m, "leap", [[0.04, 0], [0.24, 5], [0.9, 5], [1, 0]])
	_pk(m, "dom", [[0.03, 0], [0.2, 1], [0.95, 1], [1, 0]])
	_pk(m, "core", [[0.14, 0], [0.585, 3.4], [0.61, 0]])
	_pk(m, "sn", [[0.6, 0], [0.9, 1]])
	_pk(m, "white", [[0.585, 0], [0.61, 1], [0.72, 0.6], [0.9, 0]])
	_pk(m, "gal", [[0.66, 0], [0.92, 1.15], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.24, -0.14], [0.58, -0.24], [0.62, 0.24], [0.9, 0], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.24, 1.6], [0.585, 1.4], [0.64, 2], [0.95, 2], [1, 0]])
	for i in 18:
		m["fx"].append([0.14 + i * 0.025, "implode"])
	_moves["bigbang"] = m
	_build_argon()


## GEMINI ARGON, keeper of the system. Channels the game has no use for are left out.
static func _build_argon() -> void:
	var m := {"dur": 3.4, "argon": true, "fx": [[0.16, "ping"], [0.83, "scanDone"]]}
	_arm(m, -1, [[0, "guard"], [0.14, "skyHand"], [0.84, "skyHand"], [1, "guard"]])
	_arm(m, 1, [[0, "guard"], [0.14, "wide"], [0.84, "wide"], [1, "guard"]])
	_pk(m, "leap", [[0, 0], [0.16, 1.4], [0.84, 1.4], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.16, -0.1], [0.84, -0.1], [1, 0]])
	_pk(m, "scan", [[0.16, 0], [0.8, 1]])
	_pk(m, "scanA", [[0.14, 0], [0.18, 1], [0.82, 1], [0.96, 0]])
	_pk(m, "wide", [[0, 0], [0.2, 1.3], [0.9, 1.3], [1, 0]])
	_moves["scan"] = m

	m = {"dur": 3.8, "argon": true, "fx": [[0.1, "autoScan"], [0.73, "crushAll"]]}
	_both(m, [[0, "guard"], [0.14, "cast"], [0.64, "wide"], [0.72, "cross"], [0.86, "cross"], [1, "guard"]])
	_pk(m, "leap", [[0, 0], [0.14, 1.2], [0.86, 1.2], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.14, -0.08], [0.72, 0.14], [1, 0]])
	_pk(m, "orb", [[0.1, 0], [0.3, 0.6], [0.7, 0.6], [0.74, 0]])
	_pk(m, "wide", [[0, 0], [0.2, 1.3], [0.9, 1.3], [1, 0]])
	_pk(m, "white", [[0.72, 0], [0.735, 0.4], [0.8, 0]])
	for i in 12:
		m["fx"].append([0.2 + i * 0.035, "seal"])
	_moves["quarantine"] = m

	m = {"dur": 4.6, "argon": true, "fx": [[0.38, "wallUp"], [0.9, "wallDown"]]}
	_both(m, [[0, "guard"], [0.12, "cross"], [0.3, "cross"], [0.38, "wide"], [0.88, "wide"], [1, "guard"]])
	_pk(m, "wall", [[0.3, 0], [0.44, 1], [0.9, 1], [1, 1]])
	_pk(m, "shield", [[0.05, 0], [0.2, 1], [0.9, 1], [1, 0]])
	_pk(m, "orb", [[0.3, 0], [0.42, 1], [0.9, 1], [1, 0]])
	_pk(m, "leap", [[0, 0], [0.3, 0.7], [0.9, 0.7], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.12, 0.08], [0.3, 0.1], [0.38, -0.1], [0.88, -0.06], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.38, 1.7], [0.92, 1.7], [1, 0]])
	for i in 22:
		m["fx"].append([0.44 + i * 0.019, "wallHit"])
	_moves["firewall"] = m

	m = {"dur": 4.8, "argon": true, "fx": [[0.2, "purgeLock"], [0.61, "purgeCut"]]}
	_pk(m, "blade", [[0.04, 0], [0.18, 1], [0.92, 1], [1, 0]])
	_pk(m, "bladeS", [[0.14, 0], [0.42, 5], [0.86, 5], [0.98, 0]])
	_arm(m, -1, [[0, "guard"], [0.3, "swordUp"], [0.54, "swordUp"], [0.61, "swordDown"], [0.86, "swordDown"], [1, "guard"]])
	_arm(m, 1, [[0, "guard"], [0.3, "wide"], [0.86, "wide"], [1, "guard"]])
	_pk(m, "twist", [[0, 0], [0.3, -0.3], [0.54, -0.36], [0.61, 0.4], [0.86, 0.3], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.3, -0.18], [0.54, -0.24], [0.61, 0.32], [0.86, 0.22], [1, 0]])
	_pk(m, "leap", [[0.1, 0], [0.4, 4.4], [0.55, 4.4], [0.62, 0]])
	_pk(m, "Bp", [[0.14, 0], [0.5, 0.9], [0.61, 3], [0.8, 1], [1, 0]])
	_pk(m, "Bt", [[0.55, 0], [0.57, 1], [0.62, 1], [0.66, 0]])
	_pk(m, "rift", [[0.595, 0], [0.62, 1.6], [0.84, 1], [0.97, 0]])
	_pk(m, "white", [[0.59, 0], [0.615, 0.85], [0.7, 0]])
	_pk(m, "shield", [[0.1, 0], [0.3, 0.5], [0.86, 0.5], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.3, 1.9], [0.92, 1.9], [1, 0]])
	_moves["purge"] = m

	m = {"dur": 3.6, "argon": true, "fx": [[0.16, "patchStart"], [0.62, "patched"]]}
	_both(m, [[0, "guard"], [0.16, "cross"], [0.58, "cross"], [0.7, "skySpread"], [0.92, "skySpread"], [1, "guard"]])
	_pk(m, "core", [[0.1, 0], [0.55, 2.2], [0.62, 0.3], [1, 0]])
	_pk(m, "patch", [[0.5, 0], [0.96, 1]])
	_pk(m, "white", [[0.6, 0], [0.63, 0.55], [0.76, 0]])
	_pk(m, "leap", [[0, 0], [0.2, 1], [0.9, 1], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.16, 0.1], [0.58, 0.12], [0.7, -0.14], [0.92, -0.1], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.6, 0.6], [0.7, 1.2], [0.94, 1.2], [1, 0]])
	_moves["patch"] = m

	m = {"dur": 8.4, "argon": true, "fx": [[0.12, "installStart"], [0.67, "install"], [0.93, "installDone"]]}
	_both(m, [[0, "guard"], [0.14, "wide"], [0.3, "skySpread"], [0.6, "skySpread"], [0.66, "cross"], [0.7, "wide"], [0.92, "wide"], [1, "guard"]])
	_pk(m, "leap", [[0.04, 0], [0.2, 5], [0.92, 5], [1, 0]])
	_pk(m, "sig", [[0.1, 0], [0.3, 1], [0.66, 1], [0.72, 0]])
	_pk(m, "prog", [[0.18, 0], [0.64, 1]])
	_pk(m, "core", [[0.3, 0], [0.66, 3.2], [0.69, 0]])
	_pk(m, "sn", [[0.68, 0], [0.92, 1]])
	_pk(m, "white", [[0.66, 0], [0.69, 1], [0.74, 0]])
	_pk(m, "orb", [[0.1, 0], [0.3, 1], [0.9, 1], [1, 0]])
	_pk(m, "shield", [[0.1, 0], [0.3, 0.4], [0.9, 0.4], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.3, -0.18], [0.6, -0.22], [0.66, 0.22], [0.9, 0], [1, 0]])
	_pk(m, "wide", [[0, 0], [0.24, 1.6], [0.65, 1.4], [0.7, 2], [0.95, 2], [1, 0]])
	for i in 18:
		m["fx"].append([0.3 + i * 0.019, "absorb"])
	_moves["install"] = m

	# UNITED WAVE: the other heroes' shadows stand up behind Gemini, feed it, and it leaves as one wave.
	m = {"dur": 10.0, "argon": true, "fx": [[0.01, "linkStart"], [0.25, "linked"], [0.53, "unite"], [0.72, "surge"], [0.93, "unityDone"]]}
	_both(m, [[0, "guard"], [0.07, "wide"], [0.22, "cross"], [0.5, "cross"], [0.53, "cast"], [0.93, "cast"], [1, "guard"]])
	_pk(m, "leap", [[0, 0], [0.08, 1.2], [0.95, 1.2], [1, 0]])
	_pk(m, "dom", [[0.03, 0], [0.16, 1], [0.96, 1], [1, 0]])
	_pk(m, "lean", [[0, 0], [0.22, -0.1], [0.5, -0.16], [0.54, 0.16], [0.7, 0.1], [0.72, 0.24], [0.93, 0.14], [1, 0]])
	_pk(m, "core", [[0.22, 0], [0.5, 1.4], [0.53, 0.4], [0.93, 0.4], [1, 0]])
	_pk(m, "white", [[0.5, 0], [0.52, 0.22], [0.58, 0], [0.705, 0], [0.72, 0.18], [0.76, 0]])
	_pk(m, "wide", [[0, 0], [0.1, 1.3], [0.24, 1.3], [0.5, 0.45], [0.54, 1.8], [0.7, 1.8], [0.73, 2.3], [0.94, 2.1], [1, 0]])
	_pk(m, "gh", [[0, 0], [0.21, 1], [0.93, 1], [1, 0]])
	# The page watches from the side; here the camera swings partway round, so the wave crosses the screen.
	_pk(m, "camTurn", [[0.02, 0], [0.2, 0.6], [0.93, 0.6], [1, 0]])
	_pk(m, "tie", [[0.21, 0], [0.26, 1], [0.5, 1], [0.54, 1.6], [0.7, 1.4], [0.72, 2.4], [0.9, 1.6], [0.94, 0]])
	_pk(m, "ball", [[0.22, 0], [0.5, 1.7], [0.52, 0.25], [0.9, 0.3], [0.94, 0]])
	_pk(m, "chg", [[0.24, 0], [0.5, 1], [0.525, 0]])
	_pk(m, "flare", [[0.7, 0], [0.72, 1], [0.9, 0.6], [0.95, 0]])
	_pk(m, "kw", [[0.52, 0], [0.56, 1], [0.97, 1]])
	_pk(m, "kwP", [[0.52, 0], [0.54, 1.5], [0.7, 1.2], [0.72, 1.7], [0.9, 1.5], [0.96, 0]])
	_pk(m, "kwR", [[0, 1], [0.52, 0.4], [0.56, 1], [0.7, 1], [0.73, 1.9], [0.9, 2.1], [0.96, 1.2]])
	for i in 4:
		m["fx"].append([0.05 + i * 0.04, "ghostIn", i])
	for i in 20:
		m["fx"].append([0.26 + i * 0.012, "feed"])
	for k in 9:
		m["fx"].append([0.26 + 0.24 * (1.0 - pow(1.0 - (k + 1) / 9.0, 1.7)), "pulse", k])
	for i in 24:
		m["fx"].append([(0.54 + i * 0.016) if i < 10 else (0.73 + (i - 10) * 0.012), "waveRing", i])
	m["fx"].sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	_moves["unity"] = m


## The same moves as keyframes for PoseRig, under the action names "m_<power>".
static func actions() -> Dictionary:
	var out := {}
	var moves := all()
	for id: String in moves:
		var keys := []
		for i in SAMPLES + 1:
			var q := float(i) / SAMPLES
			keys.append([q, _pose(moves[id], q)])
		out["m_" + id] = keys
	return out


static func _pose(m: Dictionary, q: float) -> Dictionary:
	var guard: Array = POSES["guard"]
	var pose := {}
	for side: int in [1, -1]:
		var s := "L" if side > 0 else "R"
		var v := []
		for i in 5:
			v.append(guard[i] + channel(m, s + "xyzfr"[i], q))
		pose["arm" + s] = Vector3(v[0], side * v[1], side * v[2])
		pose["fore" + s] = Vector3(v[3], side * v[4], 0.0)
	pose["upper"] = Vector3(0.02 + channel(m, "lean", q), -0.05 + channel(m, "twist", q), 0.0)
	pose["root"] = Vector3(channel(m, "rootX", q), 0.0, 0.0)
	pose["lift"] = Vector3(0.0, channel(m, "leap", q) * LIFT_PER_LEAP, 0.0)
	var drop := maxf(channel(m, "drop", q), 0.0)
	if m.has("drop"):
		var bend := acos(clampf(1.0 - drop / LEG_LENGTH, -1.0, 1.0))
		var kick := channel(m, "kx", q)
		pose["legL"] = Vector3(-bend, 0.0, -0.06)
		pose["shinL"] = Vector3(bend * 2.0, 0.0, 0.0)
		pose["legR"] = Vector3(-bend + kick, 0.0, 0.06)
		pose["shinR"] = Vector3(bend * 2.0 * (1.0 - minf(1.0, -kick)) + channel(m, "ks", q), 0.0, 0.0)
	return pose
