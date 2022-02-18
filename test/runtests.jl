module GLibTestModule
using Test, Gtk4.GLib

@testset "GLib" begin
include("keyfile.jl")
include("date.jl")
include("datetime.jl")
include("bytes.jl")
#include("gstring.jl")
include("mainloop.jl")
include("list.jl")

include("gvalue.jl")
#include("gbinding.jl")

#include("gfile.jl")
include("gmenu.jl")
include("action-group.jl")
end

@testset "Pango" begin
include("families.jl")
include("layout.jl")
end

GC.gc()

sleep(2)

end
