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
white = lambertian(RGB(1.0f0, 1.0f0, 1.0f0))
light = lambertian(RGB(1f0, 1f0, 1f0); emission = RGB(10f0, 10f0, 10f0))

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

lookfrom = Vector3(0f0, 0f0, 800.0f0)
lookat = Vector3(0f0, 0f0, 0.0f0)
vup = Vector3(0.0f0, 1.0f0, 0.0f0)
focusdist = 10.0f0
aperture = 0.0f0

camera = FovCamera(lookfrom, lookat, vup, vfov, aspect, aperture, focusdist)

###################
# Construct scene #
###################

function constructscene() :: Scene
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

    shortmesh = Mesh(
        # Vertexes
        [
            # Front vertexes
            Vector3(-82.5f0, -82.5f0, 82.5f0),
            Vector3( 82.5f0, -82.5f0, 82.5f0),
            Vector3( 82.5f0,  82.5f0, 82.5f0),
            Vector3(-82.5f0,  82.5f0, 82.5f0),

            # Back vertexes
            Vector3(-82.5f0, -82.5f0, -82.5f0),
            Vector3( 82.5f0, -82.5f0, -82.5f0),
            Vector3( 82.5f0,  82.5f0, -82.5f0),
            Vector3(-82.5f0,  82.5f0, -82.5f0),
        ],

        # Triangles
        [
            # Front face
            MeshTriangle(1, 2, 4),
            MeshTriangle(2, 3, 4),

            # Back face
            MeshTriangle(6, 5, 7),
            MeshTriangle(5, 8, 7),

            # Left face
            MeshTriangle(5, 1, 8),
            MeshTriangle(1, 4, 8),

            # Right face
            MeshTriangle(2, 6, 3),
            MeshTriangle(6, 7, 3),

            # Top face
            MeshTriangle(4, 3, 8),
            MeshTriangle(3, 7, 8),

            # Bottom face
            MeshTriangle(5, 6, 1),
            MeshTriangle(6, 2, 1),
        ]
    )
    shortmeshindex = addmesh!(scene, shortmesh)

    lightmesh = Mesh(
        # Vertexes
        [
            Vector3(-65f0, -52.5f0, 0f0),
            Vector3( 65f0, -52.5f0, 0f0),
            Vector3( 65f0,  52.5f0, 0f0),
            Vector3(-65f0,  52.5f0, 0f0),
        ],
    
        # Triangles
        [
            MeshTriangle(1, 2, 4),
            MeshTriangle(2, 3, 4),
        ]
    )
    lightmeshindex = addmesh!(scene, lightmesh)

    # Back wall
    addinstance!(
        scene,
        MeshInstance(
            wallmeshindex,
            white,
            translation(Vector3(0f0, 0f0, -555f0)),
        )
    )

    # Bottom
    addinstance!(
        scene,
        MeshInstance(
            wallmeshindex,
            white,
            translation(Vector3(0f0, -277.5f0, -277.5f0)) * rotation(-Float32(π) / 2f0, Vector3(1f0, 0f0, 0f0)),
        )
    )

    # Top
    addinstance!(
        scene,
        MeshInstance(
            wallmeshindex,
            white,
            translation(Vector3(0f0,  277.5f0, -277.5f0)) * rotation(Float32(π) / 2f0, Vector3(1f0, 0f0, 0f0)),
        )
    )


    # Left wall
    addinstance!(
        scene,
        MeshInstance(
            wallmeshindex,
            red,
            translation(Vector3(-277.5f0, 0f0, -277.5f0)) * rotation(Float32(π) / 2f0, Vector3(0f0, 1f0, 0f0))
        )
    )

    # Right wall
    addinstance!(
        scene,
        MeshInstance(
            wallmeshindex,
            green,
            translation(Vector3( 277.5f0, 0f0, -277.5f0)) * rotation(-Float32(π) / 2f0, Vector3(0f0, 1f0, 0f0))
        )
    )

    # Short block
    addinstance!(
        scene,
        MeshInstance(
            shortmeshindex,
            white,
            # identitytransform(),
            translation(Vector3(87.5f0, -195f0, -147.5f0)) * rotation(-Float32(2.0 * π) * 0.05f0, Vector3(0f0, 1f0, 0f0)),
        )
    )

    # Tall block
    addinstance!(
        scene,
        MeshInstance(
            shortmeshindex,
            white,
            # identitytransform(),
            translation(Vector3(-97.5f0, -112.5f0, -347.5f0)) * rotation(Float32(2.0 * π) * 0.041667f0, Vector3(0f0, 1f0, 0f0)) * scale(Vector3(1f0, 2f0, 1f0)),
        )
    )

    # Light
    addinstance!(
        scene,
        MeshInstance(
            lightmeshindex,
            light,
            translation(Vector3(0f0,  277.4f0, -277.5f0)) * rotation(Float32(π) / 2f0, Vector3(1f0, 0f0, 0f0)),
        )
    )

    scene
end

##################
# Perform render #
##################

scene = constructscene()
rendersettings = RenderSettings(20000)

render(image, camera, scene, rendersettings)

saveimage(image, examplefilename("cornellbox"))