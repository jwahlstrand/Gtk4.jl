## GtkButton

GtkButton(title::AbstractString) = G_.Button_new_with_mnemonic(title)
function GtkButton(w::GtkWidget)
    b = G_.Button_new()
    G_.set_child(b,w)
    b
end

setindex!(f::GtkButton, w::Union{Nothing,GtkWidget}) = G_.set_child(f,w)
getindex(f::GtkButton) = G_.get_child(f)

function on_signal_clicked(@nospecialize(clicked_cb::Function), widget::GtkButton, vargs...)
    signal_connect(clicked_cb, widget, "clicked", Nothing, (), vargs...)
end

## GtkCheckButton, GtkToggleButton

GtkCheckButton(title::AbstractString) = G_.CheckButton_new_with_mnemonic(title)

group(cb::GtkCheckButton, cb2::Union{Nothing,GtkCheckButton}) = G_.set_group(cb, cb2)

GtkToggleButton(title::AbstractString) = G_.ToggleButton_new_with_mnemonic(title)

group(tb::GtkToggleButton, tb2::Union{Nothing,GtkToggleButton}) = G_.set_group(tb, tb2)

# GtkToggleButton is a subclass of GtkButton so "clicked" signal is also available for it
# GtkCheckButton only has "toggled"
function on_signal_toggled(@nospecialize(toggled_cb::Function), widget::Union{GtkToggleButton,GtkCheckButton}, vargs...)
    signal_connect(toggled_cb, widget, "toggled", Nothing, (), vargs...)
end

## GtkSwitch

function GtkSwitch(active::Bool)
    b = GtkSwitch()
    G_.set_active(b, active)
    b
end

## GtkLinkButton

function GtkLinkButton(uri::AbstractString, label::AbstractString, visited::Bool)
    b = GtkLinkButton(uri, label)
    G_.set_visited(b, visited)
    b
end
function GtkLinkButton(uri::AbstractString, visited::Bool)
    b = GtkLinkButton(uri)
    G_.set_visited(b, visited)
    b
end

function GtkVolumeButton(value::Real) # 0 <= value <= 1
    b = GtkVolumeButton()
    G_.set_value(b, value)
    b
end

popup(b::GtkMenuButton) = G_.popup(b)

function GtkPopoverMenu(model::GMenu, nested = false)
    if nested
        G_.PopoverMenu_new_from_model_full(model, PopoverMenuFlags_Nested)
    else
        G_.PopoverMenu_new_from_model(model)
    end
end

GtkPopoverMenuBar(model::GMenu) = G_.PopoverMenuBar_new_from_model(model)

menu_model(b::Union{GtkMenuButton,GtkPopoverMenu, GtkPopoverMenuBar}, model) = G_.set_menu_model(b, GMenuModel(model))
menu_model(b::Union{GtkMenuButton,GtkPopoverMenu, GtkPopoverMenuBar}) = G_.get_menu_model(b)
