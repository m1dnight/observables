defmodule CombineLatestSilentTest do
  use ExUnit.Case
  alias Observables.{Obs, Subject}
  require Logger

  @tag :combinelatestsilent
  test "Combine Latest Silent" do
    # 1      2      3     
    # 11          12     13     14     15
    # ===================================
    # 1/11   2/11   3/12          

    testproc = self()

    # {:ok, pid1} = GenObservable.spawn_supervised(Observables.Subject)
    xs = Subject.create()

    ys = Subject.create()

    Obs.combinelatestsilent(xs, ys, left: nil, right: nil, silent: :right)
    |> Obs.map(fn v -> send(testproc, v) end)

    # Send first value, should not produce.
    Subject.next(xs, :x0)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    # Send second value, should  not produce because silent.
    Subject.next(ys, :y0)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    # Update the left observable. Should produce with history.
    Subject.next(xs, :x1)
    assert_receive({:x1, :y0}, 5000, "did not get this message {:x1, :y0}!")

    # Update the right observable, should be silent.
    Subject.next(ys, :y1)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    Subject.next(ys, :x2)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    Subject.next(ys, :y3)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    # Send a final value, should produce.
    Subject.next(xs, :x2)
    assert_receive({:x2, :y3}, 1000, "did not get this message {:x2, :y3}!")

    # Mailbox should be empty.
    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end
  end
end
