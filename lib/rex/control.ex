defmodule Rex.Control do

  import Rex

  @doc ~S"""
  If-Then-Else evaluates `then` quoted expression if `cond` is truthy
  otherwise evaluates `else` quoted expression

  [cond, then, else | s]

  [true, [x], [y] | s] -> [x | s]
  [nil,  [x], [y] | s] -> [y | s]
  """
  drex ifte(true, then_expr, _) ({:unquote, [], nil}, then_expr)
  drex ifte(_, _, else_expr) ({:unquote, [], nil}, else_expr)


end
