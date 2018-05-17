defmodule SubjectTest do
  use ExUnit.Case
  alias Observables.{Obs, Subject}
  require Logger

  @tag :subject
  test "subject" do
    Code.load_file("test/util.ex")

    # Create a subject.
    testproc = self()
    s = Subject.create()

    # Print out all the values that this subject produces,
    # and forward them to the testproc.
    s
    |> Obs.each(fn v -> send(testproc, {:test, v}) end)

    # Send some values to the subject, and make sure we receive them.
    Subject.next(s, 10)
    Subject.next(s, 20)
    Subject.next(s, 30)
    Test.Util.sleep(2000)

    assert_receive({:test, 10}, 1000, "did not get this message!")
    assert_receive({:test, 20}, 1000, "did not get this message!")
    assert_receive({:test, 30}, 1000, "did not get this message!")

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end
end
