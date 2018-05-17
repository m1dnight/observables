defmodule FilterTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger
  @tag :filter
  test "Filter" do
    testproc = self()

    xs = [1, 2, 3, 1, 2, 3, 3, 2, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.filter(fn x -> x > 2 end)
    |> Obs.map(fn v -> send(testproc, v) end)

    xs
    |> Enum.filter(fn x -> x > 2 end)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x)}" == ""
    after
      1000 ->
        :ok
    end
  end
end
