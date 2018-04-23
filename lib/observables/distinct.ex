defmodule Observables.Distinct do
  @moduledoc """
  Range takes a start and end value and produces all the values in between.
  """
  use Observables.GenObservable

  def init([comparator]) do
    Logger.debug("Distinct: #{inspect(self())}")
    {:ok, %{:comp => comparator, :seen => []}}
  end

  def handle_event(v, state = %{:comp => f, :seen => xs}) do
    seen? = Enum.any?(xs, fn seen -> f.(v, seen) end)

    if not seen? do
      {:value, v, %{:comp => f, :seen => [v | xs]}}
    else
      {:novalue, state}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end