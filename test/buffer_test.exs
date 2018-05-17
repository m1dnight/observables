defmodule BufferTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :buffer
  test "buffer" do
    testproc = self()

    start = 1
    tend = 100
    size = 3

    # Create a range.
    Obs.range(start, tend, 100)
    |> Obs.buffer(size)
    |> Obs.each(fn v ->
      Logger.debug("Sending #{inspect(v)}")
      send(testproc, v)
    end)

    # Receive all the values.
    Enum.chunk_every(1..100, size)
    |> Enum.map(fn list ->
      Logger.debug("Waiting for #{inspect(list)}")

      receive do
        ^list -> Logger.debug("Got list #{inspect(list)}")
      end
    end)

    # Receive no other values.
    receive do
      _x ->
        Logger.error("Received another value, did not want")
        assert "received another value:" == ""
    after
      1000 ->
        :ok
    end
  end
end
