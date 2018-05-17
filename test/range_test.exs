defmodule RangeTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :range
  test "range" do
    testproc = self()

    Obs.range(1, 5, 500)
    |> Obs.map(fn x -> send(testproc, x) end)

    1..5
    |> Enum.map(fn _x ->
      receive do
        v -> Logger.debug("Got #{v}")
      end
    end)

    assert 5 == 5
  end
end
