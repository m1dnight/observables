defmodule EachTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :each
  test "Each" do
    testproc = self()

    xs = [1, 1, 1, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.each(fn x -> IO.inspect(x) end)
    |> Obs.map(fn v -> send(testproc, v) end)

    xs
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    receive do
      _x ->
        Logger.error("Received another value, did not want")
        assert 5 == 10
    after
      1000 ->
        :ok
    end

    assert 5 == 5
  end
end
