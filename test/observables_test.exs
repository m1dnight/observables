defmodule ObservablesTest do
  use ExUnit.Case
  alias Observables.{Obs, GenObservable}
  require Logger

  def sleep(ms) do
    Logger.debug("Sleeping for #{ms}")

    receive do
      :nevergonnahappen -> :ok
    after
      ms -> Logger.debug("Woken up")
    end
  end

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

  @tag :fromenum
  test "Test from enum" do
    testproc = self()

    xs = [1, 2, 3]

    xs
    |> Obs.from_enum(1000)
    |> Obs.map(fn v -> send(testproc, v) end)

    xs
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    assert 5 == 5
  end
  @tag :merge
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

    sleep(3000)
    assert 5 == 5
  end

  @tag :map
  test "Map" do
    testproc = self()

    xs = [1, 1, 1, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.map(fn x -> x + 100 end)
    |> Obs.map(fn v -> send(testproc, v) end)

    Enum.map(xs, fn x -> x + 100 end)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    assert 5 == 5
  end

  test "Distinct" do
    testproc = self()

    xs = [1, 1, 1, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.distinct()
    |> Obs.map(fn v -> send(testproc, v) end)

    Enum.uniq(xs)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end

      receive do
        ^x -> assert "duplicates" == ""
      after
        1000 -> :ok
      end
    end)

    assert 5 == 5
  end

  test "Filter" do
    testproc = self()

    xs = [1, 2, 3, 1, 2, 3, 3, 2, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.filter(fn x -> x > 2 end)
    |> Obs.map(fn v -> send(testproc, v) end)

    xs
    |> Enum.filter(fn x -> x > 2 end)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    assert 5 == 5
  end

  test "Starts with" do
    testproc = self()

    first = [0]
    xs = [1, 2, 3]

    xs
    |> Obs.from_enum(100)
    |> Obs.starts_with(first)
    |> Obs.map(fn v -> send(testproc, v) end)

    (xs ++ first)
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    assert 5 == 5
  end

  test "switch" do
    testproc = self()

    {:ok, pid} = GenObservable.spawn_supervised(Observables, 0)

    Obs.from_pid(pid)
    |> Obs.switch()
    |> Obs.map(fn v -> send(testproc, v) end)

    x =
      1..5
      |> Enum.to_list()
      |> Obs.from_enum()

    Logger.debug("Setting new observable x")
    GenObservable.send_event(pid, x)
    sleep(10000)

    y =
      6..10
      |> Enum.to_list()
      |> Obs.from_enum()

    Logger.debug("Setting new observable y")
    GenObservable.send_event(pid, y)

    1..10
    |> Enum.map(fn x ->
      receive do
        v -> Logger.debug("Got #{v}")
      end
    end)

    assert 5 == 5
  end

  @tag :range
  test "range" do
    testproc = self()

    Obs.range(1, 5, 500)
    |> Obs.map(fn x -> send(testproc, x) end)

    1..5
    |> Enum.map(fn x ->
      receive do
        v -> Logger.debug("Got #{v}")
      end
    end)

    assert 5 == 5
  end

  @tag :zip
  test "zip" do
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

    sleep(5000)
  end

  @tag :zip
  test "zip uneven inputs" do
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

    sleep(5000)
  end
end
