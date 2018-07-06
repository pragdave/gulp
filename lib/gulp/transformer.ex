# defmodule Gulp.Transformer do

#   @callback initialize(config::map()) :: :ok
#   @callback reinitialize(old_config::map(), new_config::map()) :: :ok

#   @callback transform(msg::any(), config::map()) :: any()

#   defmacro __using__(_) do
#     quote do
#       @behaviour unquote(__MODULE__)
#       use GenServer


#       def reinitialize(old, new) do
#         :ok
#       end
#       defoverridable(reinitialize: 2)


#       def start_link(host_config, transformer_config) do
#         GenServer.start_link(unquote(__MODULE__), { host_config, transformer_config }, name: host_config.name)
#       end

#       def init(state) do
#         { :ok, state }
#       end

#       def handle_cast({ :do_transform, msg }, config = { host_config, transformer_config }) do
#         result = transform(msg, transformer_config)
#         send(host_config.target, result)
#         { :noreply, config }
#       end
#     end
#   end



# end
