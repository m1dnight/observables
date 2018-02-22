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
      {:ok, pid} = GenObservable.spawn_supervised(Observables, 0)
      Obs.from_pid(pid)
      |> Obs.inspect
      pid # returned for debugging
  end

  def ex_from_enum do
    # Start a random GenServer
    [1,2,3, 4, 5, 6, 7, 8, 9, 10]
    |> Obs.from_enum(3000) # delay between each
    |> Obs.starts_with([-100, -99, -98, -97, -96])
    |> Obs.filter(fn(x) -> rem(x, 2) == 0 end)
    |> Obs.map(fn(v) -> v * 1 end)
    |> Obs.each(fn(v) -> Logger.debug "Got a value: #{v}" end)
  end


  def ex_merge do
    a = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    |> Obs.from_enum()

    [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
    |> Obs.from_enum()
    |> Obs.merge(a) 
    |> Obs.print
  end
end
