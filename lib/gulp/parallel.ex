defmodule Gulp.Parallel do


  defmacro parallel(arg, steps), do: do_parallel(arg, steps)
  defmacro      par(arg, steps), do: do_parallel(arg, steps)



  defp do_parallel(arg, { :with, context, steps }) when is_list(steps) do

    { transforms, expression } = extract_transforms_from(steps, [])

    variables_defined = validate_no_backreferences_in(transforms)

    check_all_variables_used(variables_defined,
                             expression,
                             { :"parallel with", context, steps })

    generate_code(arg, transforms, expression)
  end

  defp do_parallel(_arg, other) do
    report_call_error(other)
  end


  @error_msg """
  \nInvalid form of `parallel with`. Expecting

      par with v1 <- Mod1,
               v2 <- Mod2,
               . . .,
               do: «some expression involving v1, v2, ...»
  """

#  defp report_call_error(clause, specific \\ nil)

  @spec report_call_error(Macro.t) :: no_return()
  defp report_call_error(clause) do
    raise @error_msg <> """

    Got:

    #{Macro.to_string(clause)}

    """
  end

  # @spec report_call_error(Macro.t, Macro.t) :: no_return()
  # defp report_call_error(clause, detail) do
  #   raise @error_msg <> """

  #   Got #{Macro.to_string(detail)} in:

  #   #{Macro.to_string(clause)}

  #   """
  # end


  #-----------------------------------------------------------------------------+
  #  Convert `with a <- .., b <- .., do: ..` into the matching clauses and the  |
  #                                `do:` clause                                 |
  #-----------------------------------------------------------------------------+

  defp extract_transforms_from([ clause = { :<-, _context, [ _var, _module ]} | rest ], result) do
    extract_transforms_from(rest, [ clause | result ])
  end

  defp extract_transforms_from([[ do: expression ]], result) do
    { Enum.reverse(result), expression }
  end

  defp extract_transforms_from(other, _result) do
    report_call_error(other)
  end


  #-------------------------------------------------------------------------+
  #  Validate that no transform body contains a reference to the result of  |
  #                          a previous transform.                          |
  #-------------------------------------------------------------------------+

  defp validate_no_backreferences_in(transforms) do
    transforms
    |> Enum.reduce(_vars = MapSet.new, &check_for_back_reference/2)
  end

  defp check_for_back_reference(matcher = { :<-, _context, clause}, previous_vars) do
    [ target, expr ] = clause
    targets = vars_in(target)
    used    = vars_in(expr)
    common = MapSet.intersection(previous_vars, used)

    if MapSet.size(common) > 0 do
      raise """
      \n
      The line

          #{Macro.to_string(matcher)}

      contains references to the following variable(s) that are set asynchronously
      in previous clauses of a `parallel with` call:

          #{common |> Enum.map(&elem(&1, 0) |> to_string()) |> Enum.join(", ")}

      This isn't allowed, as we cannot guarantee synchronization between clauses.

      """

    end
    MapSet.union(targets, previous_vars)
  end


  #------------------------------------------------------------------------+
  #  Make sure all variables assigned matched in the parallel clauses are  |
  #                 actually used in the result expression                 |
  #------------------------------------------------------------------------+

  defp check_all_variables_used(variables, expression, par_clause) do
    used = vars_in(expression)
    variables = non_underscored_variables_in(variables)

    unused = MapSet.difference(variables, used)

    cond do
      MapSet.size(unused) == 0 ->
        :ok
      true ->
        list = unused |> MapSet.to_list |> Enum.map(&elem(&1, 0)) |> Enum.join("a, ")
        IO.puts :stderr, """
        \n
        The expression:

        #{Macro.to_string(par_clause)}

        sets the variable(s) `#{list}`, but these are not used
        in the final `do` expression. If you are just running that
        particular parallel clause for its side effect, then
        change the variable(s) to have a leading underscore.

        """
    end
  end

  defp non_underscored_variables_in(set) do
    set
    |> MapSet.to_list
    |> Enum.reject(fn { name, _ } -> name |> to_string() |> String.starts_with?("_") end)
    |> MapSet.new
  end


  @doc !"""
  Generate the code for the whole parallel with. We return a function which, when
  called, will execute the `with`.

      parallel(x) with a <- something,
                       b <- otherthing,
                      do: a + b

  becomes

      fn (x) ->
        tasks = [
          Task.await(fn -> something end)
          Task.await(fn -> otherthing end)
        ]
        case Gulp.Parallel.Waiter.await(tasks) do
          results ->
            [ a, b ] = results
            { :ok, a + b }
          other ->
            other
        end
      end
  """

  defp generate_code(arg, transformations, expression) do


    arg = arg |> update_variable_context()
    IO.inspect arg: arg

    { lhs, rhs } =
      transformations
      |> Enum.reduce({[],[]}, fn ({ :<-, _context, line}, { lhs, rhs }) ->
        [ l, r] = line
        {[ l | lhs ], [ r | rhs ]}
      end)

    lhs = lhs |> Enum.reverse |> update_variable_context()
    rhs = rhs |> Enum.reverse |> update_variable_context()
    expression = expression   |> update_variable_context()

    tasks = Enum.map(rhs, fn clause ->
      quote do
        Task.async(fn -> unquote(clause) end)
      end
    end)


    result = quote do
      fn unquote(arg) ->
        tasks_to_run = unquote(tasks)

        results = Gulp.Parallel.Waiter.await(tasks_to_run)

        cond do
          [{ :ok, _ } | _] = results ->
            unquote(lhs) = results |> Enum.map(&elem(&1, 1))
            { :ok, unquote(expression) }
          true ->
            results
        end
      end
    end

    result |> Macro.to_string |> IO.puts
    result
  end


  defp update_variable_context(expr) do
    Macro.prewalk(expr, nil, &maybe_update_variable/2)
    |> elem(0)
  end

  defp maybe_update_variable({ name, context, nil }, _) do
    {{ name, context, __MODULE__ }, nil }
  end

  defp maybe_update_variable(other, _) do
    { other, nil }
  end

  defp vars_in(expr) do
    Macro.prewalk([expr], MapSet.new, fn sub, acc -> maybe_add_variable(sub, acc) end)
    |> elem(1)
  end

  defp maybe_add_variable(var = { name, _context, nil }, acc) do
    { var, MapSet.put(acc, { name, nil })}
  end

  defp maybe_add_variable(other, acc) do
    { other, acc }
  end

end


defmodule B do
  require Gulp.Parallel

    func = Gulp.Parallel.parallel(value, (with  b <- { :ok, value + 99 } do
       b
    end))

    IO.inspect func.(123)

end
