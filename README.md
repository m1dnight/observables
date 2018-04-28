# Observables

An implementation of Reactive Extensions in Elixir.

The library is a work in progress and I'm only implementing what I need.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `observables` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:observables, "~> 0.1.0"}
  ]
end
```

## TODO

 - A `zip` observable should stop as soon as one of both observables stops *and* the buffer has been consumed. 
 - At this point we send some meta-messages to observables (e.g., `Chunk`) to control the way they produce values. These values we use are in the domain (which is infinite) of the values that the observable could produce. This should be fixed to a seperate meta-layer of the observable. We could send `{:meta, <cmd>}` to the observable, because that can not be mixed with `{:event, <value>}`.