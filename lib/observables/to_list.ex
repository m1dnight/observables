defmodule Observables.Operator.ToList do
  @moduledoc false
  use Observables.GenObservable

  def init([action, state]) do
    {:ok, %{:state => state, :action => action}}
  end

  def handle_event(e, %{:state => s, :action => a}) do
    case a.(e, s) do
      {:value, v, new_s} ->
        {:value, v, %{:state => new_s, :action => a}}

      {:novalue, new_s} ->
        {:novalue, %{:state => new_s, :action => a}}

      {:buffer, v, new_s} ->
        {:buffer, v, %{:state => new_s, :action => a}}

      {:done, new_s} ->
        Logger.debug("done")
        {:done, new_s}
    end
  end

  def handle_done(_pid, state) do
    {:ok, state}
  end
end
