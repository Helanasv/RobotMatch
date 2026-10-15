extends RefCounted

const TEXTURE: Texture2D = preload("res://assets/ui/star.svg")


static func fill(parent: Node, count: int, size: float) -> void:
	for child in parent.get_children():
		child.queue_free()
	for _i in count:
		var icon := TextureRect.new()
		icon.texture = TEXTURE
		icon.custom_minimum_size = Vector2(size, size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(icon)
