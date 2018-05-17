defmodule CombineLatestTest do
  use ExUnit.Case
  alias Observables.{Obs, Subject}
  require Logger

  @tag :combinelatest
  test "Combine Latest" do
    testproc = self()

    xs = Subject.create()

    ys = Subject.create()

    Obs.combinelatest(xs, ys, left: nil, right: nil)
    |> Obs.map(fn v -> send(testproc, v) end)

    # Send first value, should not produce.
    Subject.next(xs, :x0)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    # Send second value, should produce.
    Subject.next(ys, :y0)
    assert_receive({:x0, :y0}, 1000, "did not get this message!")

    # Update the left observable. Shoudl produce with history.
    Subject.next(xs, :x1)
    assert_receive({:x1, :y0}, 1000, "did not get this message!")

    Subject.next(ys, :y1)
    assert_receive({:x1, :y1}, 1000, "did not get this message!")

    # Send a final value, should produce.
    Subject.next(xs, :xfinal)
    assert_receive({:xfinal, :y1}, 1000, "did not get this message!")

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end
end
