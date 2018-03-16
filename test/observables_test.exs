defmodule ObservablesTest do
  use ExUnit.Case
  alias Observables.{Obs, GenObservable}

  doctest Observables

  test "Test from pid" do
    testproc = self()
    {:ok, pid1} = GenObservable.spawn_supervised(Observables, 0)

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

  test "Test from enum" do
    testproc = self()

    xs = [1, 2, 3]

    xs
    |> Obs.from_enum(100)
    |> Obs.map(fn v -> send(testproc, v) end)

    xs
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    assert 5 == 5
  end

  test "Merge" do
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

    assert 5 == 5
  end
end
