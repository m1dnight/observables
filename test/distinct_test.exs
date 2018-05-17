defmodule DistinctTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :distinct
  test "Distinct" do
    testproc = self()

    xs = [1, 1, 1, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.distinct()
    |> Obs.map(fn v -> send(testproc, v) end)

    Enum.uniq(xs)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end

      receive do
        ^x -> assert "duplicates" == ""
      after
        1000 -> :ok
      end
    end)

    assert 5 == 5
  end
end
