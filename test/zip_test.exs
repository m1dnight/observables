defmodule ZipTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :zip
  test "zip" do
    Code.load_file("test/util.ex")
    testproc = self()

    Obs.range(1, 5, 500)
    |> Obs.zip(Obs.range(1, 5, 500))
    |> Obs.map(fn x -> send(testproc, x) end)

    1..5
    |> Enum.map(fn x ->
      receive do
        {^x, ^x} -> Logger.debug("Got #{inspect({x, x})}")
      end
    end)

    Test.Util.sleep(5000)
  end

  @tag :zip
  test "zip uneven inputs" do
    Code.load_file("test/util.ex")
    testproc = self()

    Obs.range(1, 5, 500)
    |> Obs.zip(Obs.range(1, 10, 500))
    |> Obs.map(fn x -> send(testproc, x) end)

    1..5
    |> Enum.map(fn x ->
      receive do
        {^x, ^x} -> Logger.debug("Got #{inspect({x, x})}")
      end
    end)

    Test.Util.sleep(5000)
  end
end
