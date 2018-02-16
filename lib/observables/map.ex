defmodule Observable.Map do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use Observable
  require Logger

  # Initialization
  def start_link(f) do
    GenServer.start_link(__MODULE__, f, [name: __MODULE__])
  end

  def init(f) do
    Logger.debug "Initializing Random"
    state = %Observable{
      state: %{:func => f},
      observers: [],
      observed: [],
      last: [],
    }

    {:ok, state}
  end

  # API ########################################################################

  # Callbacks ##################################################################

  def handle_info({:new_value, value}, state) do
    output = state.state.func.(value)
    notify_all(output, state.observers)
    {:noreply, state}
  end

end
