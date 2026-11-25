"""Pose the rig into a test stance and render it, to check the automatic weights.

    blender -b galaxy_dragon.blend --python pose_test.py
"""
import bpy, os, math
from mathutils import Matrix, Vector as Vec

arm = bpy.data.objects['GD_Rig']
def turn(bone, axis, deg):
    """Rotate a pose bone about a world (Blender) axis through its head."""
    pb = arm.pose.bones[bone]
    bpy.context.view_layer.update()
    head = arm.matrix_world @ pb.head
    R = Matrix.Translation(head) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-head)
    pb.matrix = arm.matrix_world.inverted() @ R @ arm.matrix_world @ pb.matrix
    bpy.context.view_layer.update()

turn('shoulderL', 'Y', -110)   # left arm raised (dragon's left is +X)
turn('elbowL', 'Y', -30)
turn('shoulderR', 'X', -60)    # right arm reaching forward
turn('head', 'X', 25)          # look up
turn('jaw', 'X', -20)
turn('wingL', 'Z', -50)        # left wing swept forward
for i in range(5): turn(f'wingF{i}L', 'Y', -8 * i)   # and partly folded
turn('wingR', 'Y', 25)         # right wing raised
for k in range(3, 10): turn(f'tail{k}', 'Z', 9)
turn('thighR', 'X', -35); turn('shinR', 'X', 50)

scene = bpy.context.scene
scene.render.resolution_x, scene.render.resolution_y = 960, 720
cam = scene.camera; cam.location = (40, -46, 18)
cam.rotation_euler = (Vec((0, -2, 11)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
scene.render.filepath = os.path.join(os.path.dirname(bpy.data.filepath), 'renders', 'galaxy_dragon_posetest.png')
bpy.ops.render.render(write_still=True)
print('rendered posetest')
