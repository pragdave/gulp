defmodule Gulp.HostInfo do

  @type t :: %__MODULE__{}

  defstruct(
    name:   nil,
    target: nil    # pid or name
  )
end
