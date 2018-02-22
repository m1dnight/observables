defmodule Observables.Obs do
    alias Observables.{Action, StatefulAction, GenObservable}
    
    
# GENERATORS ###################################################################
 
    def from_pid(pid) do
        fn(observer) ->
            GenObservable.subscribe(pid, observer)
        end
    end

    @doc """
    Takes an enumerable and will "spit" each value one by one, every delay seconds.
    If the enum is consumed, returns done.
    """
    def from_enum(coll, delay \\ 1000) do
        action = fn(:spit, state) ->
            case state do
                []     -> {:done, state}
                [x|xs] -> Process.send_after(self(), {:event, :spit}, delay)
                          {:value, x, xs}
            end
        end

        {:ok, pid} = GenObservable.start(StatefulAction, [action, coll])

        Process.send_after(pid, {:event, :spit}, delay)

        fn(observer) ->
            GenObservable.subscribe(pid, observer)
        end
    end

# CONSUMER AND PRODUCER ########################################################

    def map(observable_fn, f) do
        # Create the mapper function.
        mapper = fn(v) ->
            new_v = f.(v)
            {:value, new_v}
        end
        create_action(observable_fn, mapper)
    end

    def each(observable_fn, f) do
        # Create the mapper function.
        eacher = fn(v) ->
            f.(v)
            {:value, v}
        end
        create_action(observable_fn, eacher)
    end

    def filter(observable_fn, f) do
        # Creat the wrapper for the filter function.
        filterer = fn(v) ->
            if f.(v) do
                {:value, v}
            else
                {:novalue}
            end
        end
        create_action(observable_fn, filterer)
    end

    
    def starts_with(observable_fn, start_vs) do
        action = fn(v) ->
            {:value, v}
        end

        # Start the producer/consumer server.
        {:ok, pid} = GenObservable.start_link(Action, action)

        # Creat the continuation.
        fn(observer) ->
            
            GenObservable.subscribe(pid, observer)
            # After the subscription has been made, send all the start values to the producer.
            for v <- start_vs do
                GenObservable.send_event(pid, v)
            end

            observable_fn.(pid)
        end
    end


# TERMINATORS ##################################################################

    def print(observable_fn) do
        action = fn(v) -> IO.puts(v) ; {:value, v} end
        create_consumer(observable_fn, action)
    end

# HELPERS ######################################################################


    defp create_action(observable_fn, action) do
        # Start the producer/consumer server.
        {:ok, pid} = GenObservable.start_link(Action, action)

        # Creat the continuation.
        fn(observer) ->
            observable_fn.(pid)
            GenObservable.subscribe(pid, observer)
        end
    end

    defp create_stateful_action(observable_fn, action, state) do
        # Start the producer/consumer server.
        {:ok, pid} = GenObservable.start_link(StatefulAction, [action, state])

        # Creat the continuation.
        fn(observer) ->
            observable_fn.(pid)
            GenObservable.subscribe(pid, observer)
        end
    end

    defp create_consumer(observable_fn, action) do
        {:ok, pid} = GenObservable.start_link(Action, action)
        observable_fn.(pid)
        :ok
    end
end