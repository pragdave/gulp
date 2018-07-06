defmodule Gulp.Sequence do

  alias Gulp.Util

  def sequence(steps) do
    steps
  end

  defmacro seq({ :with, _context, list }) when is_list(list) do
    list
    |> Enum.map(&Util.is_module?(&1, fn error -> report_call_error(error) end))
  end

  defmacro seq(other) do
    report_call_error(other)
  end


  defp report_call_error(other) do
    raise """

    \nInvalid form of `seq with`. Expecting a comma-separated list of modules.

    Got:

    #{Macro.to_string(other)}

    """
  end

  def execute(seq, initial_arg) do
    Enum.reduce(seq, { :ok, initial_arg }, &run_a_step/2)
  end

  def run_a_step(module, :ok) do
    module.transform(nil)
  end

  def run_a_step(module, { :ok, val }) do
    module.transform(val)
  end

  def run_a_step(_module, other) do
    other
  end
end

# defmodule B do
#   defmodule Module1 do
#     def transform(x), do: { :ok, x * 2 }
#   end

#   defmodule Mod2 do
#     def transform(x), do: { :ok, x+1 }
#   end

#   defmodule Mod3 do
#     def transform(x), do: { :ok, x*3 }
#   end

#   require Gulp.Sequence
#   import Gulp.Sequence
#   seq = seq with Module1, Mod2, Mod3

#   IO.inspect Gulp.Sequence.execute(seq, 11)
# end
