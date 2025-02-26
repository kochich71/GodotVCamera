@tool
extends Node

class_name VCameraTriggerAction

enum Action {
	NOTHING,
	ENABLE,
	DISABLE,
	SET_PRIORITY,
	ADD_TO_GROUP,
	REMOVE_FROM_GROUP
}

var target_vcamera : NodePath
var filter_objects_by_group : String

var on_enter_action : int = Action.ENABLE: set = set_on_enter_action
func set_on_enter_action(value : int) -> void:
	on_enter_action = value
	notify_property_list_changed()

var on_enter_priority : int = 0
var on_enter_group : String = ""

var on_exit_action : int = Action.DISABLE: set = set_on_exit_action
func set_on_exit_action(value : int) -> void:
	on_exit_action = value
	notify_property_list_changed()

var on_exit_priority : int = 0
var on_exit_group : String = ""

var _overlapping_count : int = 0: set = _set_overlapping_count

func _ready() -> void:
	if get_parent() is Area3D and not Engine.is_editor_hint():
		get_parent().connect("area_entered", Callable(self, "_on_entered"))
		get_parent().connect("body_entered", Callable(self, "_on_entered"))
		get_parent().connect("area_exited", Callable(self, "_on_exited"))
		get_parent().connect("body_exited", Callable(self, "_on_exited"))

func _on_entered(area) -> void:
	if filter_objects_by_group and not area.is_in_group(filter_objects_by_group):
		return
	self._overlapping_count += 1

func _on_exited(area) -> void:
	if filter_objects_by_group and not area.is_in_group(filter_objects_by_group):
		return
	self._overlapping_count -= 1

func _set_overlapping_count(value : int):
	if _overlapping_count == 0 and value > 0:
		execute(on_enter_action, on_enter_priority, on_enter_group)
	elif _overlapping_count > 0 and value == 0:
		execute(on_exit_action, on_exit_priority, on_exit_group)
	
	_overlapping_count = value

func execute(action : int, priority : int, group : String) -> void:
	var vcamera : VCamera = get_node_or_null(self.target_vcamera) as VCamera
	if vcamera:
		match action:
			Action.ENABLE:
				vcamera.enabled = true
			Action.DISABLE:
				vcamera.enabled = false
			Action.SET_PRIORITY:
				vcamera.priority = priority
			Action.ADD_TO_GROUP:
				vcamera.add_to_group(group)
			Action.REMOVE_FROM_GROUP:
				vcamera.remove_from_group(group)

func _get_property_list() -> Array:
	var gen := preload("res://addons/virtualcamera/Helpers/PropertyListGenerator.gd").new(self)
	
	gen.append("target_vcamera")
	gen.append("filter_objects_by_group")
	
	gen.append_enum("on_enter_action", Action)
	if on_enter_action == Action.SET_PRIORITY:
		gen.append_number_range("on_enter_priority", 0, 1024)
	if on_enter_action == Action.ADD_TO_GROUP or on_enter_action == Action.REMOVE_FROM_GROUP:
		gen.append("on_enter_group")
	
	gen.append_enum("on_exit_action", Action)
	if on_exit_action == Action.SET_PRIORITY:
		gen.append_number_range("on_exit_priority", 0, 1024)
	if on_exit_action == Action.ADD_TO_GROUP or on_exit_action == Action.REMOVE_FROM_GROUP:
		gen.append("on_exit_group")
	
	return gen.properties

func _get_configuration_warnings():
	if get_parent() is Area3D:
		return ""
	else:
		return "VCameraTriggerAction has to be child of Area3D to be usable.\n\nAction choosen on enter will be executed when first area/body enters parent Area3D.\nAction choosen on exit will be executed when last area/body leaves parent Area3D."
