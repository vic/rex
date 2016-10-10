defmodule Rex do

  defmacro __using__(_) do
    quote do
      import Rex
      import Rex.Stack
      import Rex.Control
      import Rex.Math
    end
  end

  import Rex.Core

  @doc ~S"""
  Define a new Rex function.

  You can call `drex` in two ways, the first is
  to define a new _word_ that *operates on the stack*,
  here for example `double` is a partial application multiplying by two:

      drex double         2 ~> Kernel.*/2

  The second way is to define a _word_ for *stack shuffling*,
  ie, for example `Rex.Stack.swap/1` is defined like:

      drex swap(a, b)     (b, a)

  """
  defmacro drex({{name, _, patterns}, _, exprs}) when length(patterns) > 0 do
    rex_def({:def, :stack_effect}, {name, patterns, exprs})
  end

  defmacro drex({name, _, [expr]}) do
    rex_def({:def, :stack_expr}, {name, expr}, __CALLER__)
  end

  @doc """
  Compile a Rex expression into an Elixir function.

  The returned anonymous function can be given a stack to operate on.
  """
  defmacro rex(expr) do
    rex_fn(expr, __CALLER__)
  end

  @doc ~S"""
  Pipe an exising stack to a new Rex expression.

      [5, 2, 3] |> rex(double ~> swap ~> double) #=> [4, 10, 3]

  """
  defmacro rex(stack, expr) when is_list(stack) do
    quote do
      unquote(stack) |> unquote(rex_fn(expr, __CALLER__)).()
    end
  end

end

