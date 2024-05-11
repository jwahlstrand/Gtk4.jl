GtkTextBuffer() = G_.TextBuffer_new(nothing)

GtkTextMark(left_gravity::Bool = false) = G_.TextMark_new(nothing, left_gravity)

GtkTextTag() = G_.TextTag_new(nothing)

const TI = Union{Ref{_GtkTextIter}, GtkTextIter}
zero(::Type{_GtkTextIter}) = _GtkTextIter()
copy(ti::_GtkTextIter) = Ref(ti)
copy(ti::Ref{_GtkTextIter}) = Ref(ti[])

"""
    GtkTextIter(text::GtkTextBuffer, char_offset::Integer)

Creates a `GtkTextIter` with offset `char_offset` (one-based index).
"""
function GtkTextIter(text::GtkTextBuffer, char_offset::Integer)
    i = G_.get_iter_at_offset(text, char_offset - 1)
    Ref(i)
end
function GtkTextIter(text::GtkTextBuffer, line::Integer, char_offset::Integer)
    i = G_.get_iter_at_line_offset(text, line - 1, char_offset - 1)
    Ref(i)
end
function GtkTextIter(text::GtkTextBuffer)
    i = G_.get_start_iter(text)
    Ref(i)
end
function GtkTextIter(text::GtkTextBuffer, mark::GtkTextMark)
    i = G_.get_iter_at_mark(text, mark)
    Ref(i)
end

show(io::IO, iter::_GtkTextIter) = println("_GtkTextIter($(iter.offset) ))")


"""
    buffer(iter::Union{Ref{_GtkTextIter}, GtkTextIter})

Returns the buffer associated with `iter`.
"""
buffer(iter::TI) = convert(GtkTextBuffer,
    ccall((:gtk_text_iter_get_buffer, libgtk4),Ptr{GtkTextBuffer},(Ref{_GtkTextIter},),iter)
)

"""
    char_offset(iter::Union{Ref{_GtkTextIter}, GtkTextIter})

Returns the offset of `iter` (one-based index).
"""
char_offset(iter::TI) = iter.offset+1

Base.cconvert(::Type{Ref{_GtkTextIter}}, it::_GtkTextIter) = Ref(it)
Base.cconvert(::Type{Ref{_GtkTextIter}}, it::Ref{_GtkTextIter}) = Ref(it[])
Base.convert(::Type{_GtkTextIter}, it::Ref{_GtkTextIter}) = GtkTextIter(buffer(it), char_offset(it))#there's a -1 in the constructor

struct GtkTextRange <: AbstractRange{Char}
    a::Base.RefValue{_GtkTextIter}
    b::Base.RefValue{_GtkTextIter}
    GtkTextRange(a, b) = new(copy(a), copy(b))
end

#####  _GtkTextIter  #####
#TODO: search
function getproperty(text::TI, key::Symbol)
    Base.in(key, fieldnames(typeof(text))) && return getfield(text, key)
    if     key === :offset
        ccall((:gtk_text_iter_get_offset, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
    elseif key === :line
        ccall((:gtk_text_iter_get_line, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
    elseif key === :line_offset
        ccall((:gtk_text_iter_get_line_offset, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
    elseif key === :line_index
        ccall((:gtk_text_iter_get_line_index, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
    elseif key === :visible_line_index
        ccall((:gtk_text_iter_get_visible_line_index, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
    elseif key === :visible_line_offset
        ccall((:gtk_text_iter_get_visible_line_offset, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
    elseif key === :marks
        ccall((:gtk_text_iter_get_marks, libgtk4), Ptr{_GSList{GtkTextMark}}, (Ptr{_GtkTextIter},), text) # GtkTextMark iter
    elseif key === :toggled_on_tags
        ccall((:gtk_text_iter_get_toggled_tags, libgtk4), Ptr{_GSList{GtkTextTag}}, (Ptr{_GtkTextIter}, Cint), text, true) # GtkTextTag iter
    elseif key === :toggled_off_tags
        ccall((:gtk_text_iter_get_toggled_tags, libgtk4), Ptr{_GSList{GtkTextTag}}, (Ptr{_GtkTextIter}, Cint), text, false) # GtkTextTag iter
#    elseif key === :child_anchor
#        convert(GtkTextChildAnchor, ccall((:gtk_text_iter_get_child_anchor, libgtk4), Ptr{GtkTextChildAnchor}, (Ptr{_GtkTextIter}, Cint), text, false))
    elseif key === :can_insert
        Bool(ccall((:gtk_text_iter_can_insert, libgtk4), Cint, (Ptr{_GtkTextIter}, Cint), text, true))
    elseif key === :starts_word
        Bool(ccall((:gtk_text_iter_starts_word, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :ends_word
        Bool(ccall((:gtk_text_iter_ends_word, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :inside_word
        Bool(ccall((:gtk_text_iter_inside_word, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :starts_line
        Bool(ccall((:gtk_text_iter_starts_line, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :ends_line
        Bool(ccall((:gtk_text_iter_ends_line, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :starts_sentence
        Bool(ccall((:gtk_text_iter_starts_sentence, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :ends_sentence
        Bool(ccall((:gtk_text_iter_ends_sentence, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :inside_sentence
        Bool(ccall((:gtk_text_iter_inside_sentence, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :is_cursor_position
        Bool(ccall((:gtk_text_iter_is_cursor_position, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :chars_in_line
        ccall((:gtk_text_iter_get_chars_in_line, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
    elseif key === :bytes_in_line
        ccall((:gtk_text_iter_get_bytes_in_line, libgtk4), Cint, (Ptr{_GtkTextIter},), text)
#    elseif key === :attributes
#        view = get_gtk_property(text, :view)::GtkTextView
#        attrs = get_gtk_property(view, :default_attributes)::GtkTextAttributes
#        ccall((:gtk_text_iter_get_attributes, libgtk4), Cint, (Ptr{_GtkTextIter}, Ptr{GtkTextAttributes}), text, &attrs)
#        attrs
#    elseif key === :language
#        ccall((:gtk_text_iter_get_language, libgtk4), Ptr{PangoLanguage}, (Ptr{_GtkTextIter}, Ptr{GtkTextAttributes}), text)
    elseif key === :is_end
        Bool(ccall((:gtk_text_iter_is_end, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :is_start
        Bool(ccall((:gtk_text_iter_is_start, libgtk4), Cint, (Ptr{_GtkTextIter},), text))
    elseif key === :char
        convert(Char, ccall((:gtk_text_iter_get_char, libgtk4), UInt32, (Ptr{_GtkTextIter},), text))
    elseif key === :pixbuf
        convert(GdkPixbuf, ccall((:gtk_text_iter_get_char, libgtk4), Ptr{GdkPixbuf}, (Ptr{_GtkTextIter},), text))
    else
        @warn "_GtkTextIter doesn't have attribute with key $key"
        false
    end
end

function setproperty!(text::TI, key::Symbol, value)
    Base.in(key, fieldnames(typeof(text))) && return setfield!(text, key, value)
    if     key === :offset
        ccall((:gtk_text_iter_set_offset, libgtk4), Cint, (Ptr{_GtkTextIter}, Cint), text, value)
    elseif key === :line
        ccall((:gtk_text_iter_set_line, libgtk4), Cint, (Ptr{_GtkTextIter}, Cint), text, value)
    elseif key === :line_offset
        ccall((:gtk_text_iter_set_line_offset, libgtk4), Cint, (Ptr{_GtkTextIter}, Cint), text, value)
    elseif key === :line_index
        ccall((:gtk_text_iter_set_line_index, libgtk4), Cint, (Ptr{_GtkTextIter}, Cint), text, value)
    elseif key === :visible_line_index
        ccall((:gtk_text_iter_set_visible_line_index, libgtk4), Cint, (Ptr{_GtkTextIter}, Cint), text, value)
    elseif key === :visible_line_offset
        ccall((:gtk_text_iter_set_visible_line_offset, libgtk4), Cint, (Ptr{_GtkTextIter}, Cint), text, value)
    else
        @warn "_GtkTextIter doesn't have attribute with key $key"
        false
    end
    return text
end

Base.:(==)(lhs::TI, rhs::TI) = Bool(ccall((:gtk_text_iter_equal, libgtk4),
    Cint, (Ref{_GtkTextIter}, Ref{_GtkTextIter}), lhs, rhs))
Base.:(<)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk4), Cint,
    (Ref{_GtkTextIter}, Ref{_GtkTextIter}), lhs, rhs) < 0
Base.:(<=)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk4), Cint,
    (Ref{_GtkTextIter}, Ref{_GtkTextIter}), lhs, rhs) <= 0
Base.:(>)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk4), Cint,
    (Ref{_GtkTextIter}, Ref{_GtkTextIter}), lhs, rhs) > 0
Base.:(>=)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk4), Cint,
    (Ref{_GtkTextIter}, Ref{_GtkTextIter}), lhs, rhs) >= 0

start_(iter::TI) = Ref(iter)
iterate(::TI, iter=start_(iter)) = iter.is_end ? nothing : (iter.char, iter + 1)

Base.:+(iter::TI, count::Integer) = (iter = copy(iter); skip(iter, count); iter)
Base.:-(iter::TI, count::Integer) = (iter = copy(iter); skip(iter, -count); iter)

"""
    skip(iter::Ref{_GtkTextIter}, count::Integer)

Moves `iter` `count` characters. Returns a Bool indicating if the move was
successful.
"""
Base.skip(iter::TI, count::Integer) =
    Bool(ccall((:gtk_text_iter_forward_chars, libgtk4), Cint,
        (Ptr{_GtkTextIter}, Cint), iter, count))

"""
    skip(iter::Ref{_GtkTextIter}, what::Symbol)

Moves `iter` according to the operation specified by `what`.
Operations are :

* `:forward_line` (`gtk_text_iter_forward_line`)
* `:backward_line` (`gtk_text_iter_backward_line`)
* `:forward_to_line_end` (`gtk_text_iter_forward_to_line_end`)
* `:backward_word_start` (`gtk_text_iter_forward_word_end`)
* `:forward_word_end` (`gtk_text_iter_backward_word_start`)
* `:backward_sentence_start` (`gtk_text_iter_backward_sentence_start`)
* `:forward_sentence_end` (`gtk_text_iter_forward_sentence_end`)
"""
function Base.skip(iter::TI, what::Symbol)
    if     what === :backward_line
        Bool(ccall((:gtk_text_iter_backward_line, libgtk4), Cint,
            (Ptr{_GtkTextIter},), iter))
    elseif what === :forward_line
        Bool(ccall((:gtk_text_iter_forward_line, libgtk4), Cint,
            (Ptr{_GtkTextIter},), iter))
    elseif what === :forward_to_line_end
        Bool(ccall((:gtk_text_iter_forward_to_line_end, libgtk4), Cint,
            (Ptr{_GtkTextIter},), iter))
    elseif what === :forward_word_end
        Bool(ccall((:gtk_text_iter_forward_word_end, libgtk4), Cint,
            (Ptr{_GtkTextIter},), iter))
    elseif what === :backward_word_start
        Bool(ccall((:gtk_text_iter_backward_word_start, libgtk4), Cint,
            (Ptr{_GtkTextIter},), iter))
    elseif what === :backward_sentence_start
        Bool(ccall((:gtk_text_iter_backward_sentence_start, libgtk4), Cint,
            (Ptr{_GtkTextIter},), iter))
    elseif what === :forward_sentence_end
        Bool(ccall((:gtk_text_iter_forward_sentence_end, libgtk4), Cint,
            (Ptr{_GtkTextIter},), iter))
    else
        @warn "_GtkTextIter doesn't have iterator of type $what"
        false
    end::Bool

end

"""
    skip(iter::Ref{_GtkTextIter}, count::Integer, what::Symbol)

Moves `iter` according to the operation specified by `what` and
`count`.
Operations are :

* `:chars` (`gtk_text_iter_forward_chars`)
* `:lines` (`gtk_text_iter_forward_lines`)
* `:words` (`gtk_text_iter_forward_word_ends`)
* `:word_cursor_positions` (`gtk_text_iter_forward_cursor_positions`)
* `:sentences` (`gtk_text_iter_forward_sentence_ends`)
* `:visible_words` (`gtk_text_iter_forward_visible_word_ends`)
* `:visible_cursor_positions` (`gtk_text_iter_forward_visible_cursor_positions`)
* `:visible_lines` (`gtk_text_iter_forward_visible_lines`)
* `:line_ends` (`gtk_text_iter_forward_visible_lines`)
"""
function Base.skip(iter::TI, count::Integer, what::Symbol)
    if     what === :char || what === :chars
        Bool(ccall((:gtk_text_iter_forward_chars, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :line || what === :lines
        Bool(ccall((:gtk_text_iter_forward_lines, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :word || what === :words
        Bool(ccall((:gtk_text_iter_forward_word_ends, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :word_cursor_position || what === :word_cursor_positions
        Bool(ccall((:gtk_text_iter_forward_cursor_positions, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :sentence || what === :sentences
        Bool(ccall((:gtk_text_iter_forward_sentence_ends, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :visible_word || what === :visible_words
        Bool(ccall((:gtk_text_iter_forward_visible_word_ends, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :visible_cursor_position || what === :visible_cursor_positions
        Bool(ccall((:gtk_text_iter_forward_visible_cursor_positions, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :visible_line || what === :visible_lines
        Bool(ccall((:gtk_text_iter_forward_visible_lines, libgtk4), Cint,
            (Ptr{_GtkTextIter}, Cint), iter, count))
    elseif what === :line_end || what === :line_ends
        count >= 0 || error("_GtkTextIter cannot iterate line_ends backwards")
        for i = 1:count
            if !Bool(ccall((:gtk_text_iter_forward_visible_lines, libgtk4), Cint,
                    (Ptr{_GtkTextIter}, Cint), iter, count))
                return false
            end
        end
        true
#    elseif what === :end
#        ccall((:gtk_text_iter_forward_to_end, libgtk4), Nothing, (Ptr{Nothing},), iter)
#        true
#    elseif what === :begin
#        ccall((:gtk_text_iter_set_offset, libgtk4), Nothing, (Ptr{Nothing}, Cint), iter, 0)
#        true
    else
        @warn "_GtkTextIter doesn't have iterator of type $what"
        false
    end::Bool
end
#    gtk_text_iter_forward_to_tag_toggle
#    gtk_text_iter_forward_find_char


"""
    forward_search(iter::Ref{_GtkTextIter},
        str::AbstractString, start::Ref{_GtkTextIter},
        stop::Ref{_GtkTextIter}, limit::Ref{_GtkTextIter}, flag::Int32)

Implements `gtk_text_iter_forward_search`.
"""
function forward_search(iter::TI,
    str::AbstractString, start::Ref{_GtkTextIter},
    stop::Ref{_GtkTextIter}, limit::Ref{_GtkTextIter}, flag)

    Bool(ccall((:gtk_text_iter_forward_search, libgtk4),
        Cint,
        (Ptr{_GtkTextIter}, Ptr{UInt8}, Cuint, Ptr{_GtkTextIter}, Ptr{_GtkTextIter}, Ptr{_GtkTextIter}),
        iter, string(str), flag, start, stop, limit
    ))
end

"""
    backward_search(iter::Ref{_GtkTextIter},
        str::AbstractString, start::Ref{_GtkTextIter},
        stop::Ref{_GtkTextIter}, limit::Ref{_GtkTextIter}, flag::Int32)

Implements `gtk_text_iter_backward_search`.
"""
function backward_search(iter::TI,
    str::AbstractString, start::Ref{_GtkTextIter},
    stop::Ref{_GtkTextIter}, limit::Ref{_GtkTextIter}, flag)

    Bool(ccall((:gtk_text_iter_backward_search, libgtk4),
        Cint,
        (Ptr{_GtkTextIter}, Ptr{UInt8}, Cuint, Ptr{_GtkTextIter}, Ptr{_GtkTextIter}, Ptr{_GtkTextIter}),
        iter, string(str), flag, start, stop, limit
    ))
end

"""
    search(buffer::GtkTextBuffer, str::AbstractString, direction = :forward,
        flag = GtkTextSearchFlags.GTK_TEXT_SEARCH_TEXT_ONLY)

Search text `str` in buffer in `direction` :forward or :backward starting from
the cursor position in the buffer.

Returns a tuple `(found, start, stop)` where `found` indicates whether the search
was successful and `start` and `stop` are _GtkTextIters containing the location of the match.
"""
function search(buffer::GtkTextBuffer, str::AbstractString, direction = :forward,
    flag = Gtk4.TextSearchFlags_TEXT_ONLY)

    start = GtkTextIter(buffer)
    stop  = GtkTextIter(buffer)
    iter  = GtkTextIter(buffer, buffer.cursor_position)

    if direction == :forward
        limit = GtkTextIter(buffer, length(buffer)+1)
        found = forward_search( iter, str, start, stop, limit, flag)
    elseif direction == :backward
        limit = GtkTextIter(buffer, 1)
        found = backward_search(iter, str, start, stop, limit, flag)
    else
        error("Search direction must be :forward or :backward.")
    end

    return (found, start, stop)
end

#####  GtkTextRange  #####

(:)(a::TI, b::TI) = GtkTextRange(a, b)
function getindex(r::GtkTextRange, b::Int)
    a = copy(first(r))
    b -= 1
    if b < 0 || (b > 0 && !skip(a, b)) || a >= last(r)
        throw(BoundsError())
    end
    a.char::Char
end
function length(r::GtkTextRange)
    a = copy(first(r))
    b = last(r)
    cnt = 0
    while a < b
        if !skip(a, 1)
            break
        end
        cnt += 1
    end
    cnt + 1
end
show(io::IO, r::GtkTextRange) = print("GtkTextRange(\"", r.text, "\")")
first(r::GtkTextRange) = r.a
last(r::GtkTextRange) = r.b
start_(r::GtkTextRange) = copy(first(r))
function next_(r::GtkTextRange, i)
	c=i.char
	skip(i, 1)
	(c,i)
end
done_(r::GtkTextRange, i) = i == last(r)
iterate(r::GtkTextRange, i=start_(r)) = done_(r,i) ? nothing : next_(r, i)

function getproperty(text::GtkTextRange, key::Symbol)
    Base.in(key, fieldnames(GtkTextRange)) && return getfield(text, key)
    starttext = first(text)
    endtext = last(text)
    if key === :slice
        bytestring(ccall((:gtk_text_iter_get_slice, libgtk4), Ptr{UInt8},
            (Ptr{_GtkTextIter}, Ptr{_GtkTextIter}), starttext, endtext))
    elseif key === :visible_slice
        bytestring(ccall((:gtk_text_iter_get_visible_slice, libgtk4), Ptr{UInt8},
            (Ptr{_GtkTextIter}, Ptr{_GtkTextIter}), starttext, endtext))
    elseif key === :text
        bytestring(ccall((:gtk_text_iter_get_text, libgtk4), Ptr{UInt8},
            (Ptr{_GtkTextIter}, Ptr{_GtkTextIter}), starttext, endtext))
    elseif key === :visible_text
        bytestring(ccall((:gtk_text_iter_get_visible_text, libgtk4), Ptr{UInt8},
            (Ptr{_GtkTextIter}, Ptr{_GtkTextIter}), starttext, endtext))
    end
end
function splice!(text::GtkTextBuffer, index::GtkTextRange)
    G_.delete(text, first(index), last(index))
    text
end
in(x::TI, r::GtkTextRange) = Bool(ccall((:gtk_text_iter_in_range, libgtk4), Cint,
    (Ptr{_GtkTextIter}, Ptr{_GtkTextIter}, Ptr{_GtkTextIter}), x, first(r), last(r)))


#####  GtkTextBuffer  #####
#TODO: tags, marks
#TODO: clipboard, selection/cursor, user_action_groups

iterate(text::GtkTextBuffer, iter=start_(GtkTextIter(text))) = iterate(iter, iter)
length(text::GtkTextBuffer) = G_.get_char_count(text)
#get_line_count(text::GtkTextBuffer) = ccall((:gtk_text_buffer_get_line_count, libgtk4), Cint, (Ptr{GObject},), text)
function insert!(text::GtkTextBuffer, index::TI, str::AbstractString)
    G_.insert(text, index, str, sizeof(str))
    text
end
function insert!(text::GtkTextBuffer, str::AbstractString)
    G_.insert_at_cursor(text, str, sizeof(str))
    text
end
function splice!(text::GtkTextBuffer, index::TI)
    G_.backspace(text, index, false, true)
    text
end
function splice!(text::GtkTextBuffer)
    G_.delete_selection(text, false, true)
    text
end

setindex!(buffer::GtkTextBuffer, content::String, ::Type{String}) = G_.set_text(buffer, content, -1)

"""
    selection_bounds(buffer::GtkTextBuffer)

Returns a tuple `(selected, start, stop)` indicating if text is selected
in the `buffer`, and if so sets the _GtkTextIter `start` and `stop` to point to
the selected text.

Implements `gtk_text_buffer_get_selection_bounds`.
"""
function selection_bounds(buffer::GtkTextBuffer)
    selected, start, stop = G_.get_selection_bounds(buffer) # returns the _GtkTextIter, not refs to it
    return (selected, Ref(start), Ref(stop))
end

"""
    select_range(buffer::GtkTextBuffer, ins::TI, bound::TI)
    select_range(buffer::GtkTextBuffer, range::GtkTextRange)

Select the text in `buffer` according to _GtkTextIter `ins` and `bound`.

Implements `gtk_text_buffer_select_range`.
"""
function select_range(buffer::GtkTextBuffer, ins::TI, bound::TI)
    G_.select_range(buffer, ins, bound)
end
select_range(buffer::GtkTextBuffer, range::GtkTextRange) = select_range(buffer, range.a, range.b)

"""
    place_cursor(buffer::GtkTextBuffer, it::_GtkTextIter)
    place_cursor(buffer::GtkTextBuffer, pos::Int)

Place the cursor at indicated position.
"""
place_cursor(buffer::GtkTextBuffer, pos::Int) = place_cursor(buffer, GtkTextIter(buffer, pos))
place_cursor(buffer::GtkTextBuffer, it::TI) = G_.place_cursor(buffer, it)

begin_user_action(buffer::GtkTextBuffer) = G_.begin_user_action(buffer)
end_user_action(buffer::GtkTextBuffer) = G_.end_user_action(buffer)

function user_action(f::Function, buffer::GtkTextBuffer)
    begin_user_action(buffer)
    try
      f(buffer)
    finally
      end_user_action(buffer)
    end
end

function create_tag(buffer::GtkTextBuffer, tag_name::AbstractString; properties...)
    tag = ccall((:gtk_text_buffer_create_tag, libgtk4), Ptr{GObject},
                (Ptr{GObject}, Ptr{UInt8}, Ptr{Nothing}),
                           buffer, bytestring(tag_name), C_NULL)
    tag = convert(GtkTextTag, tag)
    for (k, v) in properties
        set_gtk_property!(tag, k, v)
    end
    tag
end

function apply_tag(buffer::GtkTextBuffer, name::AbstractString, itstart::TI, itend::TI)
    G_.apply_tag_by_name(buffer, name, itstart, itend)
end

function remove_tag(buffer::GtkTextBuffer, name::AbstractString, itstart::TI, itend::TI)
    G_.remove_tag_by_name(buffer, name, itstart, itend)
end

function remove_all_tags(buffer::GtkTextBuffer, itstart::TI, itend::TI)
    G_.remove_all_tags(buffer, itstart, itend)
end

"""
    create_mark(buffer::GtkTextBuffer, mark_name, it::TI, left_gravity::Bool)
    create_mark(buffer::GtkTextBuffer, it::TI)

Implements `gtk_text_buffer_create_mark`.
"""
create_mark(buffer::GtkTextBuffer, mark_name, it::TI, left_gravity::Bool)  =
    GtkTextMarkLeaf(ccall((:gtk_text_buffer_create_mark, libgtk4), Ptr{GObject},
    (Ptr{GObject}, Ptr{UInt8}, Ref{_GtkTextIter}, Cint), buffer, mark_name, it, left_gravity))

create_mark(buffer::GtkTextBuffer, it::TI)  = create_mark(buffer, C_NULL, it, false)

"""
    undo!(buffer::GtkTextBuffer)

Implements `gtk_text_buffer_undo`.
"""
undo!(buffer::GtkTextBuffer) = G_.undo(buffer)

"""
    redo!(buffer::GtkTextBuffer)

Implements `gtk_text_buffer_redo`.
"""
redo!(buffer::GtkTextBuffer) = G_.redo(buffer)

#####  GtkTextView  #####
#TODO: scrolling/views, child overlays

function getindex(text::GtkTextView, sym::Symbol, ::Type{GtkTextBuffer})
    sym === :buffer || error("must supply :buffer, got ", sym)
    return G_.get_buffer(text)
end
function getindex(text::GtkTextView, sym::Symbol, ::Type{Bool})
    sym === :editable || error("must supply :editable, got ", sym)
    return G_.get_editable(text)
end

function insert!(text::GtkTextView, index::TI, child::GtkWidget)
    anchor = G_.create_child_anchor(G_.get_buffer(text), index)
    G_.add_child_at_anchor(text, child, anchor)
    text
end

function insert!(text::GtkTextView, index::TI, str::AbstractString)
    G_.insert_interactive(G_.get_buffer(text), index, str, sizeof(str), G_.get_editable(text))
    text
end
function insert!(text::GtkTextView, str::AbstractString)
    G_.insert_interactive_at_cursor(G_.get_buffer(text), bytestring(str), sizeof(str), G_.get_editable(text))
    text
end
function splice!(text::GtkTextView, index::TI)
    G_.backspace(G_.get_buffer(text), index, true, G_.get_editable(text))
    text
end
function splice!(text::GtkTextView)
    G_.delete_selection(G_.get_buffer(text), true, G_.get_editable(text))
    text
end

"""
    scroll_to(view::GtkTextView, mark::GtkTextMark, within_margin::Real,
                   use_align::Bool, xalign::Real, yalign::Real)

    scroll_to(view::GtkTextView, iter::TI, within_margin::Real,
              use_align::Bool, xalign::Real, yalign::Real)

Implements `gtk_text_view_scroll_to_mark` and `gtk_text_view_scroll_to_iter`.
"""
function scroll_to(view::GtkTextView, mark::GtkTextMark, within_margin::Real,
                   use_align::Bool, xalign::Real, yalign::Real)
    G_.scroll_to_mark(view, mark, within_margin, use_align, xalign, yalign)
end

function scroll_to(view::GtkTextView, iter::TI, within_margin::Real,
                   use_align::Bool, xalign::Real, yalign::Real)
    G_.scroll_to_iter(view, iter, within_margin, use_align, xalign, yalign)
    nothing
end


"""
    buffer_to_window_coords(view::GtkTextView, buffer_x::Integer, buffer_y::Integer, wintype::Integer = 0)

Implements `gtk_text_view_buffer_to_window_coords`.
"""
function buffer_to_window_coords(view::GtkTextView, buffer_x::Integer, buffer_y::Integer, wintype = TextWindowType_WIDGET)
    G_.buffer_to_window_coords(view, wintype, buffer_x, buffer_y)
end

"""
    window_to_buffer_coords(view::GtkTextView, window_x::Integer, window_y::Integer, wintype::Integer = 2)

Implements `gtk_text_view_window_to_buffer_coords`.
"""
function window_to_buffer_coords(view::GtkTextView, window_x::Integer, window_y::Integer, wintype = TextWindowType_LEFT)
    G_.window_to_buffer_coords(view, wintype, window_x, window_y)
end

"""
    text_iter_at_position(view::GtkTextView, x::Integer, y::Integer)

Implements `gtk_text_view_get_iter_at_position`.
"""
function text_iter_at_position(view::GtkTextView, x::Integer, y::Integer)
    buffer = view.buffer
    iter = GtkTextIter(buffer)
    text_iter_at_position(view, iter, nothing, Int32(x), Int32(y))
    return GtkTextIter(buffer, char_offset(iter))
end

function text_iter_at_position(view::GtkTextView, iter::Ref{_GtkTextIter}, trailing, x::Int32, y::Int32)
    ret, iter_ret, trailing_ret = G_.get_iter_at_position(view, x, y)
    iter[] = iter_ret
    if trailing !== nothing
        trailing[] = trailing_ret
    end
end

function cursor_locations(view::GtkTextView)
    weak = Ref{_GdkRectangle}()
    strong = Ref{_GdkRectangle}()
    buffer = view.buffer
    iter = GtkTextIter(buffer, buffer.cursor_position)

    string, weak = G_.get_cursor_locations(view, iter)
    return (iter, strong, weak)
end

####  GtkTextMark  ####

show(w::GtkTextMark) = visible(w, true)
