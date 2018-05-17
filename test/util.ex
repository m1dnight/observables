defmodule Test.Util do
  def sleep(ms) do
    receive do
      :nevergonnahappen -> :ok
    after
      ms -> :ok
    end
  end
end
