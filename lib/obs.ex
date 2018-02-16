defmodule Observables.Obs do

alias Observable.{Random, Printer, Map, Filter}

# GENERATORS ###################################################################
 
    def random() do
        {:ok, pid} = GenServer.start_link(Random, [])
        fn(observer) ->
            Random.subscribe(pid, observer)
        end
    end

# CONSUMER AND PRODUCER ########################################################

    def map(observable_fn, f) do
        {:ok, pid} = GenServer.start_link(Map, f)
        fn(observer) ->
            observable_fn.(pid)
            Map.subscribe(pid, observer)
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