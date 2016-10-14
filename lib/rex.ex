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
  """
  defmacro drex({{name, _, patterns}, _, exprs}) when length(patterns) > 0 do
    rex_def({:def, :shuffler}, {name, patterns, exprs}, __CALLER__)
  end

  defmacro drex({name, _, [expr]}) do
    rex_def({:def, :operator}, {name, nil, expr}, __CALLER__)
  end

  defmacro drex({name, _, args}, expr = [do: _]) do
    rex_def({:def, :operator}, {name, args, expr}, __CALLER__)
  end

  @doc """
  Compile a Rex expression into an Elixir function.
  """
  defmacro rex(expr) do
    rex_fn(expr, __CALLER__)
  end

  @doc ~S"""
  Pipe an exising stack to a new Rex expression.
  """
  defmacro rex(stack, expr) do
    quote do
      unquote(stack) |> unquote(rex_fn(expr, __CALLER__)).()
    end
  end

end

