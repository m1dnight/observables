defmodule ObservablesTest do
  use ExUnit.Case
  alias Observables.{Obs, GenObservable}
  require Logger

  def sleep(ms) do
    receive do
      :nevergonnahappen -> :ok
    after
      ms -> :ok
    end
  end
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

  @tag :distinct
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

  @tag :each
  test "Each" do
    testproc = self()

    xs = [1, 1, 1, 1]

    xs
    |> Obs.from_enum(100)
    |> Obs.each(fn x -> IO.inspect(x) end)
    |> Obs.map(fn v -> send(testproc, v) end)

    xs
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert 5 == 10
    after
      1000 ->
        :ok
    end

    assert 5 == 5
  end

  @tag :filter
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

    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x)}" == ""
    after
      1000 ->
        :ok
    end
  end

  @tag :startswith
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

    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x)}" == ""
    after
      1000 ->
        :ok
    end
  end

  @tag :switch
  test "switch" do
    testproc = self()

    {:ok, pid} = GenObservable.spawn_supervised(Observables.Subject, 0)

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

  @tag :repeat
  test "repeat" do
    testproc = self()

    Obs.repeat(
      fn ->
        send(testproc, :hello)
      end,
      interval: 500,
      times: 5
    )

    [:hello, :hello, :hello, :hello, :hello]
    |> Enum.map(fn x ->
      receive do
        ^x -> Logger.debug("Got #{x}")
      end
    end)

    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x)}" == ""
    after
      1000 ->
        :ok
    end

    assert 5 == 5
  end

  @tag :buffer
  test "buffer" do
    testproc = self()

    start = 1
    tend = 100
    size = 3

    # Create a range.
    Obs.range(start, tend, 100)
    |> Obs.buffer(size)
    |> Obs.each(fn v ->
      Logger.debug("Sending #{inspect(v)}")
      send(testproc, v)
    end)

    # Receive all the values.
    Enum.chunk_every(1..100, size)
    |> Enum.map(fn list ->
      Logger.debug("Waiting for #{inspect(list)}")

      receive do
        ^list -> Logger.debug("Got list #{inspect(list)}")
      end
    end)

    # Receive no other values.
    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value:" == ""
    after
      1000 ->
        :ok
    end
  end

  @tag :chunk
  test "chunk" do
    testproc = self()

    start = 1
    tend = 50
    size = 5

    # Create a range.
    Obs.range(start, tend, 100)
    # We should consume 5 values each time.
    |> Obs.chunk(size * 100 + 10)
    |> Obs.each(fn v ->
      Logger.debug("Sending #{inspect(v, charlists: :as_lists)}")
      send(testproc, v)
    end)

    # Receive all the values.
    Enum.chunk_every(1..50, size)
    |> Enum.map(fn list ->
      Logger.debug("Waiting for #{inspect(list, charlists: :as_lists)}")

      receive do
        ^list -> Logger.debug("Got list #{inspect(list, charlists: :as_lists)}")
      after
        10000 ->
          assert "Did not receive list in time: #{inspect(list, charlists: :as_lists)}" == ""
      end
    end)

    # Receive no other values.
    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x, charlists: :as_lists)} " == ""
    after
      1000 ->
        :ok
    end
  end

  @tag :scan
  test "scan" do
    testproc = self()

    start = 1
    tend = 50

    # Create a range.
    Obs.range(start, tend, 100)
    |> Obs.scan(fn x, y -> x + y end)
    |> Obs.each(fn v ->
      Logger.debug("Sending #{inspect(v, charlists: :as_lists)}")
      send(testproc, v)
    end)

    # Receive all the values.
    Enum.scan(1..50, fn x, y -> x + y end)
    |> Enum.map(fn v ->
      receive do
        ^v -> :ok
      after
        10000 ->
          assert "Did not receive item in time: #{inspect(v)}" == ""
      end
    end)

    # Receive no other values.
    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x, charlists: :as_lists)} " == ""
    after
      1000 ->
        :ok
    end
  end

  @tag :take
  test "Take" do
    testproc = self()

    xs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]

    xs
    |> Obs.from_enum(100)
    |> Obs.take(4)
    |> Obs.map(fn v -> send(testproc, v) end)

    [1, 2, 3, 4]
    |> Enum.map(fn x ->
      receive do
        ^x -> :ok
      end
    end)

    # Receive no other values.
    receive do
      x ->
        Logger.error("Received another value, did not want")
        assert "received another value: #{inspect(x, charlists: :as_lists)} " == ""
    after
      1000 ->
        :ok
    end
  end

  @tag :combinelatest
  test "Combine Latest" do
    testproc = self()

    
    {:ok, pid1} = GenObservable.spawn_supervised(Observables.Subject)
    xs = Obs.from_pid(pid1)

    {:ok, pid2} = GenObservable.spawn_supervised(Observables.Subject)
    ys = Obs.from_pid(pid2)

    Obs.combinelatest(xs, ys)
    |> Obs.inspect()
    |> Obs.map(fn v -> send(testproc, v) end)

    # Send first value, should not produce.
    GenObservable.send_event(pid1, :x0)

    receive do
      x -> flunk "Mailbox was supposed to be empty, got: #{inspect x}"
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
      x -> flunk "Mailbox was supposed to be empty, got: #{inspect x}"
    after 
      0 -> :ok
    end
  end
end
