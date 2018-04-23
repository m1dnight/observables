defmodule Observables.Map do
  @moduledoc """
  Range takes a start and end value and produces all the values in between.
  """
  use Observables.GenObservable

  def init([proc]) do
    Logger.debug "Map: #{inspect self()}"
    {:ok, %{:proc => proc}} # We don't keep state in merge.
  end

  def handle_event(v, state = %{:proc => proc}) do
    {:value, proc.(v), state}
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
