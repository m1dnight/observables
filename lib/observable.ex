defmodule Observables.Observable do
  alias Observables.GenObservable

  @moduledoc """
  WRITE ME PLEASE KIND SIR
  """

  def unsubscribe() do
    GenObservable.unsubscribe(self())
  end
end
