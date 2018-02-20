defmodule Observables do
  alias Observables.Obs
  require Logger
  def example do

    # Start a random GenServer

    {:ok, pid} = GenObservable.start_link(A, 0, [name: :foobar])

    Obs.from_pid(pid)
    |> Obs.filter(fn(x) -> rem(x, 2) == 0 end)
    |> Obs.map(fn(v) -> v * 3 end)
    |> Obs.each(fn(v) -> Logger.debug "Got a value: #{v}" end)
    |> Obs.print
  end
end
