GtkImage(pixbuf::GdkPixbuf) = G_.Image_new_from_pixbuf(pixbuf)
GtkImage(filename::AbstractString) = G_.Image_new_from_file(filename)

function GtkImage(; resource_path = nothing, filename = nothing, icon_name = nothing, stock_id = nothing, size::Symbol = :INVALID)
    source_count = (resource_path !== nothing) + (filename !== nothing) + (icon_name !== nothing) + (stock_id !== nothing)
    @assert(source_count <= 1,
        "GdkPixbuf must have at most one resource_path, filename, stock_id, or icon_name argument")
    if resource_path !== nothing
        img = G_.Image_new_from_resource(resource_path)
    elseif filename !== nothing
        img = G_.Image_new_from_file(filename)
    elseif icon_name !== nothing
        img = G_.Image_new_from_icon_name(icon_name, getfield(GtkIconSize, size))
    elseif stock_id !== nothing
        img = G_.Image_new_from_stock(stock_id, getfield(GtkIconSize, size))
    else
        img = G_.Image_new()
    end
    return img
end
empty!(img::GtkImage) = G_.clear(img)
GdkPixbuf(img::GtkImage) = G_.get_pixbuf(img)

GtkPicture(pixbuf::GdkPixbuf) = G_.Picture_new_for_pixbuf(pixbuf)
GtkPicture(gfile::GFile) = G_.Picture_new_for_file(gfile)

function GtkPicture(; resource_path = nothing, filename = nothing)
    source_count = (resource_path !== nothing) + (filename !== nothing) + (icon_name !== nothing) + (stock_id !== nothing)
    @assert(source_count <= 1,
        "GdkPixbuf must have at most one resource_path, filename, stock_id, or icon_name argument")
    if resource_path !== nothing
        img = G_.Picture_new_for_resource(resource_path)
    elseif filename !== nothing
        img = G_.Picture_new_for_filename(filename)
    else
        img = G_.Picture_new()
    end
    return img
end

set_pixbuf(p::GtkPicture,pb) = G_.set_pixbuf(p,pb)

GtkProgressBarLeaf() = G_.ProgressBar_new()
pulse(progress::GtkProgressBar) = G_.pulse(progress)

GtkSpinnerLeaf() = G_.Spinner_new()

start(spinner::GtkSpinner) = G_.start(spinner)
stop(spinner::GtkSpinner) = G_.stop(spinner)

GtkStatusbarLeaf() = G_.Statusbar_new()
context_id(status::GtkStatusbar, source) = G_.get_context_id(status, source)
context_id(status::GtkStatusbar, source::Integer) = source
push!(status::GtkStatusbar, context, text) =
    (G_.push(status, context_id(status, context), text); status)
pop!(status::GtkStatusbar, context) = G_.pop(status, context_id(status, context))
slice!(status::GtkStatusbar, context, message_id) =
    G_.remove(status, context_id(status, context), message_id)
empty!(status::GtkStatusbar, context) = G_.remove_all(status, context_id(status, context))