defmodule Observables.Operator.Map do
  @moduledoc false
  use Observables.GenObservable

  def init([proc]) do
    Logger.debug("Map: #{inspect(self())}")
    # We don't keep state in merge.
    {:ok, %{:proc => proc}}
  end

  def handle_event(v, state = %{:proc => proc}) do
    {:value, proc.(v), state}
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
