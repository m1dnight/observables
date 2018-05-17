defmodule Observables.Operator.CombineLatest do
  @moduledoc false
  use Observables.GenObservable

  def init([left_initial, right_initial]) do
    Logger.debug("CombineLatest: #{inspect(self())}")
    {:ok, {:left, left_initial, :right, right_initial}}
  end

  def handle_event(value, state) do
    case {value, state} do
      # No values yet.
      {{:left, vl}, {:left, nil, :right, nil}} ->
        {:novalue, {:left, vl, :right, nil}}

      {{:right, vr}, {:left, nil, :right, nil}} ->
        {:novalue, {:left, nil, :right, vr}}

      # Already have the other value.
      {{:left, vl}, {:left, nil, :right, vr}} ->
        {:value, {vl, vr}, {:left, vl, :right, vr}}

      {{:right, vr}, {:left, vl, :right, nil}} ->
        {:value, {vl, vr}, {:left, vl, :right, vr}}

      # Have one value, and got a newever version of that value.
      {{:left, vl}, {:left, _lv, :right, nil}} ->
        {:novalue, {:left, vl, :right, nil}}

      {{:right, vr}, {:left, nil, :right, _vr}} ->
        {:novalue, {:left, nil, :right, vr}}

      # We have a history for both, and now we got a new one.
      {{:left, vl}, {:left, _vl, :right, vr}} ->
        {:value, {vl, vr}, {:left, vl, :right, vr}}

      {{:right, vr}, {:left, vl, :right, _vr}} ->
        {:value, {vl, vr}, {:left, vl, :right, vr}}
    end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: combinelatest has one dead dependency, going on.")
    {:ok, :continue}
  end
end
