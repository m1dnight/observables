defmodule ScanTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :scan
  test "scan" do
    testproc = self()

    start = 1
    tend = 50

    # Create a range.
    Obs.range(start, tend, 100)
    |> Obs.scan(fn x, y -> x + y end)
    |> Obs.each(fn v ->
      Logger.debug("Sending #{inspect(v, charlists: :as_lists)}")
      send(testproc, v)
    end)

    # Receive all the values.
    Enum.scan(1..50, fn x, y -> x + y end)
    |> Enum.map(fn v ->
      receive do
        ^v -> :ok
      after
        10000 ->
          assert "Did not receive item in time: #{inspect(v)}" == ""
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
