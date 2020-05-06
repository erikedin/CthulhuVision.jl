using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering
using CthulhuVision.Camera
using CthulhuVision.Spheres
using CthulhuVision.Scenes
using CthulhuVision.Random

################
# Define image #
################

width = 200
height = 100
image = PPM(Dimension(width, height))

####################
# Define materials #
####################

brown = lambertian(RGB(0.4f0, 0.2f0, 0.1f0))
shiny = metal(RGB(0.7f0, 0.6f0, 0.5f0))
grey  = lambertian(RGB(0.5f0, 0.5f0, 0.5f0))
light = dielectric(1.0f0; emission = RGB(1.0f0, 1.0f0, 1.0f0))

#################
# SceneSettings #
#################

ambientemission = RGB(0.02f0, 0.02f0, 0.1f0)
settings = SceneSettings(ambientemission)

##########
# Camera #
##########

aspect = Float32(image.dimension.width / image.dimension.height)
vfov = 20.0f0

lookfrom = Vec3(0.0f0, 4.0f0, -20.0f0)
lookat = Vec3(0.0f0, 1.0f0, 0.0f0)
vup = Vec3(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.1f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

###################
# Construct scene #
###################

# world = Vector{Sphere}([
#     Sphere(Vec3( 0.0f0, -1000.0f0, 0.0f0), 1000.0f0, grey),
#     Sphere(Vec3( 0.0f0,     1.0f0, 0.0f0),    1.0f0, dielectric(1.5f0)),
#     Sphere(Vec3(-4.0f0,     1.0f0, 0.0f0),    1.0f0, brown),
#     Sphere(Vec3( 4.0f0,     1.0f0, 0.0f0),    1.0f0, shiny),
# ])

bigsphere = Sphere(Vec3(0f0, 0f0, 0f0), 1000f0, grey)
node1 = transform([bigsphere], translation(0f0, -1000f0, 0f0))

lightsphere = Sphere(Vec3(0f0, 0f0, 0f0),   50f0, light)
node2 = transform([lightsphere], translation(0f0, 100f0, 0f0))

smallspheres = Vector{Sphere}([
    Sphere(Vec3( 0.0f0,     1.0f0, 0.0f0),    1.0f0, dielectric(1.5f0)),
    Sphere(Vec3(-4.0f0,     1.0f0, 0.0f0),    1.0f0, brown),
    Sphere(Vec3( 4.0f0,     1.0f0, 0.0f0),    1.0f0, shiny),
])
yaxis = Vec3(0f0, 1f0, 0f0)
node3child = transform(smallspheres, rotation(Float32(-π/8f0), yaxis))
node3parent = transform([node3child], translation(0f0, 0f0, 3f0))
#node3parent = transform([node3child], identitytransform())

rootnode = group([node1, node2, node3parent])

scene = Scene(rootnode, settings)

##################
# Perform render #
##################

render(image, camera, scene)

saveimage(image, examplefilename("scene"))

