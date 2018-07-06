defmodule Test.Gulp.Wrap do

  use ExUnit.Case
  import Gulp.Wrap

  test "Wrap returns a function" do
    wrapped = wrap(fn a -> a end)
    assert is_function(wrapped, 3)
  end

  test "Wrapped function invokes ok_clause when value is :ok" do
    wrapped = wrap(fn _ -> :ok end)
    wrapped.(:ignored,
             fn result -> assert result == :ok end,
             fn _      -> flunk("error case should not be called") end)
  end

  test "Wrapped function invokes ok_clause when value is an :ok tuple" do
    wrapped = wrap(fn val -> { :ok, val + 1 } end)
    wrapped.(99,
             fn result -> assert result == 100 end,
             fn _      -> flunk("error case should not be called") end)
  end

  test "Wrapped function invokes not_ok_clause when result is not ok" do
    wrapped = wrap(fn val -> { :error, val + 1 } end)
    wrapped.(99,
             fn _      -> flunk(":ok case should not be called") end,
             fn result -> assert result == { :error, 100 } end)
  end

end
