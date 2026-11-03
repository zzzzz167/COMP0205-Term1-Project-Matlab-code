"""ManimGL warm ivory 3D portrait. Run: uv run python relief_portrait.py"""
from pathlib import Path
import numpy as np
from PIL import Image
import interactive_cycle as mechanism

class MechanicalPortrait(mechanism.InteractiveCycle):
    """Freeze the shared 3D mechanism at 210 degrees for a transparent portrait."""
    presentation_mode = True
    # Skip playback while constructing a single still image.
    def wait(self,*args,**kwargs):
        return self
    def construct(self):
        original=mechanism.PALETTE.copy()
        mechanism.PALETTE.update(primary='#FAF9F6',scissor='#EAD8D0',metal='#CDA49C',
                                 pin='#FAF9F6',ink='#E6C5B8',released='#E6C5B8')
        super().construct()
        self.cycle_clock.clear_updaters()
        self.cycle_clock.set_value(210)
        self.update_mobjects(0)
        self.model_geometry.clear_updaters()
        mechanism.PALETTE.update(original)
        # The two offset scissor layers need distinct values so their crossing
        # remains legible at cover scale even when both face the same light.
        for i in (0,4):
            self.model_geometry[i].set_color('#C9A89E')
        for i in (1,5):
            self.model_geometry[i].set_color('#F0DFD5')
        self.model_geometry.set_shading(.35,.35,.08)
        self.remove(self.wall_guides)
        # A long focal distance gives an almost orthographic engineering view.
        # In the original 45-degree FOV, the upper and lower horizontal clamp
        # frames acquired noticeably different vanishing directions.
        self.frame.reorient(-32, 62).move_to(self.model_geometry.get_center()).set_height(7.7)
        self.frame.set_focal_distance(90)
        self.camera.background_rgba=np.array([0.,0.,0.,0.])

if __name__=='__main__':
    scene=MechanicalPortrait(camera_config={'resolution':(3840,2160)})
    scene.construct()
    scene.camera.capture(scene.model_geometry)
    im=scene.camera.get_image()
    box=im.getchannel('A').getbbox()
    if box is None:raise RuntimeError('Empty rendering')
    im=im.crop(box)
    # GPU stores premultiplied RGB on a transparent canvas. Convert to straight
    # alpha for clean edges when PowerPoint composites the image onto a red slide.
    arr=np.asarray(im).astype(float)
    alpha=arr[:,:,3:4]/255
    arr[:,:,:3]=np.divide(arr[:,:,:3],alpha,out=np.zeros_like(arr[:,:,:3]),where=alpha>0)
    im=Image.fromarray(np.clip(arr,0,255).astype('uint8'),'RGBA')
    out=Image.new('RGBA',(im.width+100,im.height+100),(0,0,0,0))
    out.alpha_composite(im,(50,50))
    path=Path(__file__).resolve().parent/'mechanical_portrait_perspective.png'
    out.save(path)
    print(path.name,out.size)
