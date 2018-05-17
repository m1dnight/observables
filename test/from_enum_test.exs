defmodule FromEnumTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :fromenum
  test "Test from enum" do
    testproc = self()

    xs = [1, 2, 3]

    xs
    |> Obs.from_enum(1000)
    |> Obs.map(fn v -> send(testproc, v) end)

    xs
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    assert 5 == 5
  end
end
