defmodule Test.Gulp.Source do

  use   ExUnit.Case
  alias Gulp.Source


  defmodule Receiver do
    use GenServer
    @me __MODULE__

    def start() do
      { :ok, pid } = GenServer.start_link(__MODULE__, [], name: @me)
      pid
    end

    def get_messages() do
      GenServer.call(@me, { :get_messages })
    end

    def stop() do
      GenServer.stop(@me, :normal)
    end

    def init(_), do: { :ok, [] }

    def handle_cast({ :process, value}, messages) do
      { :noreply, [ value | messages ]}
    end

    def handle_call({ :get_messages }, _, messages) do
      { :reply, Enum.reverse(messages), [] }
    end
  end

  def sender(config, emit) do
    emit.(config.name)
    emit.("aaa")
    emit.("bbb")
    emit.("ccc")
  end

  test "basic functionality" do
    receiver = Receiver.start()
    config = [ name: :test1, next: receiver, function: &sender/2 ]
    Source.start_link(config)
    Source.run(:test1)

    :timer.sleep(10) # wait for casts to be handled

    received = Receiver.get_messages()
    Receiver.stop
    assert length(received) == 4
    assert [ :test1, "aaa", "bbb", "ccc" ] == received
  end

end
