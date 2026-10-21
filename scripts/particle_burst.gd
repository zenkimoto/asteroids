class_name ParticleBurst
extends GPUParticles2D
## A one-shot GPU particle burst that frees itself when its particles are gone.
## Particles live in world space and glow additively; the node's modulate tints them.

const TEXTURE_SIZE: int = 32
## Seconds after the particles' lifetime before the node is freed.
const CLEANUP_MARGIN: float = 0.1

static var _dot_texture: Texture2D
static var _additive_material: CanvasItemMaterial


## Creates a burst at `at`, tinted `color` and scaled by `size`, with particle
## count scaled by `intensity` (0-1). Add it to the tree to start it.
static func create(settings: ParticleBurstSettings, at: Vector2, color: Color, size: float = 1.0,
		intensity: float = 1.0, angle: float = 0.0) -> ParticleBurst:
	var burst := ParticleBurst.new()
	burst.position = at
	burst.rotation = angle
	burst.scale = Vector2.ONE * size
	burst.modulate = color
	burst.amount = settings.get_amount(intensity)
	burst.lifetime = settings.lifetime
	burst.explosiveness = settings.explosiveness
	burst.one_shot = true
	burst.local_coords = false
	burst.process_material = settings.get_material()
	burst.texture = get_dot_texture()
	burst.material = get_additive_material()
	burst.visibility_rect = Rect2(-600.0, -600.0, 1200.0, 1200.0)
	burst.emitting = true
	return burst


## Soft round dot shared by every particle effect.
static func get_dot_texture() -> Texture2D:
	if _dot_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.35, Color(1, 1, 1, 0.8))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = TEXTURE_SIZE
		texture.height = TEXTURE_SIZE
		_dot_texture = texture
	return _dot_texture


static func get_additive_material() -> CanvasItemMaterial:
	if _additive_material == null:
		_additive_material = CanvasItemMaterial.new()
		_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive_material


func _ready() -> void:
	# `finished` is not emitted reliably for bursts started before entering the
	# tree, so the burst also frees itself once its last particle has expired.
	# The timer pauses with the game, like the particles.
	finished.connect(queue_free)
	get_tree().create_timer(lifetime / speed_scale + CLEANUP_MARGIN, false).timeout.connect(queue_free)
