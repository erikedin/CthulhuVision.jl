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

width = 512
height = 512
image = PPM(Dimension(width, height))

####################
# Define materials #
####################

red = lambertian(RGB(0.9f0, 0.1f0, 0.1f0))
green = lambertian(RGB(0.1f0, 0.9f0, 0.1f0))
blue = lambertian(RGB(0.1f0, 0.1f0, 0.9f0))
white = lambertian(RGB(1.0f0, 1.0f0, 1.0f0))
shiny = metal(RGB(0.7f0, 0.6f0, 0.5f0))
grey  = lambertian(RGB(0.5f0, 0.5f0, 0.5f0))
light = lambertian(RGB(1f0, 1f0, 1f0); emission = RGB(1.0f0, 1.0f0, 1.0f0))

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

lookfrom = Vec3(277.5f0, 277.5f0, 800.0f0)
lookat = Vec3(277.5f0, 277.5f0, 0.0f0)
vup = Vec3(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.0f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

###################
# Construct scene #
###################

redwall = uniformwall(555f0, 555f0, 1000, red)
redtransform = translation(0f0, 0f0, 0f0) * rotation(Float32(π / 2f0), Vec3(0f0, 1f0, 0f0)) 
redwallnode = transform([redwall], redtransform)

greenwall = uniformwall(555f0, 555f0, 1000, green)
greentransform = translation(555f0, 0f0, 0f0) * rotation(Float32(π / 2f0), Vec3(0f0, 1f0, 0f0)) 
greenwallnode = transform([greenwall], greentransform)

whitewall = uniformwall(555f0, 555f0, 1000, white)

toptransform = translation(0f0, 555f0, 0f0) * rotation(Float32(-π / 2f0), Vec3(1f0, 0f0, 0f0))
topwallnode = transform([whitewall], toptransform)

bottomtransform = rotation(Float32(-π / 2f0), Vec3(1f0, 0f0, 0f0))
bottomwallnode = transform([whitewall], bottomtransform)

backtransform = translation(0f0, 0f0, -555f0)
backwallnode = transform([whitewall], backtransform)

lightbox = uniformwall(250f0, 250f0, 1000, light)
lightboxtransform = translation(177f0, 554f0, -177f0) * rotation(Float32(-π / 2f0), Vec3(1f0, 0f0, 0f0))
lightboxnode = transform([lightbox], lightboxtransform)

tallblock = block(165f0, 330f0, 165f0, 100, white)
tallblocktransform = translation(70f0, 0f0, -460f0) * rotation(Float32(0.05 * 2f0 * π), Vec3(0f0, 1f0, 0f0))
tallblocknode = transform([tallblock], tallblocktransform)

shortblock = block(165f0, 165f0, 165f0, 100, white)
shortblocktransform = translation(320f0, 0f0, -260f0) * rotation(Float32(-0.0617f0 * 2f0 * π), Vec3(0f0, 1f0, 0f0))
shortblocknode = transform([shortblock], shortblocktransform)

rootnode = group([
    redwallnode,
    greenwallnode,
    topwallnode,
    bottomwallnode,
    backwallnode,
    lightboxnode,
    tallblocknode,
    shortblocknode,
])

scene = Scene(rootnode, settings)

##################
# Perform render #
##################

render(image, camera, scene)

saveimage(image, examplefilename("cornellbox"))

