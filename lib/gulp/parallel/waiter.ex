defmodule Gulp.Parallel.Waiter do

  @doc """
  Given a list of tasks, await each. If any returns anything other than
  ':ok' or '{ :ok, result }', cancel the remaining tasks and return
  the error value. Otherwise return a list of the return values for each task.
  """

  def await(task_list) do
    Enum.reduce(task_list, [], &await_one_task/2)
    |> case do
       { :__abort__, reason } -> reason
       results                -> results |> Enum.reverse
       end
  end

  defp await_one_task(task, error = { :abort, _reason }) do
    Task.shutdown(task, :brutal_kill)
    error
  end

  defp await_one_task(task, results) do
    task
    |> Task.await
    |> decode_result(results)
  end

  defp decode_result(:ok, results) do
    [ { :ok, :ok } | results ]
  end

  defp decode_result({ :ok, result }, results) do
    [ { :ok, result } | results ]
  end

  defp decode_result(other, _) do
    { :__abort__, other }
  end
end
