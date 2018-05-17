defmodule SwitchTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :switch
  test "switch" do
    Code.load_file("test/util.ex")
    testproc = self()

    s = Observables.Subject.create()

    s
    |> Obs.switch()
    |> Obs.map(fn v -> send(testproc, v) end)

    x =
      1..5
      |> Enum.to_list()
      |> Obs.from_enum()

    Logger.debug("Setting new observable x")
    Observables.Subject.next(s, x)
    Test.Util.sleep(10000)

    y =
      6..10
      |> Enum.to_list()
      |> Obs.from_enum()

    Logger.debug("Setting new observable y")
    Observables.Subject.next(s, y)

    1..10
    |> Enum.map(fn _x ->
      receive do
        v -> Logger.debug("Got #{v}")
      end
    end)

    assert 5 == 5
  end
end
