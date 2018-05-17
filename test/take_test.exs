defmodule TakeTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger
  @tag :take
  test "Take" do
    testproc = self()

    xs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]

    xs
    |> Obs.from_enum(100)
    |> Obs.take(4)
    |> Obs.map(fn v -> send(testproc, v) end)

    [1, 2, 3, 4]
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    # Receive no other values.
    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x, charlists: :as_lists)} " == ""
    after
      1000 ->
        :ok
    end
  end
end
