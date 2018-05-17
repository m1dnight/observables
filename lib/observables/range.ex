defmodule Observables.Operator.Range do
  @moduledoc false
  use Observables.GenObservable

  def init([first, last, delay]) do
    Logger.debug("Range: #{inspect(self())}")
    {:ok, %{:first => first, :last => last, :current => first, :delay => delay}}
  end

  def handle_event(
        :tick,
        state = %{:first => first, :last => last, :current => current, :delay => delay}
      ) do
    case {current, last} do
      {current, :infinity} ->
        Process.send_after(self(), {:event, :tick}, delay)

        {:value, current,
         %{:first => first, :last => last, :current => current + 1, :delay => delay}}

      {current, last} when current > last ->
        {:done, state}

      {current, _last} ->
        Process.send_after(self(), {:event, :tick}, delay)

        {:value, current,
         %{:first => first, :last => last, :current => current + 1, :delay => delay}}
    end
  end

  def handle_done(pid, _state) do
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")
    {:ok, :continue}
  end
end
