defmodule UnsubscribeTest do
  use ExUnit.Case
  alias Observables.{Obs}
  require Logger

  @tag :unsubscribe
  test "ubsubscribe" do
    Code.load_file("test/util.ex")

    testproc = self()

    Obs.range(1, :infinity, 500)
    |> Obs.map(fn v ->
      if v > 5 do
        Observables.Observable.unsubscribe()
      else
        send(testproc, v)
      end
    end)

    Test.Util.sleep(2000)

    1..5
    |> Enum.map(fn v ->
      assert_receive(^v, 5000, "did not get this message #{v}")
    end)
  end
end
