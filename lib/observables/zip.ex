defmodule Observables.Operator.Zip do
  @moduledoc false
  use Observables.GenObservable

  def init([]) do
    Logger.debug("Zip: #{inspect(self())}")
    {:ok, {:left, [], :right, []}}
  end

  def handle_event(value, state) do
    case {value, state} do
      # No values at all, and got a left.
      {{:left, vl}, {:left, [], :right, []}} ->
        {:novalue, {:left, [vl], :right, []}}

      # No values yet, and got a right.
      {{:right, vr}, {:left, [], :right, []}} ->
        {:novalue, {:left, [], :right, [vr]}}

      # Already have left, now got right.
      {{:right, vr}, {:left, [vl | vls], :right, []}} ->
        {:value, {vl, vr}, {:left, vls, :right, []}}

      # Already have a right value, and now received left.
      {{:left, vl}, {:left, [], :right, [vr | vrs]}} ->
        {:value, {vl, vr}, {:left, [], :right, vrs}}

      # Already have a left, and received a left.
      {{:left, vln}, {:left, vls, :right, []}} ->
        {:novalue, {:left, vls ++ [vln], :right, []}}

      # Already have a right, and received a right.
      {{:right, vr}, {:left, [], :right, vrs}} ->
        {:novalue, {:left, [], :right, vrs ++ [vr]}}

      # Have left and right, and received a right.
      {{:right, vrn}, {:left, [vl | vls], :right, [vr | vrs]}} ->
        {:value, {vl, vr}, {:left, vls, right: vrs ++ [vrn]}}

      # Have left and right, and received a left.
      {{:left, vln}, {:left, [vl | vls], :right, [vr | vrs]}} ->
        {:value, {vl, vr}, {:left, vls ++ [vln], right: vrs}}
    end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: zip has one dead dependency, stopping.")
    {:ok, :done}
  end
end
