defmodule A do

    def init(args) do
        {:ok, args}
    end

    def handle_event(message, state) do
        # We reply with :value if we want the value to propagate through the dependency graph.
        {:value, message, state}
    end

    def test do
        x = GenObservable.start_link(A, 0)
        x   
    end
end

