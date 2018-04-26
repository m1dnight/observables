defmodule Observables.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(arg \\ []) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_child(module, opts) do
    spec = Supervisor.Spec.worker(module, opts, restart: :transient)
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
