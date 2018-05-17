defmodule Observables.Operator.CombineLatestSilent do
  @moduledoc false
  use Observables.GenObservable

  # silent == :left or :right
  def init([left_initial, right_initial, silent]) do
    Logger.debug("CombineLatest: #{inspect(self())}")
    {:ok, {:left, left_initial, :right, right_initial, :silent, silent}}
  end

  def handle_event(value, state) do
    {:left, l, :right, r, :silent, s} = state

    case {value, l, r, s} do
      # No values yet.
      {{:left, vl}, nil, nil, _} ->    	       
        {:novalue, {:left, vl, :right, nil, :silent, s}}

      {{:right, vr}, nil, nil, _} ->		
        {:novalue, {:left, nil, :right, vr, :silent, s}}

      # Have one value, and got a newever version of that value.
      {{:left, vl}, _, nil, _} ->	       
        {:novalue, {:left, vl, :right, nil, :silent, s}}

      {{:right, vr}, nil, _, _} ->  		
        {:novalue, {:left, nil, :right, vr, :silent, s}}

      # Already have the other value.
      {{:left, vl}, nil, vr, :right} ->    	       
        {:value, {vl, vr}, {:left, vl, :right, vr, :silent, s}}

      {{:left, vl}, nil, vr, :left} ->  	       
        {:novalue, {:left, vl, :right, vr, :silent, s}}

      {{:right, vr}, vl, nil, :right} ->  		
        {:novalue, {:left, vl, :right, vr, :silent, s}}

      {{:right, vr}, vl, nil, :left} ->
        {:value, {vl, vr}, {:left, vl, :right, vr, :silent, s}}

      # We have a history for both, and now we got a new one.
      {{:left, vl}, _, vr, :left} ->
        {:novalue, {:left, vl, :right, vr, :silent, s}}

      {{:left, vl}, _, vr, :right} ->
        {:value, {vl, vr}, {:left, vl, :right, vr, :silent, s}}

      {{:right, vr}, vl, _, :left} ->
        {:value, {vl, vr}, {:left, vl, :right, vr, :silent, s}}

      {{:right, vr}, vl, _, :right} ->
        {:novalue, {:left, vl, :right, vr, :silent, s}}
    end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: combinelatest has one dead dependency, going on.")
    {:ok, :continue}
  end
end
