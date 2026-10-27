extends RefCounted
# Speaker-relative seat/radius/height rig, adapted from SeleniumSoul's
# DREditor Alpha Scripts/Camera/TrialCamera/DRTrialCamera.cs (CC BY 4.0).
# Rewritten in GDScript: procedural camera tracks replace Unity's Animator.
# See THIRD_PARTY_NOTICES.md for source, authors, license, and changes.
var camera: Camera3D
var target = Vector3.ZERO
var origin_angle = 0.0
var elapsed = 0.0
var duration = 5.0
var preset = "push_in"
var initial = Transform3D.IDENTITY
var initial_fov = 55.0

func set_shot(view: Camera3D, actor: Node3D, track: String, length: float):
    camera = view
    target = actor.global_position + Vector3(0, 1.65, 0)
    origin_angle = atan2(target.x, target.z)
    preset = track
    duration = max(0.1, length)
    elapsed = 0.0
    initial = camera.global_transform
    initial_fov = camera.fov

func step(dt: float):
    if not is_instance_valid(camera): return
    elapsed += dt
    var t = clamp(elapsed / duration, 0.0, 1.0)
    var offset = 0.0
    var distance = 4.8
    var height = 0.35
    var fov = 49.0
    match preset:
        "sweep_left":
            offset = lerp(-0.4, 0.22, t)
            distance = 6.5
            fov = 55.0
        "sweep_right":
            offset = lerp(0.4, -0.22, t)
            distance = 6.5
            fov = 55.0
        "high_angle":
            height = lerp(3.0, 0.6, t)
            distance = 5.5
            offset = -0.18
        "dolly_zoom":
            distance = lerp(3.8, 6.2, t)
            fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(55.0) / 2.0) * 3.8 / distance))
            offset = 0.12
        _:
            distance = lerp(6.0, 3.7, t)
            offset = 0.12
    var inward = -Vector3(sin(origin_angle + offset), 0, cos(origin_angle + offset))
    var position = target + inward * distance + Vector3.UP * height
    var next = Transform3D(Basis.IDENTITY, position).looking_at(target, Vector3.UP)
    # The first half-second connects the previous speaker's shot smoothly.
    var blend = smoothstep(0.0, 0.55, elapsed)
    camera.global_transform = initial.interpolate_with(next, blend)
    camera.fov = lerp(initial_fov, fov, blend)
