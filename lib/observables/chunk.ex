defmodule Observables.Operator.Chunk do
  @moduledoc false
  use Observables.GenObservable

  def init([interval]) do
    Logger.debug("Chunk: #{inspect(self())}")
    {:ok, %{:interval => interval, :buffer => []}}
  end

  # If we receive this messsage, we flush the buffer.
  def handle_event(:flush, %{:interval => interval, :buffer => bs}) do
    Process.send_after(self(), {:event, :flush}, interval)

    case bs do
      [] ->
        {:novalue, %{:interval => interval, :buffer => []}}

      _xs ->
        {:value, bs, %{:interval => interval, :buffer => []}}
    end
  end

  # A regular value from the dependencies.
  def handle_event(v, %{:interval => interval, :buffer => bs}) do
    {:novalue, %{:interval => interval, :buffer => bs ++ [v]}}
  end

  def handle_done(pid, %{:interval => _interval, :buffer => bs}) do
    # We are buffering, and if our dependency stops we need to flush our buffer or we are losing values.
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")

    case bs do
      [] ->
        {:ok, :done}

      xs ->
        {:ok, :done, {:value, xs}}
    end
  end
end
