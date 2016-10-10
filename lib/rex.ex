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

  defmacro drex({{name, _, patterns}, _, exprs}) when length(patterns) > 0 do
    rex_def({:def, :stack_effect}, {name, patterns, exprs}, __CALLER__)
  end

  defmacro drex({name, _, [expr]}) do
    rex_def({:def, :stack_expr}, {name, expr}, __CALLER__)
  end

  defmacro rex(stack, expr) do
    quote do
      unquote(stack) |> unquote(rex_fn(expr, __CALLER__)).()
    end
  end

end

