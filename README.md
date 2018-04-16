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