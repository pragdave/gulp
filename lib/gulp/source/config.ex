defmodule Gulp.Source.Config do

  use Gulp.Config,
      fields:   [
        { :function, required: true },
      ],
      based_on: Gulp.Config.Emitter


end
