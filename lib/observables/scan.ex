defmodule Observables.Operator.Scan do
  @moduledoc false
  use Observables.GenObservable

  def init([proc, default]) do
    Logger.debug("Scan: #{inspect(self())}")
    # We don't keep state in merge.
    {:ok, %{:proc => proc, :intermediate => default}}
  end

  def handle_event(v, %{:proc => proc, :intermediate => i}) do
    case i do
      nil ->
        {:value, v, %{:proc => proc, :intermediate => v}}

      x ->
        res = proc.(v, x)
        {:value, res, %{:proc => proc, :intermediate => res}}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :done}
  end
end
