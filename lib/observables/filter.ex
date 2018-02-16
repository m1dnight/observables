defmodule Observable.Filter do
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
    if state.state.func.(value) do
      notify_all(value, state.observers)
    end
    {:noreply, state}
  end

  # Helpers ####################################################################

  defp notify_all(value, observers) do
    observers
    |> Enum.map(fn(obs) -> send(obs, {:new_value, value}) end)
  end

end
