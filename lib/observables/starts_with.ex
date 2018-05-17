defmodule Observables.Operator.StartsWith do
  @moduledoc false
  use Observables.GenObservable

  def init([]) do
    Logger.debug("Starts With: #{inspect(self())}")
    # No state for startswith.
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
