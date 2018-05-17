defmodule RepeatTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :repeat
  test "repeat" do
    testproc = self()

    Obs.repeat(
      fn ->
        send(testproc, :hello)
      end,
      interval: 500,
      times: 5
    )

    [:hello, :hello, :hello, :hello, :hello]
    |> Enum.map(fn x ->
      receive do
        ^x -> Logger.debug("Got #{x}")
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

    assert 5 == 5
  end
end
