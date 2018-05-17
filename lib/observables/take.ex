defmodule Observables.Operator.Take do
  @moduledoc false
  use Observables.GenObservable

  def init([n]) do
    Logger.debug("Take: #{inspect(self())}")
    # We don't keep state in merge.
    {:ok, %{:n => n}}
  end

  def handle_event(v, state = %{:n => n}) do
    case n do
      n when n <= 0 -> {:done, state}
      1 -> {:done, v, state}
      n -> {:value, v, %{:n => n - 1}}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
