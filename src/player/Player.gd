extends CharacterBody3D


@onready var head: Node3D = $Head
@onready var photo: MeshInstance3D = $Head/Photo
@onready var photo_sub_viewport: SubViewport = $Head/Camera3D/PhotoSubViewport
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var csg_combiner: CSGCombiner3D = $Head/CSGCombiner3D
@onready var csg_mesh: CSGMesh3D = $Head/CSGCombiner3D/CSGMesh3D
@onready var csg_intersector: CSGMesh3D = $Head/CSGCombiner3D/CSGIntersector
@onready var object_detector: Area3D = $Head/ObjectDetector
@onready var objects_holder: Node3D = $Head/ObjectsHolder


const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENS := 0.2

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mouse_captured := false
var applying := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true


func _input(event: InputEvent) -> void:
	if applying:
		return
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		head.rotation_degrees.x = clampf(head.rotation_degrees.x, -89, 89)
	
	if event.is_action_pressed("photo_capture"):
		photo_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		photo.show()
		animation_player.stop()
		animation_player.play("capture_photo")
		
		for object in objects_holder.get_children():
			object.queue_free()
		
		for object in get_captured_objects():
			var nodes: Array = [object] + object.find_children("*", "", true, false)
			
			var new_object: PhysicsBody3D
			var new_mesh_instance := MeshInstance3D.new()
			var new_collision_shape := CollisionShape3D.new()
			
			var mesh_instance: MeshInstance3D
			var collision_shape: CollisionShape3D
			
			for node in nodes:
				if node is StaticBody3D:
					new_object = StaticBody3D.new()
				if node is RigidBody3D:
					new_object = RigidBody3D.new()
				if node is MeshInstance3D:
					mesh_instance = node
				if node is CollisionShape3D:
					collision_shape = node
			
			if not new_object or not mesh_instance or not collision_shape:
				print("Object Invalid")
				continue
			
			new_object.add_child(new_mesh_instance)
			new_object.add_child(new_collision_shape)
			
			csg_mesh.mesh = mesh_instance.mesh
			csg_intersector.operation = CSGShape3D.OPERATION_INTERSECTION
			csg_combiner.global_transform = mesh_instance.global_transform
			csg_intersector.global_transform = head.global_transform
			csg_combiner.show()
			csg_combiner._update_shape()
			csg_combiner.hide()
			
			var meshes := csg_combiner.get_meshes()
			new_mesh_instance.mesh = meshes[1]
			
			if new_object is StaticBody3D:
				new_collision_shape.shape = new_mesh_instance.mesh.create_trimesh_shape()
			else:
				new_collision_shape.make_convex_from_siblings()
			
			new_object.set_meta("item_root", true)
			
			objects_holder.add_child(new_object)
			new_object.global_transform = object.global_transform
			new_mesh_instance.global_transform = mesh_instance.global_transform
			new_collision_shape.global_transform = collision_shape.global_transform
	
	if event.is_action_pressed("photo_apply") and photo.visible:
		applying = true
		animation_player.play("apply_photo")
		await get_tree().create_timer(2.0).timeout
		photo.hide()
		
		for object in get_captured_objects():
			var nodes: Array = [object] + object.find_children("*", "", true, false)
			
			var is_rigid := false
			var mesh_instance: MeshInstance3D
			var collision_shape: CollisionShape3D
			
			for node in nodes:
				if node is RigidBody3D:
					is_rigid = true
				if node is MeshInstance3D:
					mesh_instance = node
				if node is CollisionShape3D:
					collision_shape = node
			
			if not mesh_instance or not collision_shape:
				print("Object Invalid")
				continue
			
			csg_mesh.mesh = mesh_instance.mesh
			csg_intersector.operation = CSGShape3D.OPERATION_SUBTRACTION
			csg_combiner.global_transform = mesh_instance.global_transform
			csg_intersector.global_transform = head.global_transform
			csg_combiner.show()
			csg_combiner._update_shape()
			csg_combiner.hide()
			
			var meshes := csg_combiner.get_meshes()
			#mesh_instance.global_transform *= meshes[0]
			mesh_instance.mesh = meshes[1]
			
			if is_rigid:
				collision_shape.make_convex_from_siblings()
			else:
				collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
		
		for object in objects_holder.get_children():
			object.reparent(get_parent())
		
		applying = false
	
	if event.is_action_pressed("mouse_mode"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not mouse_captured else Input.MOUSE_MODE_VISIBLE
		mouse_captured = not mouse_captured


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("movement_left", "movement_right", "movement_forward", "movement_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if not applying:
		move_and_slide()


func get_captured_objects() -> Array[Node3D]:
	var objects: Array[Node3D] = []
	
	for object in object_detector.get_overlapping_bodies():
		while not object.scene_file_path and not object.has_meta("item_root"):
			object = object.get_parent()
		objects.append(object)
	
	return objects
