defmodule Observables.CombineLatest do
  @moduledoc false
  use Observables.GenObservable

  def init([]) do
    Logger.debug("CombineLatest: #{inspect(self())}")
    {:ok, {:left, nil, :right, nil}}
  end

  def handle_event(value, state) do
    case {value, state} do
      # No values at all, and got a left.
      {{:left, vl}, {:left, nil, :right, nil}} ->
        {:novalue, {:left, vl, :right, nil}}

      # No values yet, and got a right.
      {{:right, vr}, {:left, nil, :right, nil}} ->
        {:novalue, {:left, nil, :right, vr}}

      # Already have left, now got right.
      {{:right, vr}, {:left, vl, :right, nil}} ->
        {:value, {vl, vr}, {:left, nil, :right, nil}}

      # Already have a left, and received a left.
      {{:left, vl}, {:left, _vl, :right, nil}} ->
        {:novalue, {:left, vl, :right, nil}}

      # Already have a right value, and now received left.
      {{:left, vl}, {:left, nil, :right, vr}} ->
        {:value, {vl, vr}, {:left, nil, :right, nil}}

      # Already have a right, and received a right.
      {{:right, vr}, {:left, nil, :right, _vr}} ->
        {:novalue, {:left, nil, :right, vr}}
    end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: zip has one dead dependency, stopping.")
    {:ok, :done}
  end
end
