defmodule CombineLatestTest do
  use ExUnit.Case
  alias Observables.{Obs, GenObservable}
  require Logger

  @tag :combinelatest
  test "Combine Latest" do
    testproc = self()

    {:ok, pid1} = GenObservable.spawn_supervised(Observables.Subject)
    xs = Obs.from_pid(pid1)

    {:ok, pid2} = GenObservable.spawn_supervised(Observables.Subject)
    ys = Obs.from_pid(pid2)

    Obs.combinelatest(xs, ys, left: nil, right: nil)
    |> Obs.inspect()
    |> Obs.map(fn v -> send(testproc, v) end)

    # Send first value, should not produce.
    GenObservable.send_event(pid1, :x0)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    # Send second value, should produce.
    GenObservable.send_event(pid2, :y0)
    assert_receive({:x0, :y0}, 1000, "did not get this message!")

    # Update the left observable. Shoudl produce with history.
    GenObservable.send_event(pid1, :x1)
    assert_receive({:x1, :y0}, 1000, "did not get this message!")

    GenObservable.send_event(pid2, :y1)
    assert_receive({:x1, :y1}, 1000, "did not get this message!")

    # Send a final value, should produce.
    GenObservable.send_event(pid1, :xfinal)
    assert_receive({:xfinal, :y1}, 1000, "did not get this message!")

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end
end
