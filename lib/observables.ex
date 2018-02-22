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

  def test1 do
      # Start a random GenServer
      {:ok, pid} = GenObservable.spawn_supervised(Observables, 0)
      Obs.from_pid(pid)
      |> Obs.filter(fn(x) -> rem(x, 2) == 0 end)
      |> Obs.map(fn(v) -> v * 3 end)
      |> Obs.each(fn(v) -> Logger.debug "Got a value: #{v}" end)
      |> Obs.print
      pid # returned for debugging
  end

  def test2 do
    # Start a random GenServer
    [1,2,3, 4, 5, 6, 7, 8, 9, 10]
    |> Obs.from_enum(0)
    |> Obs.starts_with([-100, -99, -98, -97, -96])
    #|> Obs.filter(fn(x) -> rem(x, 2) == 0 end)
    |> Obs.map(fn(v) -> v * 1 end)
    #|> Obs.each(fn(v) -> Logger.debug "Got a value: #{v}" end)
    |> Obs.print
  end

  def test3 do
    e = [1,2,3, 4, 5, 6, 7, 8, 9, 10]
        |> Obs.from_enum(0)

    e |> Obs.print

    e |> Obs.print
  end

  def test4 do
    a = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    |> Obs.from_enum()

    b = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
    |> Obs.from_enum()

    a
    |> Obs.merge(b) 
    |> Obs.print
  end
end
