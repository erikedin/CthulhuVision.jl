module Shapes

export uniformwall, block

using CthulhuVision.Spheres
using CthulhuVision.Scenes
using CthulhuVision.Materials
using CthulhuVision.Math

function uniformwall(width::Float32, height::Float32, nspheres::Int, material::Material) :: SceneNode
    densitydimension = max(width, height)
    density = densitydimension / Float32(nspheres)

    radius = density / sqrt(2f0)

    stepwidth = width / Float32(nspheres)
    stepheight = height / Float32(nspheres)

    spheres = Vector{Sphere}([
        Sphere(Vec3(x, y, 0f0), radius, material)
        for x = 0f0:stepwidth:width
        for y = 0f0:stepheight:height
    ])

    group(spheres)
end

function block(width::Float32, height::Float32, depth::Float32, nspheres::Int, material::Material) :: SceneNode
    densitydimension = max(width, height, depth)
    density = densitydimension / Float32(nspheres)

    radius = density / sqrt(2f0)

    stepwidth = width / Float32(nspheres)
    stepheight = height / Float32(nspheres)
    stepdepth = depth / Float32(nspheres)

    spheres = Vector{Sphere}([
        Sphere(Vec3(x, y, z), radius, material)
        for x = 0f0:stepwidth:width
        for y = 0f0:stepheight:height
        for z = 0f0:stepdepth:depth
    ])

    group(spheres)
end

end