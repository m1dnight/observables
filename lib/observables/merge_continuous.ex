defmodule Observables.Operator.MergeContinuous do
  @moduledoc false
  use Observables.GenObservable
  alias Observables.GenObservable
  alias Observables.Obs

  def init([]) do
    {:ok, []}
  end

  def handle_event({:forward, v}, state) do
    {:value, v, state}
  end

  def handle_event(new_obs, s) do
    merger = self()

    # Each value emitted by new_obs must be proxied through us.
    forwarder =
      new_obs
      |> Obs.map(fn v -> GenObservable.send_event(merger, {:forward, v}) end)

    {:novalue, [new_obs | s]}
  end

  def handle_done(_pid, state) do
    # TODO
    {:ok, state}
  end
end
