defmodule Observables.Operator.Delay do
  @moduledoc false
  use Observables.GenObservable
  require Logger

  def init([delay]) do
    {:ok, %{:delay => delay}}
  end

  def handle_event(v, state = %{:delay => delay}) do
    Logger.warn("Got this: #{inspect(v)}")

    case v do
      {:delayed, x} ->
        {:value, x, state}

      v ->
        Logger.warn("Sending after #{delay}: #{inspect(v)}")
        Process.send_after(self(), {:event, {:delayed, v}}, delay)
        {:novalue, state}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :done}
  end
end
