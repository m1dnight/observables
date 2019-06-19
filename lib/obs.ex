defmodule Observables.Obs do
  alias Observables.GenObservable

  alias Observables.Operator.{
    Switch,
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
    CombineLatest,
    CombineLatestSilent,
    ToList,
    Delay,
    DistinctUntilChanged,
    MergeContinuous
  }

  alias Enum
  require Logger
  alias Logger

  # GENERATORS ###################################################################

  @doc """
  Takes an enumerable and turns it into an observable that produces a value
  for each value of the enumerable.
  If the enum is consumed, returns done.

  More information: http://reactivex.io/documentation/operators/from.html
  """
  def from_enum(coll, delay \\ 1000) do
    {:ok, pid} = GenObservable.start(FromEnum, [coll, delay])

    Process.send_after(pid, {:event, :spit}, delay)

    # {fn observer ->
    #    GenObservable.send_to(pid, observer)
    #  end, pid}
    pid
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

    pid
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
    left =
      l
      |> map(fn v -> {:left, v} end)

    right =
      r
      |> map(fn v -> {:right, v} end)

    # Start our zipper observable.
    {:ok, pid} = GenObservable.start(Zip, [])

    # Make left and right send to us.
    GenObservable.send_to(left, pid)
    GenObservable.send_to(right, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Combine two observables into a single observable that will emit the events
  produced by the inputs.

  More information: http://reactivex.io/documentation/operators/merge.html
  """
  def merge(left, right) do
    {:ok, pid} = GenObservable.start_link(Merge, [])

    GenObservable.send_to(left, pid)
    GenObservable.send_to(right, pid)

    # Creat the continuation.
    pid
  end  
  
  @doc """
  Given an observable which emits observables, mergeContinuous will
  merge all of them and output their values.

  More information: http://reactivex.io/documentation/operators/merge.html
  """
  def mergeContinuous(observable) do
    {:ok, pid} = GenObservable.start_link(MergeContinuous, [])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Combine one or more observables into a single observable that will emit the events
  produced by the inputs. Works the same as merge/2, but expects a list of observables
  to merge.

  More information: http://reactivex.io/documentation/operators/merge.html
  """
  def mergen(observables) do
    {:ok, pid} = GenObservable.start_link(Merge, [])

    observables
    |> Enum.map(fn o ->
      GenObservable.send_to(o, pid)
    end)

    # Creat the continuation.
    pid
  end

  @doc """
  Applies a given function to each value produces by the dependency observable.

  More information: http://reactivex.io/documentation/operators/map.html
  """
  def map(observable, f) do
    {:ok, pid} = GenObservable.start_link(Map, [f])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Filters out values that have already been produced by any given observable.
  Uses the default `==` function if none is given.

  The expected function should take 2 arguments, and return a boolean indication
  the equality.

  More information: http://reactivex.io/documentation/operators/distinct.html
  """
  def distinct(observable, f \\ fn x, y -> x == y end) do
    {:ok, pid} = GenObservable.start_link(Distinct, [f])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Filters out values that have already been produced by any given observable.
  Allows duplicate values as soon as a different value has been produces.


  Uses the default `==` function if none is given.

  The expected function should take 2 arguments, and return a boolean indication
  the equality.

  More information: http://reactivex.io/documentation/operators/distinct.html and http://rxmarbles.com/#distinctUntilChanged
  """
  def distinctuntilchanged(observable, f \\ fn x, y -> x == y end) do
    {:ok, pid} = GenObservable.start_link(DistinctUntilChanged, [f])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Same as map, but returns the original value. Typically used for side effects.

  More information: http://reactivex.io/documentation/operators/subscribe.html
  """
  def each(observable, f) do
    {:ok, pid} = GenObservable.start_link(Each, [f])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Filters out the values that do not satisfy the given predicate.

  The expection function should take 1 arguments and return a boolean value.
  True if the value should be produced, false if the value should be discarded.

  More information: http://reactivex.io/documentation/operators/filter.html
  """
  def filter(observable, f) do
    {:ok, pid} = GenObservable.start_link(Filter, [f])
    GenObservable.send_to(observable, pid)
    # Creat the continuation.
    pid
  end

  @doc """
  Prepends any observable with a list of values provided here in the form of a list.

  More information: http://reactivex.io/documentation/operators/startwith.html
  """
  def starts_with(observable, start_vs) do
    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(StartsWith, [])

    # After the subscription has been made, send all the start values to the producers
    # so he can start pushing them out to our dependees.
    GenObservable.delay(pid, 500)

    # We send each value to the observable, such that it can then forward them to its dependees.
    for v <- start_vs do
      GenObservable.send_event(pid, v)
    end

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Convert an Observable that emits Observables into a single Observable that
  emits the items emitted by the most-recently-emitted of those Observables.

  More information: http://reactivex.io/documentation/operators/switch.html
  """
  def switch(observable) do
    # Start the producer/consumer server.
    {:ok, pid} = GenObservable.start_link(Switch, [])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Chunks items produces by the observable together bounded in time.
  As soon as the set delay has been passed, the observable emits an enumerable
  with the elements gathered up to that point. Does not emit the empty list.

  Works in the same vein as the buffer observable, but that one is bound by number,
  and not by time.

  Source: http://reactivex.io/documentation/operators/buffer.html
  """
  def chunk(observable, interval) do
    {:ok, pid} = GenObservable.start_link(Chunk, [interval])

    GenObservable.send_to(observable, pid)

    Process.send_after(pid, {:event, :flush}, interval)

    # Create the continuation.
    pid
  end

  @doc """
  Periodically gather items emitted by an Observable into bundles of size `size` and emit
  these bundles rather than emitting the items one at a time.

  Source: http://reactivex.io/documentation/operators/buffer.html
  """
  def buffer(observable, size) do
    {:ok, pid} = GenObservable.start_link(Buffer, [size])

    GenObservable.send_to(observable, pid)

    # Create the continuation.
    pid
  end

  @doc """
  Applies a given procedure to an observable's value, and its previous result.
  Works in the same way as the Enum.scan function:

  Enum.scan(1..10, fn(x,y) -> x + y end)
  => [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]

  More information: http://reactivex.io/documentation/operators/scan.html
  """
  def scan(observable, f, default \\ nil) do
    {:ok, pid} = GenObservable.start_link(Scan, [f, default])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Takes the n first element of the observable, and then stops.

  More information: http://reactivex.io/documentation/operators/take.html
  """
  def take(observable, n) do
    {:ok, pid} = GenObservable.start_link(Take, [n])

    GenObservable.send_to(observable, pid)

    # Creat the continuation.
    pid
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
  def combinelatest(l, r, opts \\ [left: nil, right: nil]) do
    left_initial = Keyword.get(opts, :left)
    right_initial = Keyword.get(opts, :right)

    # We tag each value from left and right with their respective label.
    left =
      l
      |> Observables.Obs.inspect()
      |> map(fn v -> {:left, v} end)

    right =
      r
      |> Observables.Obs.inspect()
      |> map(fn v -> {:right, v} end)

    # Start our zipper observable.
    {:ok, pid} = GenObservable.start(CombineLatest, [left_initial, right_initial])

    # Make left and right send to us.
    GenObservable.send_to(left, pid)
    GenObservable.send_to(right, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Given two observables, merges them together and always merges the last result of on of both, and
  reuses the last value from the other.

  The nuance with combinelatest here is that one of both observables will not trigger an update,
  but will update silently.


  E.g.
  1 -> 2 ------> 3
  A -----> B ------> C
  =
  1A --> 2A ----> 3B

  More information: http://reactivex.io/documentation/operators/combinelatest.html
  """
  def combinelatestsilent(l, r, opts \\ [left: nil, right: nil, silent: :right]) do
    left_initial = Keyword.get(opts, :left, nil)
    right_initial = Keyword.get(opts, :right, nil)
    silent = Keyword.get(opts, :silent, :right)

    # We tag each value from left and right with their respective label.
    left =
      l
      |> Observables.Obs.inspect()
      |> map(fn v -> {:left, v} end)

    right =
      r
      |> Observables.Obs.inspect()
      |> map(fn v -> {:right, v} end)

    # Start our zipper observable.
    {:ok, pid} = GenObservable.start(CombineLatestSilent, [left_initial, right_initial, silent])

    # Make left and right send to us.
    GenObservable.send_to(left, pid)
    GenObservable.send_to(right, pid)

    # Creat the continuation.
    pid
  end

  @doc """
  Delays the given observable for n miliseconds.

  More information: http://reactivex.io/documentation/operators/delay.html
  """
  def delay(observable, n) do
    {:ok, pid} = GenObservable.start(Delay, [n])

    GenObservable.send_to(observable, pid)

    pid
  end

  # TERMINATORS ##################################################################

  @doc """
  Prints out the values produces by this observable. Keep in mind that this only works
  for values that are actually printable. If not sure, use inspect/1 instead.
  """
  def print(observable) do
    map(observable, fn v ->
      IO.puts(v)
      v
    end)
  end

  @doc """
  Same as the print/1 function, but uses inspect to print instead of puts.
  """
  def inspect(observable) do
    map(observable, fn v ->
      IO.inspect(v)
      v
    end)
  end

  @doc """
  Aggregates all values produces by its dependency, and stops and returns them in a list 
  as soon as the dependency has signaled it's stopping.
  Do not use this on an infinite stream, for obvious reasons.
  """
  def to_list(observable) do
    ref = :erlang.make_ref()
    {:ok, pid} = GenObservable.start_link(ToList, [{self(), ref}])

    GenObservable.send_to(observable, pid)

    # Our process is now buffering. 
    # When the dependency stops, we will stop as well, and we need to getg
    receive do
      {^ref, vs} ->
        vs
    end
end
end
