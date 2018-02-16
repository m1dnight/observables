defmodule Observables.Obs do

alias Observable.{Random, Printer, Map, Filter, ProducerConsumer}

# GENERATORS ###################################################################
 
    def random() do
        {:ok, pid} = GenServer.start_link(Random, [])
        fn(observer) ->
            Random.subscribe(pid, observer)
        end
    end

# CONSUMER AND PRODUCER ########################################################

    def map(observable_fn, f) do
        # Create the mapper function.
        mapper = fn(v) ->
            new_v = f.(v)
            {:next_value, new_v}
        end
        create_producer_consumer(observable_fn, mapper)
    end

    def filter(observable_fn, f) do
        # Creat the wrapper for the filter function.
        filterer = fn(v) ->
            if f.(v) do
                {:next_value, v}
            else
                {:no_value, "filter did not match"}
            end
        end
        create_producer_consumer(observable_fn, filterer)
    end

# TERMINATORS ##################################################################

    def print(observable_fn) do
        {:ok, pid} = GenServer.start_link(Printer, [])
        observable_fn.(pid)
    end

# HELPERS ######################################################################


defp create_producer_consumer(observable_fn, action) do
    # Start the producer/consumer server.
    {:ok, pid} = GenServer.start_link(ProducerConsumer, action)

    # Creat the continuation.
    fn(observer) ->
        observable_fn.(pid)
        ProducerConsumer.subscribe(pid, observer)
    end
end

end