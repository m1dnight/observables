defmodule ToListTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger
  @tag :take
  test "ToList" do
    testproc = self()

    xs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]

    res =
      xs
      |> Obs.from_enum(100)
      |> Obs.to_list()

    res == xs
  end

  test "ToList take a few" do
    testproc = self()

    xs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]

    res =
      xs
      |> Obs.from_enum(100)
      |> Obs.take(2)
      |> Obs.to_list()

    res == [1, 2]
  end
end
