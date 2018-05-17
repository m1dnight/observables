defmodule Observables.Subject do 
    alias Observables.GenObservable 

    @moduledoc """
    Subject defines functions to create and interact with subjects.

    A Subject is an observable which acts as a regular observer. It can be observed as usual, but it also allows the programmer to manually send messages to the process. The Subject will then emit the values.

    Have a look at test/subject_test.ex for a simple example.
    """

    def create() do
        {:ok, pid} = GenObservable.spawn_supervised(Observables.Operator.Subject)

        {fn observer ->
            GenObservable.send_to(pid, observer)
          end, pid}
    end

    def next({_f, pid}, v) do
        GenObservable.send_event(pid, v) 
    end
end
