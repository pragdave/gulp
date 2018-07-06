defmodule Test.Gulp.Parallel do
  use ExUnit.Case

  require Gulp.Parallel
  import  Gulp.Parallel


  test "detects use of async variables in subsequent async clauses" do
    assert_raise RuntimeError, ~r/ontains references to the following variable\(s\) that are set asynchronously/s, fn ->
      Code.compile_string """
      require Gulp.Parallel
      import  Gulp.Parallel

        par with a <- 1,
                 b <- a + 1,
             do: a + b
      """
    end
  end

  test "detects use of async variables in subsequent async clauses (part 2)" do
    assert_raise RuntimeError, ~r/ontains references to the following variable\(s\) that are set asynchronously/s, fn ->
      Code.compile_string """
      require Gulp.Parallel
      import  Gulp.Parallel

        par with {a, _} <- {1, 2},
                 b      <- a + 1,
             do: a + b
      """
    end
  end

  test "detects use of async variables in subsequent async clauses (part 3)" do
      assert_raise RuntimeError, ~r/ontains references to the following variable\(s\) that are set asynchronously/s, fn ->
        Code.compile_string """
        require Gulp.Parallel
        import  Gulp.Parallel

          par with {a, _} <- {1, 2},
                   b      <- IO.puts(min(3, max(a, 1))),
               do: a + b
        """
      end
  end

  test "detects unused parallel assignments" do
    import ExUnit.CaptureIO

    output = capture_io(:stderr, fn ->
      Code.compile_string """
      require Gulp.Parallel
      import  Gulp.Parallel

      par with a <- 1,
               b <- 2,
          do:  a + 1
      """
    end)

    assert output =~ ~r/sets the variable\(s\) `b`, but these are not used/
  end


  test "ignores unused underscored variables in parallel assignments" do
    import ExUnit.CaptureIO

    output = capture_io(:stderr, fn ->
      Code.compile_string """
      require Gulp.Parallel
      import  Gulp.Parallel

      par with a <- 1,
              _b <- 2,
          do:  a + 1
      """
    end)

    assert output == ""
  end

  test "returns the correct result in the simple case" do
    func = parallel with a <- { :ok, 3 }, b <- { :ok, 5 }, do: a*b
    assert func.() == { :ok, 15 }
  end

  test "handles pattern matching" do
    func = parallel with { a, b }    <- { :ok, { 5, 7 } },
                         %{ val: c } <- { :ok, %{ other: 99, val: 11 } },
                     do: a*b*c
    assert func.() == { :ok, 5*7*11 }
  end

  test "works when passed a module name" do
    defmodule A do
      def transform(), do: { :ok, 11 }
    end
    defmodule B do
      def transform(), do: { :ok, 13 }
    end

    func = parallel with a <- A, b <- B, do: a*b

    assert func.() == { :ok, 11*13 }
  end

  test "works asynchronously" do
    func = parallel with a <- ( :timer.sleep(50); { :ok, 7 }),
                         b <- ( :timer.sleep(50); { :ok, 11 }),
                     do: a*b

    assert_took expected: { :ok, 77 }, min: 50, max: 60, func: func
  end


  test "works asynchronously with different timings" do
    func = parallel with a <- ( :timer.sleep(5);  { :ok, 7 }),
                         b <- ( :timer.sleep(50); { :ok, 11 }),
                     do: a*b

    assert_took expected: { :ok, 77 }, min: 50, max: 60, func: func
  end


  defp assert_took(options) do
    start_time = :erlang.timestamp
    result = options[:func].()
    end_time   = :erlang.timestamp
    assert result == options[:expected]
    diff = :timer.now_diff(end_time, start_time) / 1_000
    assert diff >= options[:min]
    assert diff <= options[:max]
  end

end
