using CthulhuVision.Image
using CthulhuVision.Math
using CthulhuVision.Light
using CthulhuVision.Materials
using CthulhuVision.Rendering
using CthulhuVision.Camera
using CthulhuVision.Worlds
using CthulhuVision.Scenes
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
white = lambertian(RGB(0.2f0, 0.8f0, 0.2f0))

#################
# SceneSettings #
#################

ambientemission = RGB(0.5f0, 0.7f0, 1.0f0)
settings = SceneSettings(ambientemission)

##########
# Camera #
##########

aspect = Float32(image.dimension.width / image.dimension.height)
vfov = 40.0f0

lookfrom = Vector3(0f0, 0f0, 800.0f0)
lookat = Vector3(0f0, 0f0, 0.0f0)
vup = Vector3(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.0f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

###################
# Construct scene #
###################

scene = Scene(settings)


wallmesh = Mesh(
    # Vertexes
    [
        Vector3(-277.5f0, -277.5f0, 0f0),
        Vector3( 277.5f0, -277.5f0, 0f0),
        Vector3( 277.5f0,  277.5f0, 0f0),
        Vector3(-277.5f0,  277.5f0, 0f0),
    ],
    
    # Triangles
    [
        MeshTriangle(1, 2, 4),
        MeshTriangle(2, 3, 4),
    ]
)
wallmeshindex = addmesh!(scene, wallmesh)

# This creates a Hitable for each triangle, to be used when building the
# acceleration structure.

# Bottom wall
# addinstance!(
#     scene,
#     MeshInstance(
#         wallmeshindex,
#         blue,
#         translation(Vector3(0f0, -277.5f0, -277.5f0)) * rotation(Float32(π) / 2f0, Vector3(1f0, 0f0, 0f0)),
#     )
# )

# Back wall
addinstance!(
    scene,
    MeshInstance(
        wallmeshindex,
        blue,
        translation(Vector3(0f0, 0f0, -555f0)),
    )
)

# Top wall
# addinstance!(
#     scene,
#     MeshInstance(
#         wallmeshindex,
#         white,
#         translation(Vector3(0f0, 277.5f0, -277.5f0)) * rotation(Float32(π) / 2f0, Vector3(1f0, 0f0, 0f0)),
#     )
# )

# Left wall
addinstance!(
    scene,
    MeshInstance(
        wallmeshindex,
        red,
        translation(Vector3(-300.5f0, -50f0, -10f0)) * rotation(Float32(π) * 0.3f0, Vector3(0f0, 1f0, 0f0)),
        # translation(Vector3(-277.5f0, 0f0, -277.5f0)) * rotation(Float32(π) / 2f0, Vector3(0f0, 1f0, 0f0)),
    )
)

# Right wall
# addinstance!(
#     scene,
#     MeshInstance(
#         wallmeshindex,
#         green,
#         translation(Vector3(277.5f0, 0f0, -277.5f0)) * rotation(Float32(π) / 2f0, Vector3(0f0, 1f0, 0f0)),
#     )
# )

##################
# Perform render #
##################

rendersettings = RenderSettings(10)

render(image, camera, scene, rendersettings)

saveimage(image, examplefilename("cornellbox"))