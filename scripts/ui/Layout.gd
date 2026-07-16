class_name Layout
extends RefCounted

# ============================================================================
# Responsive layout helper.
#
# The project renders at a 1206x2622 base (iPhone 17 Pro native) with stretch mode "canvas_items" +
# aspect "expand": the constrained axis keeps the base size, the other axis
# shows MORE canvas units than the base. So absolute coordinates drift on any
# aspect ratio other than 9:16. This helper converts the real visible area and
# the device safe-area (notches / home indicator) into canvas units, and gives
# screens a centered content column to lay out against instead of hardcoded X/Y.
# ============================================================================

const BASE_WIDTH := 1206.0
const BASE_HEIGHT := 2622.0
const BASE_SIZE := Vector2(BASE_WIDTH, BASE_HEIGHT)

# Max width of the readable content column; on very wide viewports (tablets)
# content stays this wide and centered rather than stretching edge to edge.
# Mockup values (iPhone 17 Pro export): content column 1072 with 67px margins.
const MAX_CONTENT_WIDTH := 1072.0
const SIDE_MARGIN := 67.0
const SAFE_PAD := 24.0

# Convert the drawable viewport size to the logical canvas exposed by
# `canvas_items + expand`. Viewport.get_visible_rect() reports framebuffer
# coordinates; using it directly makes a wide window look narrower than the
# canvas and shifts every supposedly centered screen to the left.
static func expanded_canvas_size(drawable_size: Vector2) -> Vector2:
	if drawable_size.x <= 0.0 or drawable_size.y <= 0.0:
		return BASE_SIZE
	var stretch_scale := minf(drawable_size.x / BASE_WIDTH, drawable_size.y / BASE_HEIGHT)
	if stretch_scale <= 0.0:
		return BASE_SIZE
	return drawable_size / stretch_scale

# Visible viewport size in logical canvas units (>= BASE on the expanded axis).
static func viewport_size(node: Node) -> Vector2:
	var vp := node.get_viewport()
	if vp == null:
		return BASE_SIZE
	return expanded_canvas_size(vp.get_visible_rect().size)

# A rebuild must detach its previous visual tree immediately. `queue_free()`
# alone leaves old and new controls visible together until the end of the frame,
# which produces one-frame seams/duplicates during continuous window resizing.
static func clear_children_for_rebuild(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

static func viewport_center(node: Node) -> Vector2:
	return viewport_size(node) * 0.5

# Canvas units per physical pixel (uniform under aspect "expand").
static func canvas_scale(node: Node) -> float:
	var win := DisplayServer.window_get_size()
	if win.x <= 0:
		return 1.0
	return viewport_size(node).x / float(win.x)

# Safe-area insets in canvas units: {top,bottom,left,right}.
static func safe_insets(node: Node) -> Dictionary:
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	var sa := DisplayServer.get_display_safe_area()
	# Some platforms report an empty safe area; treat it as "no insets".
	if sa.size.x <= 0 or sa.size.y <= 0:
		return {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	var scale := canvas_scale(node)
	return {
		"top": maxf(0.0, float(sa.position.y)) * scale,
		"left": maxf(0.0, float(sa.position.x)) * scale,
		"right": maxf(0.0, float(win.x - (sa.position.x + sa.size.x))) * scale,
		"bottom": maxf(0.0, float(win.y - (sa.position.y + sa.size.y))) * scale,
	}

# Y where top content should begin (below the notch / status bar). Default
# matches the iPhone 17 Pro mockup's reserved top safe area (186px).
static func content_top(node: Node, base_margin: float = 186.0) -> float:
	return maxf(base_margin, float(safe_insets(node)["top"]) + SAFE_PAD)

# Y of the bottom edge available for content (above the home indicator).
# Default matches the mockup's reserved bottom safe area (91px).
static func content_bottom(node: Node, base_margin: float = 91.0) -> float:
	var vp := viewport_size(node)
	return vp.y - maxf(base_margin, float(safe_insets(node)["bottom"]) + SAFE_PAD)

# Gap from content_bottom up to the operator-chips bottom (game screen).
const BOTTOM_LINE_GAP := 134.0

# The unified bottom content line = the operator-chips bottom edge. Every screen
# aligns its lowest element to this so the bottom border is identical (and it
# stays device-adaptive because it's derived from the safe-area content_bottom).
static func content_bottom_line(node: Node, base_margin: float = 91.0) -> float:
	return content_bottom(node, base_margin) - BOTTOM_LINE_GAP

# Centered content column as a Rect2 (in canvas units) between the side safe
# insets, capped at MAX_CONTENT_WIDTH.
static func content_column(node: Node, max_width: float = MAX_CONTENT_WIDTH) -> Rect2:
	var vp := viewport_size(node)
	var insets := safe_insets(node)
	var avail := vp.x - maxf(SIDE_MARGIN, float(insets["left"])) - maxf(SIDE_MARGIN, float(insets["right"]))
	var width := minf(avail, max_width)
	var x := (vp.x - width) * 0.5
	return Rect2(x, content_top(node), width, content_bottom(node) - content_top(node))

# Left X of the centered content column of a given width.
static func column_left(node: Node, width: float) -> float:
	return (viewport_size(node).x - width) * 0.5

# Horizontal center of the viewport (canvas units).
static func center_x(node: Node) -> float:
	return viewport_size(node).x * 0.5
