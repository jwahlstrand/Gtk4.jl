## GtkTreeView

const TRI = Union{Ref{_GtkTreeIter}, _GtkTreeIter}
zero(::Type{GtkTreeIter}) = GtkTreeIter()
copy(ti::GtkTreeIter) = G_.copy(ti)
copy(ti::_GtkTreeIter) = ti
copy(ti::Ref{_GtkTreeIter}) = Ref(ti[])
show(io::IO, iter::GtkTreeIter) = print("GtkTreeIter(...)")

Base.cconvert(::Type{Ref{_GtkTreeIter}},x::_GtkTreeIter) = Ref(x)

### GtkTreePath

GtkTreePath() = G_.TreePath_new()
copy(path::GtkTreePath) = G_.copy(path)

GtkTreePath(path::AbstractString) = G_.TreePath_new_from_string(path)

next(path::GtkTreePath) = G_.next(path)
prev(path::GtkTreePath) = G_.prev(path)
up(path::GtkTreePath) = ccall((:gtk_tree_path_up, libgtk4), Cint, (Ptr{GtkTreePath},), path) != 0
down(path::GtkTreePath) = ccall((:gtk_tree_path_down, libgtk4), Nothing, (Ptr{GtkTreePath},), path)
string(path::GtkTreePath) = G_.to_string(path)

### add indices for a store 1-based

## Get an iter corresponding to an index specified as a string
function iter_from_string_index(store, index::AbstractString)
    success, iter = G_.get_iter_from_string(GtkTreeModel(store), index)
    if !isvalid(store, iter)
        error("invalid index: $index")
    end
    iter
end

### GtkListStore

function GtkListStore(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_list_store_newv, libgtk4), Ptr{GObject}, (Cint, Ptr{GLib.GType}), length(types), gtypes)
    GtkListStoreLeaf(handle)
end

GtkListStore(combo::GtkComboBoxText) = GtkListStore(ccall((:gtk_combo_box_get_model, libgtk4), Ptr{GObject}, (Ptr{GObject},), combo))

## index is integer for a liststore, vector of ints for tree
iter_from_index(store::GtkListStore, index::Int) = iter_from_string_index(store, string(index - 1))
index_from_iter(store::GtkListStore, iter::TRI) = parse(Int, get_string_from_iter(GtkTreeModel(store), iter)) + 1

function list_store_set_values(store::GtkListStore, iter, values)
	riter = Ref(iter)
    for (i, value) in enumerate(values)
        ccall((:gtk_list_store_set_value, libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Cint, Ptr{GValue}),
              store, riter, i - 1, GLib.gvalue(value))
    end
end

function push!(listStore::GtkListStore, values::Tuple)
	iter = G_.append(listStore)
    list_store_set_values(listStore, iter, values)
    iter
end

function pushfirst!(listStore::GtkListStore, values::Tuple)
    iter = G_.prepend(listStore)
    list_store_set_values(listStore, iter, values)
    iter
end

## insert before
function insert!(listStore::GtkListStoreLeaf, iter::TRI, values)
	if isa(iter,_GtkTreeIter)
		iter=Ref(iter)
	end
	newiter = Ref{_GtkTreeIter}()
    ccall((:gtk_list_store_insert_before, libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ref{_GtkTreeIter}), listStore, newiter, iter)
    list_store_set_values(listStore, newiter[], values)
    newiter
end


function delete!(listStore::GtkListStore, iter::TRI)
    # not sure what to do with the return value here
	if isa(iter,_GtkTreeIter)
		iter=Ref(iter)
	end
	ret = ccall(("gtk_list_store_remove", libgtk4), Cint, (Ptr{GObject}, Ptr{_GtkTreeIter}), listStore, iter)
    listStore
end

deleteat!(listStore::GtkListStore, iter::TRI) = delete!(listStore, iter)


empty!(listStore::GtkListStore) = G_.clear(listStore)

## by index

## insert into a list store after index
function insert!(listStore::GtkListStoreLeaf, index::Int, values)
    index > length(listStore) && return(push!(listStore, values))

    iter = iter_from_index(listStore, index)
    insert!(listStore, iter, values)
end

deleteat!(listStore::GtkListStoreLeaf, index::Int) = delete!(listStore, iter_from_index(listStore, index))
pop!(listStore::GtkListStoreLeaf) = deleteat!(listStore, length(listStore))
popfirst!(listStore::GtkListStoreLeaf) = deleteat!(listStore, 1)


function isvalid(listStore::GtkListStore, iter::_GtkTreeIter)
	_iter = Ref(iter)
	ret = ccall(("gtk_list_store_iter_is_valid", libgtk4), Cint, (Ptr{GObject}, Ptr{_GtkTreeIter}), listStore, _iter)
	ret2 = convert(Bool, ret)
end

function length(listStore::GtkListStore)
    _len = G_.iter_n_children(GtkTreeModel(listStore), nothing)
	return convert(Int, _len)
end

size(listStore::GtkListStore) = (length(listStore), ncolumns(GtkTreeModel(listStore)))

getindex(store::GtkListStore, row::Int, column) = getindex(store, iter_from_index(store, row), column)
getindex(store::GtkListStore, row::Int) = getindex(store, iter_from_index(store, row))

function setindex!(store::GtkListStore, value, index::Int, column::Integer)
    setindex!(store, value, iter_from_index(store, index), column)
end

### GtkTreeStore

function GtkTreeStoreLeaf(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_tree_store_newv, libgtk4), Ptr{GObject}, (Cint, Ptr{GLib.GType}), length(types), gtypes)
    GtkTreeStoreLeaf(handle)
end

iter_from_index(store::GtkTreeStoreLeaf, index::Vector{Int}) = iter_from_string_index(store, join(index.-1, ":"))

function tree_store_set_values(treeStore::GtkTreeStoreLeaf, iter, values)
	riter = Ref(iter)
    for (i, value) in enumerate(values)
        ccall((:gtk_tree_store_set_value, libgtk4), Nothing, (Ptr{GObject}, Ref{_GtkTreeIter}, Cint, Ptr{GValue}),
              treeStore, riter, i - 1, GLib.gvalue(value))
    end
    iter
end


function push!(treeStore::GtkTreeStore, values::Tuple, parent = nothing)
	m_iter = Ref{_GtkTreeIter}()
	_parent = (parent === nothing ? C_NULL : parent)
	if isa(_parent,_GtkTreeIter)
		_parent=Ref(_parent)
	end
	ret = ccall(("gtk_tree_store_append", libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ptr{_GtkTreeIter}), treeStore, m_iter, _parent)
	iter = m_iter[]

    tree_store_set_values(treeStore, iter, values)
    iter
end

function pushfirst!(treeStore::GtkTreeStore, values::Tuple, parent = nothing)
	if isa(parent,_GtkTreeIter)
		parent=Ref(parent)
	end
    iter = G_.prepend(treeStore, parent)

    tree_store_set_values(treeStore, iter, values)
    iter
end

## index can be :parent or :sibling
## insertion can be :after or :before
function insert!(treeStore::GtkTreeStoreLeaf, piter::TRI, values; how::Symbol = :parent, where::Symbol = :after)
    iter =  Ref{_GtkTreeIter}()
    if how == :parent
        if where == :after
            ccall((:gtk_tree_store_insert_after, libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ref{_GtkTreeIter}, Ptr{Nothing}), treeStore, iter, piter, C_NULL)
        else
            ccall((:gtk_tree_store_insert_before, libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ref{_GtkTreeIter}, Ptr{Nothing}), treeStore, iter, piter, C_NULL)
        end
    else
        if where == :after
            ccall((:gtk_tree_store_insert_after, libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ref{Nothing}, Ref{_GtkTreeIter}), treeStore, iter, C_NULL, piter)
        else
            ccall((:gtk_tree_store_insert_before, libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ref{Nothing}, Ref{_GtkTreeIter}), treeStore, iter, C_NULL, piter)
        end
    end

    tree_store_set_values(treeStore, iter[], values)
end


function delete!(treeStore::GtkTreeStore, iter::TRI)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_tree_store_remove, libgtk4), Cint, (Ptr{GObject}, Ref{_GtkTreeIter}), treeStore, iter)
    treeStore
end

deleteat!(treeStore::GtkTreeStore, iter::TRI) = delete!(treeStore, iter)

## insert by index
function insert!(treeStore::GtkTreeStoreLeaf, index::Vector{Int}, values; how::Symbol = :parent, where::Symbol = :after)
    iter = iter_from_index(treeStore, index)
    insert!(treeStore, iter, values; how = how, where = where)
end


function splice!(treeStore::GtkTreeStoreLeaf, index::Vector{Int})
    iter = iter_from_index(treeStore, index)
    delete!(treeStore, iter)
end

empty!(treeStore::GtkTreeStore) = G_.clear(treeStore)

isvalid(treeStore::GtkTreeStore, iter) =
    ccall((:gtk_tree_store_iter_is_valid, libgtk4), Cint,
         (Ptr{GObject}, Ref{_GtkTreeIter}), treeStore, iter) != 0

isancestor(treeStore::GtkTreeStore, iter::TRI, descendant::TRI) =
    ccall((:gtk_tree_store_is_ancestor, libgtk4), Cint,
          (Ptr{GObject}, Ref{_GtkTreeIter}, Ref{_GtkTreeIter}),
          treeStore, iter, descendant) != 0

depth(treeStore::GtkTreeStore, iter::TRI) =
    ccall((:gtk_tree_store_iter_depth, libgtk4), Cint, (Ptr{GObject}, Ref{_GtkTreeIter}), treeStore, iter)

## get index store[iter], store[iter, column], store[index], store[index, column]
getindex(store::Union{GtkTreeStore, GtkListStore}, iter::TRI, column::Integer) = getindex(GtkTreeModel(store), iter, column)
getindex(store::Union{GtkTreeStore, GtkListStore}, iter::TRI) = getindex(GtkTreeModel(store), iter)

getindex(store::GtkTreeStore, row::Vector{Int}, column) = getindex(store, iter_from_index(store, row), column)
getindex(store::GtkTreeStore, row::Vector{Int}) = getindex(store, iter_from_index(store, row))

function setindex!(store::GtkListStore, value, iter::_GtkTreeIter, column::Integer)
    ret = ccall(("gtk_list_store_set_value", libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Int32, Ptr{_GValue}), store, Ref(iter), column - 1, GLib.gvalue(value))
end

function setindex!(store::GtkTreeStore, value, iter::_GtkTreeIter, column::Integer)
    ret = ccall(("gtk_tree_store_set_value", libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Int32, Ptr{_GValue}), store, Ref(iter), column - 1, GLib.gvalue(value))
end

function setindex!(store::GtkTreeStore, value, index::Vector{Int}, column::Integer)
     setindex!(store, value, iter_from_index(store, index), column)
end



### GtkTreeModelFilter

GtkTreeModelFilterLeaf(child_model::GObject) = G_.filter_new(child_model, nothing)

function convert_iter_to_child_iter(model::GtkTreeModelFilter, filter_iter::TRI)
    child_iter = Ref{GtkTreeIter}()
    ccall((:gtk_tree_model_filter_convert_iter_to_child_iter, libgtk4), Nothing,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreeIter}),
          model, child_iter, Ref(filter_iter))
    child_iter[]
end

function convert_child_iter_to_iter(model::GtkTreeModelFilter, child_iter::TRI)
    filter_iter = Ref{GtkTreeIter}()
    ccall((:gtk_tree_model_filter_convert_child_iter_to_iter, libgtk4), Nothing,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}),
          model,  filter_iter, child_iter)
    filter_iter[]
end

### GtkTreeModelSort

GtkTreeModelSortLeaf(child_model::GObject) = G_.TreeModelSort_new_with_model(GtkTreeModel(child_model))

function convert_iter_to_child_iter(model::GtkTreeModelSort, sort_iter::TRI)
    child_iter = Ref{GtkTreeIter}()
    ccall((:gtk_tree_model_sort_convert_iter_to_child_iter, libgtk4), Nothing,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}),
          model, child_iter, sort_iter)
    child_iter[]
end

function convert_child_iter_to_iter(model::GtkTreeModelSort, child_iter::TRI)
    sort_iter = Ref{_GtkTreeIter}()
    ccall((:gtk_tree_model_sort_convert_child_iter_to_iter, libgtk4), Nothing,
          (Ptr{GObject}, Ptr{_GtkTreeIter}, Ref{_GtkTreeIter}),
          model, sort_iter, child_iter)
    sort_iter[]
end
### GtkTreeModel

function getindex(treeModel::GtkTreeModel, iter::TRI, column::Integer)
    val = Ref(GValue())
	if isa(iter,_GtkTreeIter)
		iter = Ref(iter)
	end
    ccall((:gtk_tree_model_get_value, libgtk4), Nothing, (Ptr{GObject}, Ptr{_GtkTreeIter}, Cint, Ptr{GValue}),
           treeModel, iter, column - 1, val)
    val[Any]
end

function getindex(treeModel::GtkTreeModel, iter::TRI)
    ntuple( i -> treeModel[iter, i], ncolumns(treeModel) )
end

ncolumns(treeModel::GtkTreeModel) = G_.get_n_columns(treeModel)

## add in gtk_tree_model iter functions to traverse tree

## Most gtk function pass in a Mutable Iter and return a bool
## Update iter to point to first iterm
# function get_iter_first(treeModel::GtkTreeModel, iter = Ref{_GtkTreeIter}())
#     ret = ccall((:gtk_tree_model_get_iter_first, libgtk4), Cint,
#           (Ptr{GObject}, Ptr{_GtkTreeIter}),
#           treeModel, iter)
#     ret != 0
# end

## return (Bool, iter)
function get_iter_next(treeModel::GtkTreeModel, iter::Ref{_GtkTreeIter})
    ret = ccall((:gtk_tree_model_iter_next, libgtk4), Cint,
                (Ptr{GObject}, Ptr{_GtkTreeIter}),
                treeModel, iter)
    ret != 0
end

## update iter to point to previous.
## return Bool
function get_iter_previous(treeModel::GtkTreeModel, iter::Ref{GtkTreeIter})
    ret = ccall((:gtk_tree_model_iter_previous, libgtk4), Cint,
          (Ptr{GObject}, Ptr{GtkTreeIter}),
          treeModel, iter)
    ret != 0
end

## update iter to point to first child of parent iter
## return Bool
function iter_children(treeModel::GtkTreeModel, iter::Ref{_GtkTreeIter}, piter::TRI)
    ret = ccall((:gtk_tree_model_iter_children, libgtk4), Cint,
                (Ptr{GObject}, Ptr{_GtkTreeIter}, Ptr{_GtkTreeIter}),
                treeModel, iter, piter)
    ret != 0
end

## return boolean, checks if there is a child
function iter_has_child(treeModel::GtkTreeModel, iter::TRI)
    ret = ccall((:gtk_tree_model_iter_has_child, libgtk4), Cint,
          (Ptr{GObject},  Ptr{_GtkTreeIter}),
          treeModel, iter)
    ret != 0
end

## return number of children for iter
function iter_n_children(treeModel::GtkTreeModel, iter::TRI)
    ret = ccall((:gtk_tree_model_iter_n_children, libgtk4), Cint,
          (Ptr{GObject},  Ref{_GtkTreeIter}),
          treeModel, iter)
    ret
end

## return Bool
function iter_parent(treeModel::GtkTreeModel, iter::Ref{_GtkTreeIter}, citer::TRI)
    ret = ccall((:gtk_tree_model_iter_parent, libgtk4), Cint,
                (Ptr{GObject}, Ptr{_GtkTreeIter}, Ref{_GtkTreeIter}),
                treeModel, iter, citer)
    ret != 0
end

## string is of type "0:1:0" (0-based)
function get_string_from_iter(treeModel::GtkTreeModel, iter::_GtkTreeIter)
	ret = ccall(("gtk_tree_model_get_string_from_iter", libgtk4), Cstring, (Ptr{GObject}, Ptr{_GtkTreeIter}), treeModel, Ref(iter))
	ret2 = if ret == C_NULL
			nothing
		else
			bytestring(ret, true)
		end
end

## these mutate iter to point to new object.
next(treeModel::GtkTreeModel, iter::Ref{_GtkTreeIter}) = get_iter_next(treeModel, iter)
prev(treeModel::GtkTreeModel, iter::Ref{_GtkTreeIter}) = get_iter_previous(treeModel, iter)
up(treeModel::GtkTreeModel, iter::Ref{_GtkTreeIter}) = iter_parent(treeModel, iter, copy(iter))
down(treeModel::GtkTreeModel, iter::Ref{_GtkTreeIter}) = iter_children(treeModel, iter, copy(iter))

length(treeModel::GtkTreeModel, iter::TRI) = iter_n_children(treeModel, iter)
string(treeModel::GtkTreeModel, iter::TRI) = get_string_from_iter(treeModel, iter)

## index is Int[] 1-based
index_from_iter(treeModel::GtkTreeModel, iter::TRI) = parse.(Int32, split(get_string_from_iter(treeModel, iter), ":")) .+ 1

## An iterator to walk a tree, e.g.,
## for iter in TreeIterator(store) ## or TreeIterator(store, piter)
##   println(store[iter, 1])
## end
mutable struct TreeIterator
    store::GtkTreeStore
    model::GtkTreeModel
    iter::Union{Nothing, TRI}
end
TreeIterator(store::GtkTreeStore, iter = nothing) = TreeIterator(store, GtkTreeModel(store), iter)
Base.IteratorSize(::TreeIterator) = Base.SizeUnknown()

## iterator interface for depth first search
function start_(x::TreeIterator)
    isa(x.iter, Nothing) ? nothing : Ref(copy(x.iter))
end

function done_(x::TreeIterator, state)
    iter = Ref{GtkTreeIter}()

    isa(state, Nothing) && return (!get_iter_first(x.model, iter))   # special case root

    state = copy(state)

    ## we are not done if:
    iter_has_child(x.model, state) && return(false) # state has child
    next(x.model, copy(state))     && return(false) # state has sibling

    # or a valid ancestor of piter has a sibling
    up(x.model, state) || return(true)

    while isa(x.iter, Nothing) || isancestor(x.store, x.iter, state)
        next(x.model, copy(state)) && return(false) # has a sibling
        up(x.model, state) || return(true)
    end
    return(true)
end


function next_(x::TreeIterator, state)
    iter = Ref{GtkTreeIter}()

    if isa(state, Nothing)      # special case root
        get_iter_first(x.model, iter)
        return(iter, iter)
    end

    state = copy(state)

    if iter_has_child(x.model, state)
        down(x.model, state)
        return(state, state)
    end

    cstate = copy(state)
    next(x.model, cstate) && return(cstate, cstate)

    up(x.model, state)

    while isa(x.iter, Nothing) || isancestor(x.store, x.iter, state)
        cstate = copy(state)
        next(x.model, cstate) && return(cstate, cstate) # return the sibling of state
        up(x.model, state)
    end
    error("next not found")
end

iterate(x::TreeIterator, state=start_(x)) = done_(x, state) ? nothing : next_(x, state)


function iter(treeModel::GtkTreeModel, path::GtkTreePath)
  it = Ref{_GtkTreeIter}()
  ret = ccall((:gtk_tree_model_get_iter, libgtk4), Cint, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ptr{GtkTreePath}),
                    treeModel, it, path) != 0
  ret, it[]
end

function path(treeModel::GtkTreeModel, iter::TRI)
  GtkTreePath( ccall((:gtk_tree_model_get_path, libgtk4), Ptr{GtkTreePath},
                            (Ptr{GObject}, Ref{_GtkTreeIter}),
                            treeModel, iter ) )
end

depth(path::GtkTreePath) = G_.get_depth(path)

### GtkTreeSortable

### GtkCellRenderer

GtkCellRendererAccelLeaf() = G_.CellRendererAccel_new()
GtkCellRendererComboLeaf() = G_.CellRendererCombo_new()
GtkCellRendererPixbufLeaf() = G_.CellRendererPixbuf_new()
GtkCellRendererProgressLeaf() = G_.CellRendererProgress_new()
GtkCellRendererSpinLeaf() = G_.CellRendererSpin_new()
GtkCellRendererTextLeaf() = G_.CellRendererText_new()
GtkCellRendererToggleLeaf() = G_.CellRendererToggle_new()
GtkCellRendererSpinnerLeaf() = G_.CellRendererSpinner_new()

### GtkTreeViewColumn

GtkTreeViewColumnLeaf() = G_.TreeViewColumn_new()
function GtkTreeViewColumnLeaf(renderer::GtkCellRenderer, mapping)
    treeColumn = GtkTreeViewColumnLeaf()
    pushfirst!(treeColumn, renderer)
    for (k, v) in mapping
        add_attribute(treeColumn, renderer, string(k), v)
    end
    treeColumn
end

function GtkTreeViewColumnLeaf(title::AbstractString, renderer::GtkCellRenderer, mapping)
    set_gtk_property!(GtkTreeViewColumnLeaf(renderer, mapping), :title, title)
end

empty!(treeColumn::GtkTreeViewColumn) = G_.clear(treeColumn)

function pushfirst!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool = false)
    G_.pack_start(treeColumn, renderer, expand)
    treeColumn
end

function push!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool = false)
    G_.pack_end(treeColumn, renderer, expand)
    treeColumn
end

add_attribute(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer,
              attribute::AbstractString, column::Integer) =
    G_.add_attribute(treeColumn, renderer, attribute, column)

### GtkTreeSelection
function selected(selection::GtkTreeSelection)
    hasselection(selection) || error("No selection for GtkTreeSelection")

    iter = Ref{_GtkTreeIter}()

    ret = ccall((:gtk_tree_selection_get_selected, libgtk4), Cint,
              (Ptr{GObject}, Ptr{Ptr{GtkTreeModel}}, Ptr{_GtkTreeIter}), selection, C_NULL, iter) != 0

    !ret && error("No selection of GtkTreeSelection")

    iter[]
end

function selected_rows(selection::GtkTreeSelection)
    hasselection(selection) || return GtkTreeIter[]

    model = Ref{Ptr{GtkTreeModel}}()

    paths = GLib.GList(ccall((:gtk_tree_selection_get_selected_rows, libgtk4),
                                Ptr{GLib._GList{Ptr{GtkTreePath}}},
                                (Ptr{GObject}, Ptr{Ptr{GtkTreeModel}}),
                                selection, model))

    iters = _GtkTreeIter[]
    for path in paths
		it = Ref{_GtkTreeIter}()
		ret = ccall((:gtk_tree_model_get_iter, libgtk4), Cint, (Ptr{GObject}, Ptr{_GtkTreeIter}, Ptr{GtkTreePath}),
	                      model[], it, path) != 0
        ret && push!(iters, it[])
    end

    iters
end

length(selection::GtkTreeSelection) = G_.count_selected_rows(selection)

hasselection(selection::GtkTreeSelection) = length(selection) > 0

select!(selection::GtkTreeSelection, iter::TRI) =
    ccall((:gtk_tree_selection_select_iter, libgtk4), Nothing,
          (Ptr{GObject}, Ref{_GtkTreeIter}), selection, iter)

unselect!(selection::GtkTreeSelection, iter::TRI) =
    ccall((:gtk_tree_selection_unselect_iter, libgtk4), Nothing,
          (Ptr{GObject}, Ref{_GtkTreeIter}), selection, iter)

selectall!(selection::GtkTreeSelection) = G_.select_all(selection)

unselectall!(selection::GtkTreeSelection) = G_.unselect_all(selection)

### GtkTreeView

GtkTreeViewLeaf() = G_.TreeView_new()
GtkTreeViewLeaf(treeStore::GtkTreeModel) = G_.TreeView_new_with_model(treeStore)

function push!(treeView::GtkTreeView, treeColumns::GtkTreeViewColumn...)
    for col in treeColumns
        G_.append_column(treeView, col)
    end
    treeView
end

function insert!(treeView::GtkTreeView, index::Integer, treeColumn::GtkTreeViewColumn)
    G_.insert_column(treeView, treeColumn, index - 1)
    treeView
end

function delete!(treeView::GtkTreeView, treeColumns::GtkTreeViewColumn...)
    for col in treeColumns
        G_.remove_column(treeView,col)
    end
    treeView
end

function expand_to_path(tree_view::GtkTreeView, path::GtkTreePath)
    G_.expand_to_path(tree_view, path)
end

function path_at_pos(treeView::GtkTreeView, x::Integer, y::Integer)
    pathPtr = Ref{Ptr{GtkTreePath}}(0)

    ret = ccall((:gtk_tree_view_get_path_at_pos, libgtk4), Cint,
                      (Ptr{GObject}, Cint, Cint, Ref{Ptr{GtkTreePath}}, Ptr{Ptr{Nothing}}, Ptr{Cint}, Ptr{Cint} ),
                       treeView, x, y, pathPtr, C_NULL, C_NULL, C_NULL) != 0
    if ret
        path = GtkTreePath(pathPtr[], true)
    else
        path = GtkTreePath()
    end
    ret, path
end

### GtkCellLayout
function cells(cellLayout::GtkCellLayout)
  cells = GLib.GList(ccall((:gtk_cell_layout_get_cells, libgtk4),
             Ptr{GLib._GList{GtkCellRenderer}}, (Ptr{GObject},), cellLayout))
  return cells
end

### To be done
#
#GtkCellArea
#GtkCellAreaBox
#GtkCellAreaContext
#GtkCellView
#GtkIconView
