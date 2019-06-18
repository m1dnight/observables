defmodule DistinctUntilChangedTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :distinctuntilchanged
  test "distinctuntilchanged" do
    testproc = self()

    xs = [1, 2, 3, 4, 1, 2, 3, 4]

    expected = [1, 2, 3, 4, 1, 2, 3, 4]

    xs
    |> Obs.from_enum(100)
    |> Obs.distinctuntilchanged()
    |> Obs.inspect()
    |> Obs.map(fn v -> send(testproc, v) end)

    expected
    |> Enum.map(fn x ->
      assert_receive(^x, 1000, "did not get this message! #{inspect(x)}")
    end)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end
end
