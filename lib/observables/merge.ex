defmodule Observables.Operator.Merge do
  @moduledoc false
  use Observables.GenObservable

  def init([]) do
    Logger.debug("Merge: #{inspect(self())}")
    # We don't keep state in merge.
    {:ok, nil}
  end

  def handle_event(v, _state) do
    {:value, v, nil}
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
