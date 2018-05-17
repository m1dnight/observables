defmodule MapTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :map
  test "Map" do
    testproc = self()

    xs = [1, 1, 1, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.map(fn x -> x + 100 end)
    |> Obs.map(fn v -> send(testproc, v) end)

    Enum.map(xs, fn x -> x + 100 end)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    assert 5 == 5
  end
end
