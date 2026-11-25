"""Render preview images of galaxy_dragon.blend headless.

    blender -b galaxy_dragon.blend --python render_previews.py [-- view ...]
"""
import bpy, os, sys, math
from mathutils import Vector as Vec

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'renders'); os.makedirs(OUT, exist_ok=True)
VIEWS = {  # camera location, look-at (Blender z-up, dragon faces -Y)
    'front': ((0, -62, 11), (0, 0, 10.5)),
    'back': ((0, 62, 11), (0, 0, 10.5)),
    'side': ((62, 0, 11), (0, 0, 10.5)),
    'iso': ((36, -46, 20), (0, -2, 10.5)),
    'head': ((9, -12, 19), (0, -1, 17.5)),
    'face': ((3.2, -9.5, 18.4), (0, -1.4, 17.8)),
}
want = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else list(VIEWS)
scene = bpy.context.scene
scene.render.resolution_x, scene.render.resolution_y = int(os.environ.get('GD_W', 1280)), int(os.environ.get('GD_H', 960))
scene.render.image_settings.file_format = 'PNG'
cam = scene.camera
try:  # bloom-like glare in the compositor (API differs between versions; skip quietly if it does)
    tree = bpy.data.node_groups.new('GD_Comp', 'CompositorNodeTree')
    tree.interface.new_socket('Image', in_out='OUTPUT', socket_type='NodeSocketColor')
    rl = tree.nodes.new('CompositorNodeRLayers'); gl = tree.nodes.new('CompositorNodeGlare'); go = tree.nodes.new('NodeGroupOutput')
    for name, val in (('Type', 'Bloom'), ('Quality', 'High'), ('Threshold', 1.0), ('Strength', .5), ('Size', .6)):
        if name in gl.inputs:
            try: gl.inputs[name].default_value = val
            except Exception as e: print('glare input', name, e)
    tree.links.new(rl.outputs['Image'], gl.inputs['Image']); tree.links.new(gl.outputs['Image'], go.inputs[0])
    scene.compositing_node_group = tree; scene.render.use_compositing = True
except Exception as e:
    print('glare skipped:', e)
for v in want:
    loc, tgt = VIEWS[v]
    cam.location = loc; cam.rotation_euler = (Vec(tgt) - Vec(loc)).to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 50 if v != 'head' else 45
    scene.render.filepath = os.path.join(OUT, f'galaxy_dragon_{v}.png')
    bpy.ops.render.render(write_still=True)
    print('rendered', v); sys.stdout.flush()
