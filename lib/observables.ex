defmodule Observables do
  use Observables.GenObservable

  alias Observables.{Obs, GenObservable}
  require Logger

  def init(args) do
    {:ok, args}
  end

  def handle_event(message, state) do
    # We reply with :value if we want the value to propagate through the dependency graph.
    {:value, message, state}
  end

  def test_switch do
    {:ok, pid1} = GenObservable.spawn_supervised(Observables, 0)

    x =
      1..100
      |> Enum.to_list()
      |> Obs.from_enum()

    y =
      100..1000
      |> Enum.to_list()
      |> Obs.from_enum()

    # We will send observables to this observable
    # such that it "produces a stream of observables"
    IO.puts("Switch: #{inspect(pid1)}")

    Obs.from_pid(pid1)
    |> Obs.switch()
    |> Obs.print()

    # returned for debugging
    {pid1, x, y}
  end
end
