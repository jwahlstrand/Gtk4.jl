import Cairo: CairoSurface, CairoContext, CairoARGBSurface

using Cairo_jll

function canvas_draw_backing_store(w, cr, width, height, user_data) # cr is a Cairo context, user_data is a Cairo surface
    user_data==C_NULL && return

    ccall((:cairo_set_source_surface, libcairo), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}, Float64, Float64), cr, user_data, 0, 0)
    ccall((:cairo_paint, libcairo), Nothing, (Ptr{Nothing},), cr)
end

function _init_canvas!(widget, w, h)
    widget.back = CairoARGBSurface(w, h)
    widget.backcc = CairoContext(widget.back)
end

"""
    GtkCanvas(w = -1, h = -1, init_back = false; kwargs...)

Create a GtkCanvas widget for drawing using Cairo (based on GtkDrawingArea).
Optional arguments `w` and `h` can be used to set the minimum width and height
of the drawing area in pixels. If `init_back` is set to true, the canvas's
image CairoSurface will be initialized immediately, which is useful for
precompilation.

Keyword arguments can be used to set properties of the GtkDrawingArea widget.
"""
mutable struct GtkCanvas <: GtkDrawingArea # NOT a GType
    handle::Ptr{GObject}
    is_sized::Bool
    resize::Union{Function, Nothing}
    draw::Union{Function, Nothing}
    back::CairoSurface   # backing store
    backcc::CairoContext

    function GtkCanvas(w = -1, h = -1, init_back = false; kwargs...)
        da = GtkDrawingArea(; kwargs...)
        if w > 0 && h > 0
            G_.set_content_height(da, h)
            G_.set_content_width(da, w)
        elseif init_back
            error("Width and height arguments must be provided to immediately initialize GtkCanvas.")
        end
        widget = new(getfield(da,:handle), false, nothing, nothing)
        if init_back
            _init_canvas!(widget, w, h)
        end

        function on_realize(da::GtkWidget)
            if widget.is_sized
                on_resize(da,1,1)
            end
            nothing
        end

        on_resize(da::GtkDrawingArea, width, height) = on_resize(da, Cint(width), Cint(height))
        function on_resize(da::GtkDrawingArea, width::Cint, height::Cint)
            widget.is_sized = true
            if G_.get_realized(widget)
                _init_canvas!(widget, width, height)

                if isa(widget.resize, Function)
                    widget.resize(widget)
                end

                draw_back = @cfunction(canvas_draw_backing_store, Nothing, (Ptr{GObject}, Ptr{Nothing}, Cint, Cint, Ptr{Nothing}))
                ccall((:gtk_drawing_area_set_draw_func, libgtk4), Nothing, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), getfield(da,:handle), draw_back, widget.back.ptr, C_NULL)

                draw(widget)
            end
            nothing
        end

        signal_connect(Base.inferencebarrier(on_realize), widget, "realize")
        signal_connect(Base.inferencebarrier(on_resize), widget, "resize")

        return GLib.gobject_move_ref(widget, da)
    end
end
const GtkCanvasLeaf = GtkCanvas

function resize(config::Function, widget::GtkCanvas)
    widget.resize = config
    if G_.get_realized(widget) && widget.is_sized
        widget.resize(widget)
        draw(widget)
    end
    nothing
end

function draw(redraw::Function, widget::GtkCanvas)
    widget.draw = redraw
    draw(widget)
    nothing
end

function draw(widget::GtkCanvas)
    if !isdefined(widget, :back)
        #@warn("backing store not defined")
        return
    end
    if isa(widget.draw, Function)
        widget.draw(widget)
    end
    G_.queue_draw(widget)
end

"""
    getgc(c::GtkCanvas)

Return the CairoContext of the CairoSurface for a GtkCanvas.
"""
function getgc(c::GtkCanvas)
    if !isdefined(c,:backcc)
      error("GtkCanvas not yet initialized.")
    end
    return c.backcc
end

"""
    cairo_surface(c::GtkCanvas)

Return the image CairoSurface for a GtkCanvas.
"""
function cairo_surface(c::GtkCanvas)
    if !isdefined(c,:back)
      error("GtkCanvas not yet initialized.")
    end
    return c.back
end
