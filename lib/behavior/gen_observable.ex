defmodule Observables.GenObservable do
    require Logger
    import GenServer 
    import Enum
    alias Observables.GenObservable
    
    defstruct  observers: [], observed: [], last: [], state: %{}, module: :nil

    @callback init(args :: term) :: any

    @callback handle_event(message :: any, state :: any) :: any

    
    defmacro __using__(_) do
        quote location: :keep do
         
        end
    end


    ###################
    # GenServer Stuff #
    ###################
    
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

    def spawn_supervised(module, args) do
      Observables.Supervisor.add_child(__MODULE__, [module, args])
    end
    
    @doc """ 
    This function is called by the GenServer process. Here we call the init function f the module provided
    by the programmer.
    """
    def init({mod, args}) do
      case  mod.init(args) do
        {:ok, state} ->
          # Initial state of Observable
          {:ok, %GenObservable{state: state, module: mod}}
        _ ->
          {:stop, {:bad_return_value, :error}}
      end
    end

    
    def handle_cast({:subscribe, pid}, state) do
      {:noreply, %{state | observers: [pid | state.observers]}}
    end

    def handle_cast({:subscribe_to, pid}, state) do
      {:noreply, %{state | observed: [pid | state.observed]}}
    end

    
    def handle_cast({:unsubscribe, pid}, state) do
      new_subs =  state.observers
                  |> Enum.filter(fn(sub) -> sub != pid end)
    
      {:noreply, %{state | observers: new_subs}}
    end          

    def handle_cast({:unsubscribe_to, pid}, state) do
      new_subs =  state.observed
                  |> Enum.filter(fn(sub) -> sub != pid end)
    
      {:noreply, %{state | observed: new_subs}}
    end 
    
    def handle_cast({:notify_all, value}, state) do
      state.observers
      |> Enum.map(fn(obs) -> GenObservable.send_event(obs, value) end)  
      {:noreply, state}            
    end

    def handle_cast(:stop, state) do
      Logger.debug "#{inspect self()} - stopping"
      state.observers 
      |> Enum.map(fn(obs) -> cast(obs, {:dependency_stopping, self()}) end)
      {:stop, :normal, state}
    end

    def handle_cast({:dependency_stopping, pid}, state) do
      Logger.debug "#{inspect self()} - dependency #{inspect pid} stopping"
      # Remove observee.
      new_subs =  state.observed
                  |> Enum.filter(fn(sub) -> sub != pid end)

      if count(new_subs) == 0 do
        Logger.debug "#{inspect self()} - Listening to nobody anymore, going offline."
        cast(self(), :stop)
      end

      {:noreply, %{state | observed: new_subs}}
    end
    

    def handle_cast({:event, value}, state) do
      case state.module.handle_event(value, state.state) do
        {:value, value, s} -> 
          cast(self(), {:notify_all, value})
          {:noreply, %{state | state: s}}
        {:novalue, s} -> 
          {:noreply, %{state | state: s}}
        {:done, s} ->
          cast(self(), :stop)
          {:noreply, %{state | state: s}}
      end
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
    def subscribe(observee_pid, observer_pid) do
      cast(observee_pid, {:subscribe, observer_pid})
      cast(observer_pid, {:subscribe_to, observee_pid})
    end

    @doc """
    Sends a message to observee_pid that observer_pid no longer wants to be notified of events.
    """
    def unsubscribe(observee_pid, observer_pid) do
      cast(observee_pid, {:unsubscribe, observer_pid})
      cast(observer_pid, {:ubsubscribe_to, observee_pid})
    end

    @doc """
    Sends a new_value message to this GenObservable, such that it procudes a new value 
    for its dependees.
    """
    def send_event(observee_pid, value) do
      cast(observee_pid, {:event, value})
    end

end
