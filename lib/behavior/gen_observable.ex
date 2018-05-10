defmodule Observables.GenObservable do
  @moduledoc false
  require Logger
  import GenServer
  import Enum
  alias Observables.GenObservable
  use GenServer

  defstruct listeners: [], listeningto: [], last: [], state: %{}, module: nil

  @callback init(args :: term) :: any

  @callback handle_event(message :: any, state :: any) :: any

  @callback handle_done(pid :: any, state :: any) :: any

  defmacro __using__(_) do
    quote location: :keep do
      require Logger

      def handle_done(pid, _state) do
        {:ok, :continue}
      end

      defoverridable handle_done: 2
    end
  end

  ###################
  # GenServer Stuff #
  ###################

  def child_spec(arg) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, arg}
    }

    Supervisor.child_spec(default, [])
  end

  @doc """
  This function is called when a programmer starts his module:
  Observable.start_link(MyObservable, initial_state)
  """
  def start_link(module, args, options \\ []) do
    GenServer.start_link(__MODULE__, {module, args}, options)
  end

  def start(module, args, options \\ []) do
    GenServer.start(__MODULE__, {module, args}, options)
  end

  def spawn_supervised(module, args \\ []) do
    Observables.Supervisor.add_child(__MODULE__, [module, args])
  end

  @doc """
  This function is called by the GenServer process. Here we call the init function f the module provided
  by the programmer.
  """
  def init({mod, args}) do
    case mod.init(args) do
      {:ok, state} ->
        # Initial state of Observable
        {:ok, %GenObservable{state: state, module: mod}}

      _ ->
        {:stop, {:bad_return_value, :error}}
    end
  end

  ################
  # Dependencies #
  ################

  def handle_cast({:send_to, pid}, state) do
    {:noreply, %{state | listeners: [pid | state.listeners]}}
  end

  def handle_cast({:listen_to, pid}, state) do
    {:noreply, %{state | listeningto: [pid | state.listeningto]}}
  end

  def handle_cast({:stop_sending_to, pid}, state) do
    new_subs =
      state.listeners
      |> Enum.filter(fn sub -> sub != pid end)

    {:noreply, %{state | listeners: new_subs}}
  end

  def handle_cast({:stop_listening_to, pid}, state) do
    new_subs =
      state.listeningto
      |> Enum.filter(fn sub -> sub != pid end)

    {:noreply, %{state | listeningto: new_subs}}
  end

  def handle_cast({:notify_all, value}, state) do
    state.listeners
    |> Enum.map(fn obs -> GenObservable.send_event(obs, value) end)

    {:noreply, state}
  end

  def handle_cast({:dependency_stopping, pid}, state) do
    Logger.warn(
      "Dependency (#{inspect(pid)}) is stopping. I (#{inspect(self())}) am currently depending on #{
        inspect(state.listeningto)
      }"
    )

    response = state.module.handle_done(pid, state.state)

    # We forward this event to the module first, and see what it wants to do.
    case response do
      {:ok, :done} ->
        Logger.debug("#{inspect(self())} stopping.")
        cast(self(), :stop)
        {:noreply, state}

      {:ok, :done, {:value, value}} ->
        Logger.debug("#{inspect(self())} stopping.")
        cast(self(), {:notify_all, value})
        cast(self(), :stop)
        {:noreply, state}

      {:ok, :continue} ->
        Logger.debug("#{inspect(self())} going on.")
        # Remove observee.
        new_subs =
          state.listeningto
          |> Enum.filter(fn sub -> sub != pid end)

        if count(new_subs) == 0 do
          Logger.warn("#{inspect(self())} all dependencies done, stopping ourselves.")
          cast(self(), :stop)
        end

        {:noreply, %{state | listeningto: new_subs}}
    end
  end

  ###################
  # Self Management #
  ###################

  def handle_cast(:stop, state) do
    Logger.warn("#{inspect(self())} am stopping")

    state.listeners
    |> Enum.map(fn obs -> cast(obs, {:dependency_stopping, self()}) end)

    {:stop, :normal, state}
  end

  def handle_cast({:event, value}, state) do
    case state.module.handle_event(value, state.state) do
      {:value, value, s} ->
        cast(self(), {:notify_all, value})
        {:noreply, %{state | state: s}}

      {:novalue, s} ->
        {:noreply, %{state | state: s}}

      {:buffer, value, s} ->
        GenServer.cast(self(), {:event, value})
        {:noreply, %{state | state: s}}

      {:done, value, s} ->
        # We are done, but produced a final value.
        cast(self(), {:notify_all, value})
        cast(self(), :stop)
        {:noreply, %{state | state: s}}

      {:done, s} ->
        cast(self(), :stop)
        {:noreply, %{state | state: s}}
    end
  end

  def handle_cast({:delay, delay}, state) do
    delay(delay)
    {:noreply, state}
  end

  def handle_info({:event, value}, state) do
    cast(self(), {:event, value})
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  #######
  # API #
  #######

  @doc """
  Sends a message to observee_pid that observer_pid needs to be notified of new events.

  """
  def send_to(producer, consumer) do
    cast(producer, {:send_to, consumer})
    cast(consumer, {:listen_to, producer})
  end

  @doc """
  Sends a message to observee_pid that observer_pid no longer wants to be notified of events.
  """
  def stop_send_to(producer, consumer) do
    cast(producer, {:stop_sending_to, consumer})
    cast(consumer, {:stop_listening_to, producer})
  end

  @doc """
  Sends a new_value message to this GenObservable, such that it procudes a new value
  for its dependees.
  """
  def send_event(consumer, value) do
    cast(consumer, {:event, value})
  end

  @doc """
  Throttles the GenObservable. It will lock it up for given timeperiod such that it can not send/receive events.
  """
  def delay(producer, delay) do
    cast(producer, {:delay, delay})
  end

  @doc """
  Makes an observable stop and gracefully shut down.
  """
  def stop(producer, reason \\ :normal) do
    cast(producer, {:stop, reason})
  end

  ###########
  # Helpers #
  ###########

  def delay(delay) do
    Process.send_after(self(), :delay, delay)

    receive do
      :delay -> :ok
    end
  end
end
