defmodule Observable.Printer do
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

    {:ok, state}
  end

  # API ########################################################################



  def handle_info({:new_value, value}, state) do
    IO.puts value
    {:noreply, state}
  end

end
