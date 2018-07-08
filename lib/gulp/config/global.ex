defmodule Gulp.Config.Global do

  use Gulp.Config,
      fields: [
        { :name, required: true },
        { :next, required: true },
     ]

end
