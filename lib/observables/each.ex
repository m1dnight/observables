defmodule Observables.Operator.Each do
  @moduledoc false
  use Observables.GenObservable

  def init([proc]) do
    Logger.debug("Each: #{inspect(self())}")
    # We don't keep state in merge.
    {:ok, %{:proc => proc}}
  end

  def handle_event(v, state = %{:proc => proc}) do
    proc.(v)
    {:value, v, state}
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
