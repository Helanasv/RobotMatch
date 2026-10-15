extends RefCounted

signal changed

const TileScript := preload("res://scripts/Tile.gd")

const MAX_HP := 100
const GEAR_DAMAGE := 5
const CRYSTAL_DAMAGE := 10
const BOLT_HEAL := 4
const BATTERY_CHARGE := 25
const STRIKE_DAMAGE := 15

var hp := MAX_HP
var phase := 1
var shield := true
var charge := 0
var charge_max := 100
var battery_charge := BATTERY_CHARGE
var strike_damage := STRIKE_DAMAGE
var defeated := false


func configure(max_charge: int, battery: int, strike: int) -> void:
	charge_max = maxi(max_charge, 1)
	battery_charge = maxi(battery, 1)
	strike_damage = maxi(strike, 1)


func apply_tiles(tiles: Array) -> void:
	if defeated:
		return
	var gears := 0
	var crystals := 0
	var microchips := 0
	var batteries := 0
	var bolts := 0
	for tile in tiles:
		if not is_instance_valid(tile):
			continue
		match tile.tile_type:
			TileScript.Type.GEAR:
				gears += 1
			TileScript.Type.ENERGY_CRYSTAL:
				crystals += 1
			TileScript.Type.MICROCHIP:
				microchips += 1
			TileScript.Type.BATTERY:
				batteries += 1
			TileScript.Type.BOLT:
				bolts += 1
	if microchips > 0:
		shield = false
	var damage := gears * GEAR_DAMAGE + crystals * CRYSTAL_DAMAGE
	if shield:
		damage = int(damage / 2)
	_hurt(damage)
	if defeated:
		changed.emit()
		return
	charge += batteries * battery_charge
	while charge >= charge_max and not defeated:
		charge -= charge_max
		_hurt(strike_damage)
	if defeated:
		changed.emit()
		return
	if bolts > 0:
		hp = mini(MAX_HP, hp + bolts * BOLT_HEAL)
	var next_phase := 1
	if hp <= 33:
		next_phase = 3
	elif hp <= 66:
		next_phase = 2
	if next_phase > phase:
		phase = next_phase
		shield = true
	changed.emit()


func _hurt(amount: int) -> void:
	if amount <= 0 or defeated:
		return
	hp -= amount
	if hp <= 0:
		hp = 0
		defeated = true
