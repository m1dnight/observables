defmodule Observables.Scan do
  @moduledoc false
  use Observables.GenObservable

  def init([proc]) do
    Logger.debug("Scan: #{inspect(self())}")
    # We don't keep state in merge.
    {:ok, %{:proc => proc, :intermediate => nil}}
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
