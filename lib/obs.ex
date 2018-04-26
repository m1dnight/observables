defmodule Observables.Obs do
  alias Observables.{
    Switch,
    GenObservable,
    FromEnum,
    Range,
    Zip,
    Merge,
    Map,
    Distinct,
    Each,
    Filter,
    StartsWith
  }

  alias Enum
  require Logger
  alias Logger

  # GENERATORS ###################################################################

  @doc """
  from_pid/1 can be considered to be a subject. Any process that implements 
  """
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
    {:ok, pid} = GenObservable.start(FromEnum, [coll, delay])

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
    {:ok, pid} = GenObservable.start(Range, [first, last, delay])

    Process.send_after(pid, {:event, :tick}, delay)

    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  repeat takes a function as argument and an optional interval.
  The function will be repeatedly executed, and the result will be emitted as an event.
  """
  def repeat(f, opts \\ []) do
    interval = Keyword.get(opts, :interval, 1000)
    times = Keyword.get(opts, :times, :infinity)

    range(1, times, interval)
    |> map(fn _ ->
      f.()
    end)
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

    # Start our zipper observable.
    {:ok, pid} = GenObservable.start(Zip, [])

    # Make left and right send to us.
    f_l.(pid)
    f_r.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def merge({observable_fn_1, _parent_pid_1}, {observable_fn_2, _parent_pid_2}) do
    {:ok, pid} = GenObservable.start_link(Merge, [])

    observable_fn_1.(pid)
    observable_fn_2.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def map({observable_fn, _parent_pid}, f) do
    {:ok, pid} = GenObservable.start_link(Map, [f])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def distinct({observable_fn, _parent_pid}, f \\ fn x, y -> x == y end) do
    {:ok, pid} = GenObservable.start_link(Distinct, [f])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def each({observable_fn, _parent_pid}, f) do
    {:ok, pid} = GenObservable.start_link(Each, [f])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def filter({observable_fn, _parent_pid}, f) do
    {:ok, pid} = GenObservable.start_link(Filter, [f])
    observable_fn.(pid)
    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  def starts_with({observable_fn, _parent_pid}, start_vs) do
    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(StartsWith, [])

    # After the subscription has been made, send all the start values to the producers
    # so he can start pushing them out to our dependees.
    GenObservable.delay(pid, 500)

    # We send each value to the observable, such that it can then forward them to its dependees.
    for v <- start_vs do
      GenObservable.send_event(pid, v)
    end

    observable_fn.(pid)

    # Creat the continuation.
    {fn consumer ->
       # This sets the observer as our dependency.
       GenObservable.send_to(pid, consumer)
     end, pid}
  end

  def switch({observable_fn, _parent_pid}) do
    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(Switch, [])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  # TERMINATORS ##################################################################

  def print({observable_fn, parent_pid}) do
    map({observable_fn, parent_pid}, fn v ->
      IO.puts(v)
      v
    end)
  end

  def inspect({observable_fn, parent_pid}) do
    map({observable_fn, parent_pid}, fn v ->
      IO.inspect(v)
      v
    end)
  end

  # def to_list({observable_fn, parent_pid}) do
  #   # Create a proxy observable, that will send all the values to us.
  # end
end
