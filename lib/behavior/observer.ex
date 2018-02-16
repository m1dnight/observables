defmodule Observable do

    defstruct  observers: [], observed: [], last: [], state: %{}

    @callback subscribe(pid(), pid()) :: :ok

    @callback unsubscribe(pid(), pid()) :: :ok

    @callback notify_all(any, any) :: any

    defmacro __using__(_) do
        quote do
            use GenServer

              # Automatically subscribes an observer to us.
              def subscribe(observee_pid, observer_pid) do
                GenServer.call(observee_pid, {:subscribe, observer_pid})
              end
            
              # Automatically unsubscribes an observer.
              def unsubscribe(observee_pid, observer_pid) do
                GenServer.cast(observee_pid, {:unsubscribe, observer_pid})
              end

              def handle_call({:subscribe, pid}, _from, state) do
                {:reply, :ok, %{state | observers: [pid | state.observers]}}
              end
            
              def handle_call({:ubsubscribe, pid}, _from, state) do
                new_subs =  state.observers
                            |> Enum.filter(fn(sub) -> sub != pid end)
            
                {:reply, :ok, %{state | observers: new_subs}}
              end          
              
              # Notifies all the subscribers of a new value.
              defp notify_all(value, observers) do
                observers
                |> Enum.map(fn(obs) -> send(obs, {:new_value, value}) end)
              end
        end
    end
end