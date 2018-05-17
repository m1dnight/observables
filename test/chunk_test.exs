defmodule ChunkTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :chunk
  test "chunk" do
    testproc = self()

    start = 1
    tend = 50
    size = 5

    # Create a range.
    Obs.range(start, tend, 100)
    # We should consume 5 values each time.
    |> Obs.chunk(size * 100 + 10)
    |> Obs.each(fn v ->
      Logger.debug("Sending #{inspect(v, charlists: :as_lists)}")
      send(testproc, v)
    end)

    # Receive all the values.
    Enum.chunk_every(1..50, size)
    |> Enum.map(fn list ->
      Logger.debug("Waiting for #{inspect(list, charlists: :as_lists)}")

      receive do
        ^list -> Logger.debug("Got list #{inspect(list, charlists: :as_lists)}")
      after
        10000 ->
          assert "Did not receive list in time: #{inspect(list, charlists: :as_lists)}" == ""
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
