using Test, Gtk4

@testset "text" begin

@testset "GtkTextIter" begin
import Gtk4: GtkTextIter

w = GtkWindow()
b = GtkTextBuffer()
b.text = "test"
v = GtkTextView(b)
@test v[:buffer, GtkTextBuffer] == b

push!(w, v)

its = _GtkTextIter(b, 1)
ite = _GtkTextIter(b, 2)

@test buffer(its) == b
@test (its:ite).text == "t"

splice!(b, its:ite)
@test b.text == "est"

insert!(b, _GtkTextIter(b, 1), "t")
@test b.text == "test"

it = _GtkTextIter(b)
@test it.line == 0 #lines are 0-based
@test it.starts_line == true

b.text = "line1\nline2"
it = Ref(_GtkTextIter(b))
it.line = 1
@test it.line == 1

it1 = _GtkTextIter(b, 1)
it2 = _GtkTextIter(b, 1)
@test it1 == it2
it2 = _GtkTextIter(b, 2)
@test (it1 == it2) == false
@test it1 < it2
it2 -= 1
@test Ref(it1) == it2

# tags
Gtk4.create_tag(b, "big"; size_points = 24)
Gtk4.create_tag(b, "red"; foreground = "red")
f(buffer)=Gtk4.apply_tag(buffer, "big", _GtkTextIter(b, 1), _GtkTextIter(b, 6))
user_action(f, b)
Gtk4.apply_tag(b, "red", _GtkTextIter(b, 1), _GtkTextIter(b, 6))
Gtk4.remove_tag(b, "red", _GtkTextIter(b, 1), _GtkTextIter(b, 3))
Gtk4.remove_all_tags(b, _GtkTextIter(b, 4), _GtkTextIter(b, 6))

# getproperty
@test it1.offset == 0 #Gtk indices are zero based
@test it2.offset == 0

it1 = Ref(it1)
it1.offset = 1
@test it1.offset == 1

mark = create_mark(b, it)
scroll_to(v, mark, 0, true, 0.0, 0.15)
scroll_to(v, it, 0, true, 0.0, 0.15)

# skip
skip(it2, 1, :line)
@test it2.line == 1
skip(it2, :backward_line)
@test it2.line == 0
skip(it2, :forward_line)
@test it2.line == 1
skip(it2, :forward_to_line_end)
it1 = Ref(_GtkTextIter(b, it2.offset-1))
(it1[]:it2[]).text == "2"

whats = [:forward_word_end, :backward_word_start, :backward_sentence_start, :forward_sentence_end]
for what in whats
    skip(it1, what)
end
whats = [:char,:line,:word,:word_cursor_position,:sentence,:visible_word,:visible_cursor_position,:visible_line,:line_end]
for what in whats
    skip(it1, 0, what)
end

# place_cursor
place_cursor(b, it2)
iter, strong, weak = Gtk4.cursor_locations(v)
@test it2.is_cursor_position == true
@test b.cursor_position == it2.offset

# search
(found, its, ite) = Gtk4.search(b, "line1", :backward)
@test found == true
@test (its:ite).text == "line1"

place_cursor(b, ite)
(found, its, ite) = Gtk4.search(b, "line2", :forward)
@test found == true
@test (its:ite).text == "line2"

# GtkTextRange
range=its:ite
@test range[1] == 'l'
@test range[5] == '2'
@test_throws BoundsError range[10]

# selection
select_range(b, its, ite)
(selected, start, stop) = selection_bounds(b)
@test selected == true
@test (start:stop).text == "line2"

insert!(v, start, "inserted text")

# coords
wx, wy = Gtk4.buffer_to_window_coords(v, 3, 2, 2)
bx, by = Gtk4.window_to_buffer_coords(v, wx, wy)
@test bx == 3 && by == 2

iter = Gtk4.text_iter_at_position(v, 3, 2)

destroy(w)
end

end