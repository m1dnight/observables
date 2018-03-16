defmodule Observables.Switch do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use Observables.GenObservable

  def init([action, state]) do
    {:ok, %{:state => state, :action => action}}
  end

  def handle_event({:forward, v}, state) do
    Logger.debug "Forwarding: #{inspect v}"
    {:value, v, state}
  end

  def handle_event(e, %{:state => s, :action => a}) do
    case a.(e, s) do
      {:value, v, new_s} -> {:value, v, %{:state => new_s, :action => a}}
      {:novalue, new_s} -> {:novalue, %{:state => new_s, :action => a}}
      {:done, new_s} -> {:done, new_s}
      _ -> Logger.error("Invalid return value from Observable action!")
    end
  end

  def handle_done(pid, state) do
    Logger.debug("#{inspect(self())} - #{inspect(pid)} is done")
    {:ok, state}
  end
end
