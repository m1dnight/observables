defmodule Observables.Operator.Switch do
  @moduledoc false
  use Observables.GenObservable
  alias Observables.GenObservable
  alias Observables.Obs

  def init([]) do
    {:ok, nil}
  end

  def handle_event({:forward, v}, state) do
    {:value, v, state}
  end

  def handle_event(new_obs, s) do
    switcher = self()

    # Unsubscribe to the previous observer we were forwarding.
    if s != nil do
      {:forwarder, forwarder, :sender, observable} = s
      {_f, pidf} = forwarder
      GenObservable.stop_send_to(pidf, self())
      {_f, pids} = observable
      GenObservable.stop_send_to(pids, pidf)
    end

    # We subscribe to this observable.
    # {_, obsvpid} = observable
    # GenObservable.send_to(obsvpid, self())

    forwarder =
      new_obs
      |> Obs.map(fn v -> GenObservable.send_event(switcher, {:forward, v}) end)

    {:novalue, {:forwarder, forwarder, :sender, new_obs}}
  end

  def handle_done(_pid, state) do
    {:ok, state}
  end
end
