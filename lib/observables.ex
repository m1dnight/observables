defmodule Observables do
  use Observables.GenObservable

  alias Observables.{Obs, GenObservable}
  require Logger

  def init(args) do
    {:ok, args}
  end

  def handle_event(message, state) do
    # We reply with :value if we want the value to propagate through the dependency graph.
    {:value, message, state}
  end

  def ex_from_pid do
    # Start a random GenServer
    {:ok, pid1} = GenObservable.spawn_supervised(Observables, 0)

    Obs.from_pid(pid1)
    |> Obs.inspect()
    |> Obs.map(fn x -> IO.puts("Got me an :#{inspect(x)}") end)

    # returned for debugging
    pid1
  end

  def ex_simple do
    # Start a random GenServer
    # delay between each
    x =
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      |> Obs.from_enum()

    [1, 1, 3, 4, 5, 6, 7, 8, 9, 10]
    |> Obs.from_enum()
    |> Obs.merge(x)
    |> Obs.distinct()
    |> Obs.filter(fn(x) -> x > 4 end)
    |> Obs.starts_with([1,2,3])
    |> Obs.map(fn v -> IO.puts(v) end)
  end

  def ex_from_enum do
    # Start a random GenServer
    # delay between each
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    |> Obs.from_enum(0)
    |> Obs.starts_with([-100, -99, -98, -97, -96])
    |> Obs.map(fn v -> v * 1 end)
    |> Obs.each(fn v -> Logger.debug("Got a value: #{v}") end)
  end

  def ex_merge do
    a =
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      |> Obs.from_enum()

    [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
    |> Obs.from_enum()
    |> Obs.merge(a)
    |> Obs.print()
  end

  def test_distinct do
    [1, 1, 2, 3, 1, 1, 2, 3, 4, 1, 2, 3, 3]
    |> Obs.from_enum()
    |> Obs.distinct()
    |> Obs.print()
  end

  def test_switch do
    {:ok, pid1} = GenObservable.spawn_supervised(Observables, 0)

    x =
      1..100
      |> Enum.to_list()
      |> Obs.from_enum()

    y =
      100..1000
      |> Enum.to_list()
      |> Obs.from_enum()

    # We will send observables to this observable
    # such that it "produces a stream of observables"
    Obs.from_pid(pid1)
    |> Obs.switch()
    |> Obs.print()

    # returned for debugging
    {pid1, x, y}
  end
end
