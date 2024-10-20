extends RigidBody3D

var speed = 40.0
var damage = 1


func _ready():
	linear_velocity = transform.basis * Vector3(0,0, -speed)



func _on_body_entered(body):
	if body.get("zombie_health"):
		body.takeDamage(damage)
		print("in body")
		queue_free()


func _on_timer_timeout():
	if !is_queued_for_deletion():
		queue_free()
