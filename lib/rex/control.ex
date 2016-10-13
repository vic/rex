defmodule Rex.Control do

  @doc ~S"""
  If-Then-Else evaluates `then` quoted expression if `cond` is truthy
  otherwise evaluates `else` quoted expression

      [cond, then, else | s]

      [true, [x], [y] | s] -> [x | s]
      [nil,  [x], [y] | s] -> [y | s]

  """
  #drex ifte(true, then_expr, _) ({:dequote, [], nil}, then_expr)
  #drex ifte(_, _, else_expr) ({:dequote, [], nil}, else_expr)

  def ifte({[true, then_expr, _ | data], prog, env}) do
    {[then_expr | data], [Rex.Macro.dequote_fn(env) | prog], env}
  end

  def ifte({[_, _, else_expr | data], prog, env}) do
    {[else_expr | data], [Rex.Macro.dequote_fn(env) | prog], env}
  end

  def dequote({data, prog, env}) do
    {data, [Rex.Macro.dequote_fn(env) | prog], env}
  end

end
