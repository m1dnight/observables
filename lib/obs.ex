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
    StartsWith,
    Buffer,
    Chunk,
    Scan,
    Take,
    CombineLatest
  }

  alias Enum
  require Logger
  alias Logger

  # GENERATORS ###################################################################

  @doc """
  from_pid/1 can be considered to be a subject. Any process that implements the GenObservable interface can be used a subject, actually.
  Example:
  Spawn a subject using the `Subject` module.
  {:ok, pid1} = GenObservable.spawn_supervised(Subject, 0)

  Print out each value that the subject produces.
  Obs.from_pid(pid1)
  |> Obs.print()

  Send an event to the subject.
  GenObservable.send_event(pid1, :value)

  More information: http://reactivex.io/documentation/subject.html
  """
  def from_pid(producer) do
    {fn consumer ->
       GenObservable.send_to(producer, consumer)
     end, producer}
  end

  @doc """
  Takes an enumerable and turns it into an observable that produces a value
  for each value of the enumerable.
  If the enum is consumed, returns done.

  More information: http://reactivex.io/documentation/operators/from.html
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

  More information: http://reactivex.io/documentation/operators/range.html
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

  More information: http://reactivex.io/documentation/operators/repeat.html
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

  @doc """
  Combine the emissions of multiple Observables together via a specified function 
  and emit single items for each combination based on the results of this function.

  More information: http://reactivex.io/documentation/operators/zip.html
  """
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

  @doc """
  Combine two observables into a single observable that will emit the events 
  produced by the inputs.

  More information: http://reactivex.io/documentation/operators/merge.html
  """
  def merge({observable_fn_1, _parent_pid_1}, {observable_fn_2, _parent_pid_2}) do
    {:ok, pid} = GenObservable.start_link(Merge, [])

    observable_fn_1.(pid)
    observable_fn_2.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Applies a given function to each value produces by the dependency observable.

  More information: http://reactivex.io/documentation/operators/map.html
  """
  def map({observable_fn, _parent_pid}, f) do
    {:ok, pid} = GenObservable.start_link(Map, [f])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Filters out values that have already been produced by any given observable.
  Uses the default `==` function if none is given. 

  The expected function should take 2 arguments, and return a boolean indication
  the equality.

  More information: http://reactivex.io/documentation/operators/distinct.html
  """
  def distinct({observable_fn, _parent_pid}, f \\ fn x, y -> x == y end) do
    {:ok, pid} = GenObservable.start_link(Distinct, [f])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Same as map, but returns the original value. Typically used for side effects.

  More information: http://reactivex.io/documentation/operators/subscribe.html
  """
  def each({observable_fn, _parent_pid}, f) do
    {:ok, pid} = GenObservable.start_link(Each, [f])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Filters out the values that do not satisfy the given predicate. 

  The expection function should take 1 arguments and return a boolean value. 
  True if the value should be produced, false if the value should be discarded.

  More information: http://reactivex.io/documentation/operators/filter.html
  """
  def filter({observable_fn, _parent_pid}, f) do
    {:ok, pid} = GenObservable.start_link(Filter, [f])
    observable_fn.(pid)
    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Prepends any observable with a list of values provided here in the form of a list.

  More information: http://reactivex.io/documentation/operators/startwith.html
  """
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

  @doc """
  Convert an Observable that emits Observables into a single Observable that 
  emits the items emitted by the most-recently-emitted of those Observables.

  More information: http://reactivex.io/documentation/operators/switch.html
  """
  def switch({observable_fn, _parent_pid}) do
    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(Switch, [])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Chunks items produces by the observable together bounded in time. 
  As soon as the set delay has been passed, the observable emits an enumerable
  with the elements gathered up to that point. Does not emit the empty list.

  Works in the same vein as the buffer observable, but that one is bound by number,
  and not by time.

  Source: http://reactivex.io/documentation/operators/buffer.html
  """
  def chunk({observable_fn, _parent_pid}, interval) do
    {:ok, pid} = GenObservable.start_link(Chunk, [interval])

    observable_fn.(pid)

    Process.send_after(pid, {:event, :flush}, interval)

    # Create the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Periodically gather items emitted by an Observable into bundles of size `size` and emit
  these bundles rather than emitting the items one at a time.

  Source: http://reactivex.io/documentation/operators/buffer.html
  """
  def buffer({observable_fn, _parent_pid}, size) do
    {:ok, pid} = GenObservable.start_link(Buffer, [size])

    observable_fn.(pid)

    # Create the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Applies a given procedure to an observable's value, and its previous result. 
  Works in the same way as the Enum.scan function:

  Enum.scan(1..10, fn(x,y) -> x + y end) 
  => [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]

  More information: http://reactivex.io/documentation/operators/scan.html
  """
  def scan({observable_fn, _parent_pid}, f) do
    {:ok, pid} = GenObservable.start_link(Scan, [f])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Takes the n first element of the observable, and then stops.

  More information: http://reactivex.io/documentation/operators/take.html
  """
  def take({observable_fn, parent_pid}, n) do
    {:ok, pid} = GenObservable.start_link(Take, [n])

    observable_fn.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  @doc """
  Given two observables, merges them together and always merges the last result of on of both, and
  reuses the last value from the other.

  E.g.
  1 -> 2 ------> 3
  A -----> B ------> C 
  =
  1A --> 2A -> 2B -> 3B -> 3C

  More information: http://reactivex.io/documentation/operators/combinelatest.html
  """
  def combinelatest(l, r) do
    # We tag each value from left and right with their respective label.
    {f_l, _pid_l} =
      l
      |> Observables.Obs.inspect()
      |> map(fn v -> {:left, v} end)

    {f_r, _pid_r} =
      r
      |> Observables.Obs.inspect()
      |> map(fn v -> {:right, v} end)

    # Start our zipper observable.
    {:ok, pid} = GenObservable.start(CombineLatest, [])

    # Make left and right send to us.
    f_l.(pid)
    f_r.(pid)

    # Creat the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

  # TERMINATORS ##################################################################

  @doc """
  Prints out the values produces by this observable. Keep in mind that this only works
  for values that are actually printable. If not sure, use inspect/1 instead.
  """
  def print({observable_fn, parent_pid}) do
    map({observable_fn, parent_pid}, fn v ->
      IO.puts(v)
      v
    end)
  end

  @doc """
  Same as the print/1 function, but uses inspect to print instead of puts.
  """
  def inspect({observable_fn, parent_pid}) do
    map({observable_fn, parent_pid}, fn v ->
      IO.inspect(v)
      v
    end)
  end
end
