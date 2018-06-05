defmodule MergeNTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :mergen
  test "Merge-n" do
    Code.load_file("test/util.ex")

    testproc = self()

    xs = Enum.to_list(1..20)
    ys = Enum.to_list(1..20)
    zs = Enum.to_list(1..20)

    [xs, ys, zs]
    |> Enum.map(&Obs.from_enum(&1, 100))
    |> Obs.mergen()
    |> Obs.map(fn v -> send(testproc, v) end)

    (xs ++ ys ++ zs)
    |> Enum.map(fn x ->
      assert_receive(^x, 1000, "Did not receive #{x}")
    end)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end
end
