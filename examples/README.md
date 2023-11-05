# Gtk4.jl Examples

## Basic examples
- `calculator4.jl` demonstrates a simple GUI with lots of buttons. Adapted from an example in Gtk.jl by Nand Vinchhi.
- `css.jl` demonstrates widget styling using CSS.
- `dialogs.jl` demonstrates various types of dialogs.

## Drawing
- `canvas.jl` demonstrates use of `GtkCanvas`, which allows drawing with Cairo. Also shows how to change the cursor when it's over a certain widget.
- `canvas_cairomakie.jl` shows how to draw a CairoMakie plot into a `GtkCanvas`.
- `glarea.jl` shows how to use the `GtkGLArea` widget to draw using OpenGL.

## Lists
- `filteredlistview.jl` demonstrates `GtkListView` to show a huge list of strings, with a `GtkSearchEntry` to filter what's shown.
- `listbox.jl` demonstrates `GtkListBox` to show a huge list of strings. This widget is a little easier to use than `GtkListView`.
- `listview.jl` demonstrates a simple way of using `GtkListView`.

## Applications

- `application.jl` is a simple example of using `GtkApplication` and `GAction`s.
- `application2.jl` together with `application.jl` shows how to use remote actions with DBus. This probably only works on Linux.
- The `ExampleApplication` subdirectory shows how to use Gtk4.jl with [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl).
