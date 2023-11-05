using Gtk4.GLib
using Test

@testset "signal basics" begin

@test signal_return_type(GObject, :notify) == Nothing
@test signal_argument_types(GObject, :notify) == (Ptr{GParamSpec},)

signames = signalnames(GSimpleAction)
@test :notify in signames
@test :activate in signames
@test :change_state in signames

@test signal_return_type(GSimpleAction, :notify) == Nothing
@test signal_argument_types(GSimpleAction, :notify) == (Ptr{GParamSpec},)

end

# GSimpleAction is an object with properties

@testset "simple action" begin

a=GLib.G_.SimpleAction_new("do-something",nothing)
@test "do-something" == GLib.G_.get_name(GAction(a))
@test a.name == "do-something"

@test nothing == GLib.G_.get_parameter_type(GAction(a))
@test a.parameter_type == nothing
@test a.state == nothing
@test a.state_type == nothing
@test a.enabled == true

repr = Base.print_to_string(a) # should display properties
@test endswith(repr,')')
@test occursin("name=\"do-something\"",repr)
@test occursin("enabled=true",repr)

# test properties
gpropnames = gtk_propertynames(a)
@test :name in gpropnames
@test :enabled in gpropnames
@test !(:handle in gpropnames)

propnames = propertynames(a)
@test :name in propnames
@test :enabled in propnames
@test :handle in propnames

GLib.propertyinfo(a,:name)
@test_throws ErrorException GLib.propertyinfo(a,:serial_number)

# test keyword constructor

a2 = GSimpleAction("do-something-else";enabled=false)
@test a2.enabled == false

a3 = GSimpleAction("do-something-again";enabled=true)
@test a3.enabled == true

end

@testset "simple action group" begin
a=GLib.G_.SimpleAction_new("do-something",nothing)
g=GLib.G_.SimpleActionGroup_new()

@test isa(g,GSimpleActionGroup)
@test [] == GLib.list_actions(GActionGroup(g))

enabled_changed = Ref(false)

function enabled_changed_cb1(ac, p)
    enabled_changed[] = true
end
signal_connect(enabled_changed_cb1, a, "notify::enabled")
a.enabled = true
@test enabled_changed[]

#function enabled_changed_cb(ptr, pspec, ref)
#    ref[] = true
#    nothing
#end
#on_notify(enabled_changed_cb, a, :enabled, enabled_changed)
#a.enabled = true

#@test enabled_changed[] == true

#enabled_changed[] = false
#signal_emit(a, "notify::enabled", Nothing, Ptr{GParamSpec}(C_NULL))
#@test enabled_changed[] == true

action_added = Ref(false)

function action_added_cb(action_group, action_name)
    action_added[] = true
end

id = signal_connect(action_added_cb, g, "action_added")

@test action_added[] == false
push!(g,a)
@test action_added[] == true

@test GLib.signal_handler_is_connected(g, id)
GLib.signal_handler_disconnect(g, id)
@test !GLib.signal_handler_is_connected(g, id)

@test ["do-something"] == GLib.list_actions(GActionGroup(g))

extra_arg_ref=Ref(0)

function action_added_cb2(action_group, action_name, extra_arg)
    action_added[] = true
    extra_arg_ref[] = extra_arg
    nothing
end

delete!(g, "do-something")

# test the more sophisticated `signal_connect`
GLib.on_action_added(action_added_cb2, g, 3)

# while we're at it, test `add_action`
function cb(ac,va)
    nothing
end

add_action(GActionMap(g), "new-action", cb)

@test extra_arg_ref[] == 3

function cb2(a,v,user_data)
    nothing
end

add_action(GActionMap(g), "new-action2", cb2, 4)

# test `add_stateful_action`

a5 = add_stateful_action(GActionMap(g), "new-action3", true, cb)
add_stateful_action(GActionMap(g), "new-action4", true, cb2, 5)

@test a5.state == GVariant(true)
GLib.set_state(a5, GVariant(false))
@test a5.state == GVariant(false)

end

@testset "GListStore" begin

a=GLib.G_.SimpleAction_new("do-something",nothing)
l = GListStore(:GSimpleAction)
@test length(l)==0
push!(l, a)
@test length(l)==1
@test l[1]==a
@test l[2]==nothing

push!(l, GLib.G_.SimpleAction_new("do-something",nothing))

l2=[i for i in l]
@test length(l2)==2

deleteat!(l,1)
@test length(l)==1

empty!(l)
@test length(l)==0

push!(l, GLib.GSimpleAction("do-something-else"))
    pushfirst!(l, GLib.GSimpleAction("do-something"))
    @test l[1].name == "do-something"
    @test length(l)==2
    insert!(l, 2, GLib.GSimpleAction("do-yet-another-thing"))
    @test l[2].name == "do-yet-another-thing"
    @test length(l)==3
end

@testset "gvariant" begin

types=[UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float64,Bool]

for t=types
    r=rand(t)
    gv=GLib.GVariant(t,r)

    @test gv[t]==r
    @test GLib.GVariantType(t) == GLib.G_.get_type(gv)
end

gv1 = GLib.GVariant(UInt8,1)
gv2 = GLib.GVariant(UInt8,2)

@test gv1 != gv2
@test gv1 < gv2
@test gv1 <= gv2
@test gv2 > gv1
@test gv2 >= gv1

end
