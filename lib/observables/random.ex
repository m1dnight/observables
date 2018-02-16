defmodule Observable.Random do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use Observable 
  require Logger

  # Initialization
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(_opts) do
    Logger.debug "Initializing Random"
    state = %Observable{
      state: %{},
      observers: [],
      observed: [],
      last: []
    }

    # Start generating values.
    generate()

    {:ok, state}
  end

  # API ########################################################################

  # Callbacks ##################################################################

  def handle_info(:generate, state) do
    value = generate()
    notify_all(value, state.observers)
    {:noreply, state}
  end

  # Helpers ####################################################################

  defp notify_all(value, observers) do
    observers
    |> Enum.map(fn(obs) -> send(obs, {:new_value, value}) end)
  end

  defp generate() do
    Process.send_after(self(), :generate, 10)
    :rand.uniform(100)
  end

end
