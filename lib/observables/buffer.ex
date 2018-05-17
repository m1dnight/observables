defmodule Observables.Operator.Buffer do
  @moduledoc false
  use Observables.GenObservable

  def init([size]) do
    Logger.debug("Buffer: #{inspect(self())}")
    # We don't keep state in merge.
    {:ok, %{:size => size, :buffer => []}}
  end

  def handle_event(v, %{:size => size, :buffer => bs}) do
    count = Enum.count(bs)

    case {bs, size, count} do
      {b, s, c} when s <= c ->
        {:value, b, %{:size => s, :buffer => [v]}}

      {b, s, c} when s > c ->
        {:novalue, %{:size => s, :buffer => b ++ [v]}}
        # {[], max_size, c} ->
        #   {:novalue, %{:max_size => max_size, :buffer => [v]}}
    end
  end

  def handle_done(pid, %{:size => _size, :buffer => bs}) do
    # We are buffering, and if our dependency stops we need to flush our buffer or we are losing values.
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :done, {:value, bs}}
  end
end
