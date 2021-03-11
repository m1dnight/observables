defmodule Observables.Operator.DistinctUntilChanged do
  @moduledoc false
  use Observables.GenObservable

  def init([comparator]) do
    Logger.debug("Distinct Until Changed: #{inspect(self())}")
    {:ok, %{:comp => comparator, :last => []}}
  end

  def handle_event(v, state = %{:comp => f, :last => last}) do
    same? = f.(v, last)

    if not same? do
      {:value, v, %{:comp => f, :last => last}}
    else
      {:novalue, state}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :done}
  end
end
