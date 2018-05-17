defmodule StartsWithTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :startswith
  test "Starts with" do
    testproc = self()

    first = [0]
    xs = [1, 2, 3]

    xs
    |> Obs.from_enum(100)
    |> Obs.starts_with(first)
    |> Obs.map(fn v -> send(testproc, v) end)

    (xs ++ first)
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
