defmodule DelayTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :delay
  test "delay" do
    Code.load_file("test/util.ex")
    testproc = self()

    # Create a range.
    Obs.range(1, 500, 100)
    |> Obs.delay(1000)
    |> Obs.each(fn v ->
      Logger.error("Got #{v}")
      send(testproc, v)
    end)

    # Receive no other values.
    receive do
      _x ->
        Logger.error("Received another value, did not want")
        assert "received another value:" == ""
    after
      0 ->
        :ok
    end

    1..5
    |> Enum.map(fn v ->
      assert_receive(^v, 5000, "did not get this message #{v}")
    end)
  end
end
