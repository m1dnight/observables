defmodule A do

    def init(args) do
        {:ok, args}
    end

    def handle_event(message, state) do
        {:notify_all, message, state}
    end


    def test do
        x = GenObservable.start_link(A, 0)
        x   
    end
end

