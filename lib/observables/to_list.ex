defmodule Observables.Operator.ToList do
  @moduledoc false
  use Observables.GenObservable

  def init([waiter]) do
    Logger.debug("ToList: #{inspect(self())}")
    {:ok, %{:buffer => [], :waiter => waiter}}
  end

  # A regular value from the dependencies.
  def handle_event(v, %{:waiter => waiter, :buffer => bs}) do
    {:novalue, %{:waiter => waiter, :buffer => bs ++ [v]}}
  end

  def handle_done(pid, %{:waiter => waiter, :buffer => bs}) do
    # The dependency has signaled it will no longer produce.
    # Send the buffer over to the waiting pid.
    Logger.debug("#{inspect(self())}: dependency stopping: #{inspect(pid)}")

    {pid, ref} = waiter
    send(pid, {ref, bs})
    {:ok, :done}
  end
end
