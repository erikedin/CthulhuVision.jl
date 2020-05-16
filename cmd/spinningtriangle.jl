using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering
using CthulhuVision.Camera
using CthulhuVision.Triangles
using CthulhuVision.Scenes
using CthulhuVision.Random

################
# Define image #
################

width = 512
height = 512
image = PPM(Dimension(width, height))

#################
# SceneSettings #
#################

ambientemission = RGB(0.0f0, 0.0f0, 0.0f0)
settings = SceneSettings(ambientemission)

##########
# Camera #
##########

aspect = Float32(image.dimension.width / image.dimension.height)
vfov = 40.0f0

lookfrom = Vector(277.5f0, 277.5f0, 800.0f0)
lookat = Vector(277.5f0, 277.5f0, 0.0f0)
vup = Vector(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.0f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

###################
# Construct scene #
###################

function constructscene(angle::Float32) :: AbstractVector{Triangle}
    r = rotation(angle, Vector(1f0, 0f0, 0f0))

    triangle = Triangle(Point(3f0, 0f0, 0f0), Point(5f0, 4f0, 0f0), Point(2f0, 3f0, 0f0))

    t = transform(triangle, r)

    Scene([t], settings)
end

##################
# Perform render #
##################

rendersettings = RenderSettings(10)

for frame = 0:99
    scene = constructscene(frame)
    render(image, camera, scene, rendersettings)
    framestr = lpad(frame, 4, '0')
    saveimage(image, examplefilename("spinningtriangle_$(framestr)"))
end