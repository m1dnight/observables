defmodule Observables.Action do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use Observables.GenObservable

  def init(action) do
    {:ok, action}
  end

  def handle_event(e, action) do
    case action.(e) do
      {:value, v} -> {:value, v, action}
      {:novalue} -> {:novalue, action}
    end
  end
end
