GI.jl
======

Julia bindings using libgobject-introspection.

This builds on https://github.com/bfredl/GI.jl

It is under active development and is currently not ready to be used for anything
outside of Gtk4.jl. The goal is to output code that simplifies the creation of
Julia packages that wrap GObject-based libraries.

This package currently only works on Linux because it uses gobject_introspection_jll,
which is currently only available for Linux. However, the generated code works on
other platforms.

## Status

Most of libgirepository is wrapped.
Information like lists of structs, methods, and functions can be extracted, as
well as argument types, struct fields, etc.
GObject introspection includes annotations that indicate whether return values
should be freed, whether pointer arguments can be optionally NULL, whether list
outputs are NULL-terminated, which argument corresponds to the length of array
inputs, etc.

Parts that are still very rough:

* Anything to do with callbacks and signals

## Generated code

Code generated by GI.jl currently requires [Gtk4.jl](https://github.com/JuliaGtk/Gtk4.jl).
In the future the GLib submodule of that package might be split off, and then
that could become the base requirement.

Below are a few details about the output.

### Constants, enums, and flags

Constant names are the same as in the C library but with the namespace removed.
So for example the C constant `G_PRIORITY_DEFAULT` becomes `PRIORITY_DEFAULT`.

Enums and flags are exported as [Cenum's](https://github.com/JuliaInterop/CEnum.jl)
and [BitFlags](https://github.com/jmert/BitFlags.jl), respectively. The name is
of the form EnumName_INSTANCE_NAME. So for example `G_SIGNAL_FLAGS_RUN_LAST`
becomes `SignalFlags_RUN_LAST`.

### GObjects and GInterfaces

GObject and GInterface types are named as in Gtk.jl, with the namespace
included in the type name (for example `PangoLayout` or `GtkWindow`). This differs
from python bindings.

Properties are exported as Julia properties and can be accessed and set using
`my_object.property_name`. Alternatively the functions `get_gtk_property` or
`set_gtk_property!` can be used.

### Methods

Methods of objects, interfaces, and structs are exported without the namespace
and, for C methods, the object/interface/struct name. So for example `pango_layout_get_extents`
becomes `get_extents`. Functions not associated with particular objects, interfaces, or structs are
exported with the namespace removed.

Arguments of C functions that are outputs are converted to returned outputs. When there
is a return value as well as argument outputs, the Julia method returns a tuple of the
outputs. For array inputs, the length parameter in the C function is removed for
Julia methods. Similarly, for array outputs, a length parameter output is
omitted in the Julia output. GError outputs are converted to throws. When pointer
inputs can optionally be NULL, the Julia methods accept nothing as the argument.
When outputs are NULL, the Julia methods output nothing.