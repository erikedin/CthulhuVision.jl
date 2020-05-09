module Image

export Dimension, Pixel, PPM, saveimage, pixel, examplefilename
export dimension4K

using Dates
using CthulhuVision.Light

struct Dimension
    width::Int
    height::Int
end

dimension4K() = Dimension(3840, 2160)

struct Pixel
    x::Int
    y::Int
end

struct PPM
    dimension::Dimension
    pixels::Dict{Pixel, RGB}

    PPM(dimension::Dimension) = new(dimension, Dict{Pixel, RGB}())
end

pixel(image::PPM, px::Pixel, rgb::RGB) = image.pixels[px] = rgb

function saveimage(image::PPM, filename::String)
    open(filename, "w") do io
        write(io, "P3\n")
        write(io, "$(image.dimension.width) $(image.dimension.height)\n")
        write(io, "255\n")

        for y = image.dimension.height - 1:-1:0
            for x = 0:image.dimension.width - 1
                rgb = image.pixels[Pixel(x, y)]
                r = trunc(Int, 255.99f0*sqrt(rgb.r))
                g = trunc(Int, 255.99f0*sqrt(rgb.g))
                b = trunc(Int, 255.99f0*sqrt(rgb.b))
                write(io, "$r $g $b\n")
            end
        end
    end
end

function examplefilename(name::AbstractString) :: String
    date = Dates.format(now(), "yyyymmdd-HHMMSS")
    "example$(name)-$(date).ppm"
end

end