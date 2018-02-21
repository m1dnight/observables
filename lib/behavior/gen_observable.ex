defmodule Observables.GenObservable do
    require Logger
    import GenServer 
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

    
    def handle_call({:subscribe, pid}, _from, state) do
      {:reply, :ok, %{state | observers: [pid | state.observers]}}
    end

    
    def handle_call({:unsubscribe, pid}, _from, state) do
      new_subs =  state.observers
                  |> Enum.filter(fn(sub) -> sub != pid end)
    
      {:reply, :ok, %{state | observers: new_subs}}
    end          

    
    def handle_cast({:notify_all, value}, state) do
      state.observers
      |> Enum.map(fn(obs) -> GenObservable.send_event(obs, value) end)  
      {:noreply, state}            
    end
    

    def handle_cast({:event, value}, state) do
      case state.module.handle_event(value, state.state) do
        {:value, value, s} -> 
          cast(self(), {:notify_all, value})
          {:noreply, %{state | state: s}}
        {:novalue, s} -> 
          {:noreply, %{state | state: s}}
        {:done, s} ->
          Logger.debug "Stopping"
          {:stop, :normal, :done, %{state | state: s}}
      end
    end

    def handle_info({:event, value}, state) do
      cast(self(), {:event, value})
      {:noreply, state}
    end

    def terminate(reason, _status) do
      IO.puts "#{inspect self()} asked to stop because #{inspect reason}"
      :ok 
    end 

    
    #######
    # API #
    #######
    
    @doc """
    Sends a message to observee_pid that observer_pid no longer wants to be notified of events.
    """
    def subscribe(observee_pid, observer_pid) do
      call(observee_pid, {:subscribe, observer_pid})
    end

    
    @doc """
    Sends a message to observee_pid that observer_pid needs to be notified of new events.
    """
    def unsubscribe(observee_pid, observer_pid) do
      cast(observee_pid, {:unsubscribe, observer_pid})
    end

    @doc """
    Sends a new_value message to this GenObservable, such that it procudes a new value 
    for its dependees.
    """
    def send_event(observee_pid, value) do
      cast(observee_pid, {:event, value})
    end

end
