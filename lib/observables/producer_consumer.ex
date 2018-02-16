defmodule Observable.ProducerConsumer do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use Observable

  # Initialization
  def start_link(action) do
    GenServer.start_link(__MODULE__, action)
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
    case output do
      {:next_value, v} -> notify_all(v, state.observers)
      {:no_value, _e}  -> :ok
      _                -> raise "invalid return value from action: #{inspect output}"
    end
    {:noreply, state}
  end

end
