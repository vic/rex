defmodule Rex.Control do

  @doc ~S"""
  If-Then-Else evaluates `then` quoted expression if `cond` is truthy
  otherwise evaluates `else` quoted expression

      [cond, then, else | s]

      [true, [x], [y] | s] -> [x | s]
      [nil,  [x], [y] | s] -> [y | s]

  """

  require Rex.Fun

  def ifte({[true, then_expr, _ | stack], queue}) do
    {[then_expr | stack], queue} |> dequote
  end

  def ifte({[_, _, else_expr | stack], queue}) do
    {[else_expr | stack], queue} |> dequote
  end

  def dequote({stack, queue}) do
    {stack, [Rex.Fun.dequote | queue]}
  end

end
