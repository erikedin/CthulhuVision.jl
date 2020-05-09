using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering
using CthulhuVision.Camera
using CthulhuVision.Spheres
using CthulhuVision.Scenes
using CthulhuVision.Shapes
using CthulhuVision.Random

################
# Define image #
################

width = 256
height = 256
image = PPM(Dimension(width, height))

####################
# Define materials #
####################

red = lambertian(RGB(0.9f0, 0.1f0, 0.1f0))
green = lambertian(RGB(0.1f0, 0.9f0, 0.1f0))
blue = lambertian(RGB(0.1f0, 0.1f0, 0.9f0))
shiny = metal(RGB(0.7f0, 0.6f0, 0.5f0))
grey  = lambertian(RGB(0.5f0, 0.5f0, 0.5f0))
light = dielectric(1.0f0; emission = RGB(1.0f0, 1.0f0, 1.0f0))

#################
# SceneSettings #
#################

ambientemission = RGB(0.8f0, 0.8f0, 0.8f0)
settings = SceneSettings(ambientemission)

##########
# Camera #
##########

aspect = Float32(image.dimension.width / image.dimension.height)
vfov = 40.0f0

lookfrom = Vec3(277.5f0, 277.5f0, 800.0f0)
lookat = Vec3(277.5f0, 277.5f0, 0.0f0)
vup = Vec3(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.0f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

###################
# Construct scene #
###################

coordinatemarkers = group([
    Sphere(Vec3(  0f0, 0f0, -1f0), 11f0, grey),
    Sphere(Vec3( 40f0, 0f0, -1f0), 11f0, red),
    Sphere(Vec3( 80f0, 0f0, -1f0), 11f0, green),
    Sphere(Vec3(120f0, 0f0, -1f0), 11f0, blue),

    Sphere(Vec3(0f0,  40f0, -1f0), 11f0, red),
    Sphere(Vec3(0f0,  80f0, -1f0), 11f0, green),
    Sphere(Vec3(0f0, 120f0, -1f0), 11f0, blue),
])

redwallmarkers = group(Vector{Sphere}(
    [
        Sphere(Vec3(277.5f0, 277.5f0, 0f0), 10f0, green),
        Sphere(Vec3(0f0, 0f0, 0f0), 10f0, blue),
        Sphere(Vec3(555f0, 0f0, 0f0), 10f0, blue),
        Sphere(Vec3(0f0, 555f0, 0f0), 10f0, blue),
        Sphere(Vec3(555f0, 555f0, 0f0), 10f0, blue),
    ]
))

redwall = uniformwall(555f0, 555f0, 1000, red)
# redtransform = translation(555f0, 0f0, 0f0) *rotation(Float32(-π / 2f0), Vec3(0f0, 1f0, 0f0)) 
redtransform = translation(0f0, 0f0, 0f0) * rotation(Float32(-π / 2f0), Vec3(0f0, 1f0, 0f0)) 
redwallnode = transform([redwall, redwallmarkers], redtransform)

rootnode = group([
    coordinatemarkers,
    redwallnode,
])

scene = Scene(rootnode, settings)

##################
# Perform render #
##################

render(image, camera, scene)

saveimage(image, examplefilename("cornellbox"))

