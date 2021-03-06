defmodule Gulp.Source do

  use GenServer

  alias Gulp.Source.Config

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def reconfigure(source, new_config) do
    GenServer.call(source, { :reconfigure, new_config })
  end

  def run(source) do
    GenServer.cast(source, { :run })
  end


  def init(config) do
    real_config = Config.new(config)
    true = Process.register(self(), real_config.name)
    { :ok,  real_config }
  end

  def handle_cast({ :run }, config) do
    emitter = fn value ->
      :ok = GenServer.cast(config.next, { :process, value })
    end

    config.function.(config, emitter)
    { :stop, :normal, config }
  end

  def handle_call({ :reconfigure, new_config }, _, config) do
    if new_config.name != config.name do
      raise """

      Reconfiguration may not change a source's name.

      Old config:

      #{inspect(config, pretty: true)}

      New config:

      #{inspect(new_config, pretty: true)}


      """
      { :reply, new_config, new_config }
    end
  end

end
