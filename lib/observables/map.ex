defmodule Observable.Map do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use Observable
  require Logger

  # Initialization
  def start_link(action) do
    GenServer.start_link(__MODULE__, action, [name: __MODULE__])
  end

  def init(action) do
    state = %Observable{
      state: %{:action => action},
      observers: [],
      observed: [],
      last: [],
    }

    {:ok, state}
  end

  def handle_info({:new_value, value}, state) do
    output = state.state.action.(value)
    notify_all(output, state.observers)
    {:noreply, state}
  end

end
