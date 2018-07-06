defmodule Gulp.Wrap do

  @type reason  :: error :: atom | { error :: atom, info :: map() }
  @type when_ok :: ( result :: any() -> none() )
  @type when_not_ok :: ( reason :: reason() -> none() )

  @type wrapped_function :: (
    ( msg :: any, when_ok:: when_ok(), when_not_ok:: when_not_ok() ) -> none()
  )

  @spec wrap(fun :: function()) :: result :: wrapped_function()
  def wrap(fun) do
    fn (msg, when_ok, when_not_ok) ->
      case fun.(msg) do
        :ok ->
          when_ok.(:ok)
        { :ok, result } ->
          when_ok.(result)
        other ->
          when_not_ok.(other)
      end
    end
  end

  def wrap(m, f) do
    wrap(fn a -> apply(m, f, a) end)
  end
end
