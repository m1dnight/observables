defmodule CombineLatestSilentTest do
  use ExUnit.Case
  alias Observables.{Obs, GenObservable}
  require Logger

  @tag :combinelatestsilent
  test "Combine Latest Silent" do
    # 1      2      3     
    # 11          12     13     14     15
    # ===================================
    # 1/11   2/11   3/12          

    testproc = self()

    {:ok, pid1} = GenObservable.spawn_supervised(Observables.Subject)
    xs = Obs.from_pid(pid1)

    {:ok, pid2} = GenObservable.spawn_supervised(Observables.Subject)
    ys = Obs.from_pid(pid2)

    Obs.combinelatestsilent(xs, ys, left: nil, right: nil, silent: :right)
    |> Obs.inspect()
    |> Obs.map(fn v -> send(testproc, v) end)

    # Send first value, should not produce.
    GenObservable.send_event(pid1, :x0)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    # Send second value, should  not produce because silent.
    GenObservable.send_event(pid2, :y0)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    # Update the left observable. Should produce with history.
    GenObservable.send_event(pid1, :x1)
    assert_receive({:x1, :y0}, 5000, "did not get this message {:x1, :y0}!")

    # Update the right observable, should be silent.
    GenObservable.send_event(pid2, :y1)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    GenObservable.send_event(pid2, :y2)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    GenObservable.send_event(pid2, :y3)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end

    # Send a final value, should produce.
    GenObservable.send_event(pid1, :x2)
    assert_receive({:x2, :y3}, 1000, "did not get this message {:x2, :y3}!")

    # Mailbox should be empty.
    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      100 -> :ok
    end
  end
end
