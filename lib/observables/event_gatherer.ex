defmodule EventGatherer do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """

  require Logger
  use Observable

  # Initialization
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(state) do
    new_state = %Observable{state: state}
    {:ok, new_state}
  end

  def handle_call(:new_event, _from, state) do
    notify_all(2, state.observers)
    {:reply, :ok, state}
  end
end
