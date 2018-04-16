defmodule Observables.Obs do
  alias Observables.{Action, StatefulAction, Switch, GenObservable}
  alias Enum
  require Logger
  alias Logger

  # GENERATORS ###################################################################

  def from_pid(producer) do
    {fn consumer ->
       GenObservable.send_to(producer, consumer)
     end, producer}
  end

  @doc """
  Takes an enumerable and will "spit" each value one by one, every delay seconds.
  If the enum is consumed, returns done.
  """
  def from_enum(coll, delay \\ 1000) do
    action = fn :spit, state ->
      case state do
        [] ->
          {:done, state}

        [x | xs] ->
          Process.send_after(self(), {:event, :spit}, delay)
          {:value, x, xs}
      end
    end

    {:ok, pid} = GenObservable.start(StatefulAction, [action, coll])

    Process.send_after(pid, {:event, :spit}, delay)

    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Range creates an observable that will start at the given integer and run until the last integer.
  If no second argument is given, the stream is infinite.
  One can use :infinity as the end for an infinite stream (see: https://elixirforum.com/t/infinity-in-elixir-erlang/7396)
  """
  def range(first, last, delay \\ 1000) do
    action = fn :tick, current ->
      case {current, last} do
        {current, last} when current > last ->
          {:done, current}

        {current, _last} ->
          Process.send_after(self(), {:event, :tick}, delay)
          {:value, current, current + 1}
      end
    end

    {:ok, pid} = GenObservable.start(StatefulAction, [action, first])

    Process.send_after(pid, {:event, :tick}, delay)

    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  # CONSUMER AND PRODUCER ########################################################

  def zip(l, r) do
    # We tag each value from left and right with their respective label.
    {f_l, _pid_l} =
      l
      |> map(fn v -> {:left, v} end)

    {f_r, _pid_r} =
      r
      |> map(fn v -> {:right, v} end)

    # We create a new stateful action that will only accept one value from the left, and one from the right.
    # It will buffer all intermediate values.
    action = fn value, state ->
      case {value, state} do
        # No values at all, and got a left.
        {{:left, vl}, {:left, [], :right, []}} ->
          {:novalue, {:left, [vl], :right, []}}

        # No values yet, and got a right.
        {{:right, vr}, {:left, [], :right, []}} ->
          {:novalue, {:left, [], :right, [vr]}}

        # Already have left, now got right.
        {{:right, vr}, {:left, [vl | vls], :right, []}} ->
          {:value, {vl, vr}, {:left, vls, :right, []}}

        # Already have a right value, and now received left.
        {{:left, vl}, {:left, [], :right, [vr | vrs]}} ->
          {:value, {vl, vr}, {:left, [], :right, vrs}}

        # Already have a left, and received a left.
        {{:left, vln}, {:left, vls, :right, []}} ->
          {:novalue, {:left, vls ++ [vln], :right, []}}

        # Already have a right, and received a right.
        {{:right, vr}, {:left, [], :right, vrs}} ->
          {:novalue, {:left, [], :right, vrs ++ [vr]}}

        # Have left and right, and received a right.
        {{:right, vrn}, {:left, [vl | vls], :right, [vr | vrs]}} ->
          {:value, {vl, vr}, {:left, vls, right: vrs ++ [vrn]}}

        # Have left and right, and received a left.
        {{:left, vln}, {:left, [vl | vls], :right, [vr | vrs]}} ->
          {:value, {vl, vr}, {:left, vls ++ [vln], right: vrs}}
      end
    end

    # Start our zipper observable.
    {:ok, pid} = GenObservable.start(StatefulAction, [action, {:left, [], :right, []}])

    # Make left and right send to us.
    f_l.(pid)
    f_r.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def merge({observable_fn_1, _parent_pid_1}, {observable_fn_2, _parent_pid_2}) do
    action = fn x -> {:value, x} end

    {:ok, pid} = GenObservable.start_link(Action, action)

    observable_fn_1.(pid)
    observable_fn_2.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def map({observable_fn, _parent_pid}, f) do
    # Create the mapper function.
    mapper = fn v ->
      new_v = f.(v)
      {:value, new_v}
    end

    create_action(observable_fn, mapper)
  end

  def distinct({observable_fn, _parent_pid}, f \\ fn x, y -> x == y end) do
    action = fn v, state ->
      seen? = Enum.any?(state, fn seen -> f.(v, seen) end)

      if not seen? do
        {:value, v, [v | state]}
      else
        {:novalue, state}
      end
    end

    create_stateful_action(observable_fn, action, [])
  end

  def each({observable_fn, _parent_pid}, f) do
    # Create the mapper function.
    eacher = fn v ->
      f.(v)
      {:value, v}
    end

    create_action(observable_fn, eacher)
  end

  def filter({observable_fn, _parent_pid}, f) do
    # Creat the wrapper for the filter function.
    filterer = fn v ->
      if f.(v) do
        {:value, v}
      else
        {:novalue}
      end
    end

    create_action(observable_fn, filterer)
  end

  def starts_with({observable_fn, _parent_pid}, start_vs) do
    action = fn v ->
      {:value, v}
    end

    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(Action, action)

    # After the subscription has been made, send all the start values to the producers
    # so he can start pushing them out to our dependees.
    GenObservable.delay(pid, 500)

    for v <- start_vs do
      GenObservable.send_event(pid, v)
    end

    # Set ourselves as the dependency of pid, so he can start sending us values, too.
    observable_fn.(pid)

    # Creat the continuation.
    {fn consumer ->
       # This sets the observer as our dependency.
       GenObservable.send_to(pid, consumer)
     end, pid}
  end

  def switch({observable_fn, _parent_pid}) do
    action = fn new_obs, s ->
      switcher = self()

      # Unsubscribe to the previous observer we were forwarding.
      if s != nil do
        {:forwarder, forwarder, :sender, observable} = s
        {_f, pidf} = forwarder
        GenObservable.stop_send_to(pidf, self())
        {_f, pids} = observable
        GenObservable.stop_send_to(pids, pidf)
      end

      # We subscribe to this observable.
      # {_, obsvpid} = observable
      # GenObservable.send_to(obsvpid, self())

      forwarder =
        new_obs
        |> map(fn v -> GenObservable.send_event(switcher, {:forward, v}) end)

      {:novalue, {:forwarder, forwarder, :sender, new_obs}}
    end

    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(Switch, [action, nil])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  # TERMINATORS ##################################################################

  def print({observable_fn, parent_pid}) do
    action = fn v ->
      IO.puts(v)
      v
    end

    map({observable_fn, parent_pid}, action)
  end

  def inspect({observable_fn, parent_pid}) do
    action = fn v ->
      IO.inspect(v)
      v
    end

    map({observable_fn, parent_pid}, action)
  end

  # HELPERS ######################################################################

  defp create_action(observable_fn, action) do
    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(Action, action)

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  defp create_stateful_action(observable_fn, action, state) do
    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(StatefulAction, [action, state])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end
end
