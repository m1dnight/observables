defmodule Observables.Operator.FromEnum do
  @moduledoc false
  use Observables.GenObservable

  def init([coll, delay]) do
    {:ok, %{:coll => coll, :delay => delay}}
  end

  def handle_event(:spit, state = %{:coll => c, :delay => delay}) do
    case c do
      [] ->
        {:done, state}

      [x | xs] ->
        Process.send_after(self(), {:event, :spit}, delay)
        {:value, x, %{:coll => xs, :delay => delay}}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
