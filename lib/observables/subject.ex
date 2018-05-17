defmodule Observables.Operator.Subject do
  @moduledoc false
  use Observables.GenObservable
  require Logger

  def init(args) do
    {:ok, args}
  end

  def handle_event(message, state) do
    # We reply with :value if we want the value to propagate through the dependency graph.
    {:value, message, state}
  end
end
