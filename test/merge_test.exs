defmodule MergeTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :merge
  test "Merge" do
    Code.load_file("test/util.ex")

    testproc = self()

    xs = [1, 2, 3]
    ys = [4, 5, 6]

    ys
    |> Obs.from_enum(100)
    |> Obs.merge(Obs.from_enum(xs, 100))
    |> Obs.map(fn v -> send(testproc, v) end)

    (xs ++ ys)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    Test.Util.sleep(3000)
    assert 5 == 5
  end
end
