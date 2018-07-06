defmodule Gulp.Util do
  def is_module?(mod, _err) when is_atom(mod) do
    mod
  end

  def is_module?(mod = {:__aliases__, _context, [name] }, _err) when is_atom(name) do
    mod
  end

  def is_module?(other, err) do
    err.(other)
  end

end
