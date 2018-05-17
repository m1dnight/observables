defmodule ObservablesTest do
  use ExUnit.Case
  alias Observables.{Obs, GenObservable}
  require Logger

  @tag :frompid
  test "Test from pid" do
    testproc = self()
    {:ok, pid1} = GenObservable.spawn_supervised(Observables.Subject, 0)

    Obs.from_pid(pid1)
    |> Obs.map(fn v -> send(testproc, :ok) end)

    GenObservable.send_event(pid1, :value)
    GenObservable.send_event(pid1, :value)

    receive do
      :ok -> :ok
    end

    receive do
      :ok -> :ok
    end

    assert 5 == 5
  end
end
