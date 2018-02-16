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

        # Start the producer/consumer server.
        {:ok, pid} = GenServer.start_link(ProducerConsumer, mapper)

        # Creat the continuation.
        fn(observer) ->
            observable_fn.(pid)
            ProducerConsumer.subscribe(pid, observer)
        end
    end

    def filter(observable_fn, f) do
        {:ok, pid} = GenServer.start_link(Filter, f)
        fn(observer) ->
            observable_fn.(pid)
            Filter.subscribe(pid, observer)
        end
    end

# TERMINATORS ##################################################################

    def print(observable_fn) do
        {:ok, pid} = GenServer.start_link(Printer, [])
        observable_fn.(pid)
    end

end