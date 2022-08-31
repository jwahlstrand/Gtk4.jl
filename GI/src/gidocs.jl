# extracting documentation strings from .gir XML files

function append_doc!(exprs, docstring, name)
    push!(exprs, Expr(:macrocall, Symbol("@doc"), nothing, docstring, name))
end

function doc_add_link(docstring, l)
    "$docstring\n \nGTK docs: $l"
end

function doc_item(d, name, t)
    ns=namespace(d.root)
    all_items=findall("//x:namespace/x:$t",d.root, ["x"=>ns])
    n=findfirst(c->c["name"]==String(name),all_items)
    if n !== nothing
        for e in eachelement(all_items[n])
            if e.name == "doc"
                lines=split(e.content,"\n\n")
                if length(lines)>1
                    return lines[1] # just pull the first chunk: a brief summary
                else
                    return e.content
                end
            end
        end
    end
    return nothing
    end

for (item, xmlitem) in [
    (:const, "constant"), (:enum, "enumeration"), (:flags, "bitfield"),
    (:struc, "record"), (:object, "class")]
    @eval function $(Symbol("doc_$(item)"))(d, name)
        doc_item(d, name, $xmlitem)
    end
    @eval function $(Symbol("doc_$(item)_add_link"))(docstring, name, nsstring)
        doc_add_link(docstring, $(Symbol("gtkdoc_$(item)_url"))(nsstring, name))
    end
end

function append_const_docs!(exprs, ns, d, c)
    for x in c
        dc = GI.doc_const(d,x)
        if dc !== nothing
            dc = GI.doc_const_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, x)
        end
    end
    for x in c
        dc = GI.doc_enum(d,x)
        if dc !== nothing
            dc = GI.doc_enum_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, x)
        end
    end
    for x in c
        dc = GI.doc_flags(d,x)
        if dc !== nothing
            dc = GI.doc_flags_add_link(dc, x, ns)
            GI.append_doc!(exprs, dc, x)
        end
    end
end
