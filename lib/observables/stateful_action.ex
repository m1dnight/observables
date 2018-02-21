defmodule Observables.StatefulAction do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use Observables.GenObservable

  def init([action, state]) do
    {:ok, %{:state => state, :action => action}}
  end

  def handle_event(e, %{:state => s, :action => a}) do
    case a.(e, s) do
      {:value, v, new_s} -> {:value, v, %{:state => new_s, :action => a}}
      {:novalue, new_s}  -> {:novalue, %{:state => new_s, :action => a}}
      {:done, new_s}     -> {:done, new_s}
    end
  end

  def handle_done(pid, state) do
    Logger.debug "#{inspect self()} - #{inspect pid} is done"
    {:ok, state}
  end
end
