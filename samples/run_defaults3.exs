
:net_kernel.start(:bench1, %{})
{:ok, _peer, node} = :peer.start(%{:name => :bench2})
:ok = :rpc.call(node, :code, :add_paths, [:code.get_path()])

{:ok, _peer, node3} = :peer.start(%{:name => :bench3})
:ok = :rpc.call(node3, :code, :add_paths, [:code.get_path()])

# Init mnesia
:mnesia.start()
:ok = :rpc.call(node, :mnesia, :start, [])
:ok = :rpc.call(node3, :mnesia, :start, [])
{:ok, _} = :mnesia.change_config(:extra_db_nodes, [node, node3])

{:atomic, :ok} = :mnesia.create_table(
    :user,
   [{:ram_copies, [node(), node, node3]}, 
     attributes: [:id, :name]
   ])

# Init CETS

{:ok, pid1} = :cets.start(:cets_user, %{})
{:ok, pid2} = :rpc.call(node, :cets, :start, [:cets_user, %{}])
{:ok, pid3} = :rpc.call(node3, :cets, :start, [:cets_user, %{}])
:ok = :cets_join.join(:join_lock1, %{}, pid1, pid2)
:ok = :cets_join.join(:join_lock1, %{}, pid1, pid3)


# Init CETS

{:ok, pid1_new} = :cets.start(:cets_user_new, %{})
{:ok, pid2_new} = :rpc.call(node, :cets, :start, [:cets_user_new, %{}])
{:ok, pid3_new} = :rpc.call(node3, :cets, :start, [:cets_user_new, %{}])
:ok = :cets_join.join(:join_lock1, %{}, pid1_new, pid2_new)
:ok = :cets_join.join(:join_lock1, %{}, pid1_new, pid3_new)

newId = fn -> :erlang.unique_integer([:positive]) end

Benchee.run(
  %{
    "mnesia" => fn -> :mnesia.sync_dirty(fn -> :mnesia.write({:user, newId.(), "alice"}) end) end,
    "cets" => fn -> :ok = :cets.insert(:cets_user, {newId.(), "alice"}) end
#   "cets_new" => fn -> :true = :cets.insert_new(:cets_user_new, {newId.(), "alice"}) end
  },
  warmup: 2,
  time: 10,
  parallel: 16,
# profile_after: true
# profile_after: :fprof
  profile_after: {:fprof, [sort: :own , apply_opts: [procs: [pid1, pid1_new]]]}
)
#:mnesia.info()
