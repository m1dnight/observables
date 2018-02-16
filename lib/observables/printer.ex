defmodule Observable.Printer do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use GenServer
  require Logger


  defstruct  observers: [], observed: [], last: [], state: %{}

  # Initialization
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(_opts) do
    Logger.debug "Initializing Random"
    state = %Observable.Random{
      state: %{},
      observers: [],
      observed: [],
      last: []
    }

    {:ok, state}
  end

  # API ########################################################################

  def subscribe(observee_pid, observer_pid) do
    GenServer.call(observee_pid, {:subscribe, observer_pid})
  end

  def ubsubscribe(observee_pid, observer_pid) do
    GenServer.cast(observee_pid, {:unsubscribe, observer_pid})
  end

  # Callbacks ##################################################################

  def handle_call({:subscribe, pid}, _from, state) do
    Logger.debug "#{inspect pid} subscribed"
    
    {:reply, :ok, %{state | observers: [pid | state.observers]}}
  end

  def handle_call({:ubsubscribe, pid}, _from, state) do
    Logger.debug "#{inspect pid} unsubscribed"

    new_subs =  state.observers
                |> Enum.filter(fn(sub) -> sub != pid end)

    {:reply, :ok, %{state | observers: new_subs}}
  end

  def handle_info({:new_value, value}, state) do
    IO.puts value
    {:noreply, state}
  end

  # Helpers ####################################################################

end
