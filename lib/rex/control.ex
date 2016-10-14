defmodule Rex.Control do

  @doc ~S"""
  If-Then-Else evaluates `then` quoted expression if `cond` is truthy
  otherwise evaluates `else` quoted expression

      [cond, then, else | s]

      [true, [x], [y] | s] -> [x | s]
      [nil,  [x], [y] | s] -> [y | s]

  """

  require Rex.Fun

  def ifte({[true, then_expr, _ | data], prog}) do
    {[then_expr | data], prog} |> dequote
  end

  def ifte({[_, _, else_expr | data], prog}) do
    {[else_expr | data], prog} |> dequote
  end

  def dequote({data, prog}) do
    {data, [Rex.Fun.dequote | prog]}
  end

end
