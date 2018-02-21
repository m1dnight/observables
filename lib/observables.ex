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
      #{:ok, pid} = GenObservable.start_link(Observables, 0, [name: :foobar])
      #{:ok, pid} = Observables.Supervisor.add_child(Observables, [0])
      {:ok, pid} = GenObservable.spawn_supervised(Observables, [0])
      Obs.from_pid(pid)
      |> Obs.filter(fn(x) -> rem(x, 2) == 0 end)
      |> Obs.map(fn(v) -> v * 3 end)
      |> Obs.each(fn(v) -> Logger.debug "Got a value: #{v}" end)
      |> Obs.print
  end

  def test2 do
    # Start a random GenServer
    [1,2,3]
    |> Obs.from_enum(100)
    |> Obs.filter(fn(x) -> rem(x, 2) == 0 end)
    |> Obs.map(fn(v) -> v * 3 end)
    |> Obs.each(fn(v) -> Logger.debug "Got a value: #{v}" end)
    |> Obs.print
  end
end
