defmodule Gulp.Config.Emitter do

  use Gulp.Config,
      fields: [
        { :next, required: true },
      ],
     based_on: Gulp.Config.Global

end
