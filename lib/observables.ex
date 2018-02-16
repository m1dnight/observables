defmodule Observables do
  alias Observables.Obs

  def example do
    Obs.random 
    |> Obs.filter(fn(x) -> rem(x, 2) == 0 end)
    |> Obs.map(fn(v) -> v * 3 end)
    |> Obs.print
  end
end
