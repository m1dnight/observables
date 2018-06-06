defmodule DistinctUntilChangedTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :distinctuntilchanged
  test "distinctuntilchanged" do
    testproc = self()

    xs = [1, 1, 2, 2, 3, 3]

    expected = [1, 2, 3]

    xs
    |> Obs.from_enum(100)
    |> Obs.distinctuntilchanged()
    |> Obs.map(fn v -> send(testproc, v) end)

    expected
    |> Enum.map(fn x ->
      assert_receive(^x, 1000, "did not get this message!")

      receive do
        ^x -> assert "duplicates" == ""
      after
        1000 -> :ok
      end
    end)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end
end
