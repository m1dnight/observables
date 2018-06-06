defmodule Observables.Operator.DistinctUntilChanged do
  @moduledoc false
  use Observables.GenObservable

  def init([comparator]) do
    Logger.debug("Distinct Until Changed: #{inspect(self())}")
    {:ok, %{:comp => comparator, :seen => []}}
  end

  def handle_event(v, state = %{:comp => f, :seen => xs}) do
    seen? = Enum.any?(xs, fn seen -> f.(v, seen) end)

    if not seen? do
      {:value, v, %{:comp => f, :seen => []}}
    else
      {:novalue, state}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
