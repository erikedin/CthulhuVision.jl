module Shapes

export uniformwall

using CthulhuVision.Spheres
using CthulhuVision.Scenes
using CthulhuVision.Materials
using CthulhuVision.Math

function uniformwall(width::Float32, height::Float32, nspheres::Int, material::Material) :: SceneNode
    densitydimension = max(width, height)
    density = densitydimension / Float32(nspheres)

    radius = density / sqrt(2f0)

    halfwidth = width / 2f0
    stepwidth = width / Float32(nspheres)
    halfheight = height / 2f0
    stepheight = width / Float32(nspheres)

    spheres = Vector{Sphere}([
        Sphere(Vec3(x, y, 0f0), radius, material)
        for x = -halfwidth:stepwidth:halfwidth
        for y = -halfheight:stepheight:halfheight
    ])

    group(spheres)
end

end