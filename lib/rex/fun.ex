defmodule Rex.Fun do

  # Converts a quoted Rex word into a quoted Elixir
  # function that handles the state
  @moduledoc false

  def to_fun({:@, _, [[expr]]}, env) do
    quoted_expr(expr, env)
  end

  def to_fun(expr, _env) do
    fun_expr(expr)
  end

  defp quoted_expr(quoted, env) do
    expr = {quoted, env} |> Macro.escape
    quote do
      fn {stack, queue} -> {[unquote(expr) | stack], queue} end
    end
  end

  defmacro dequote do
    quote do
      fn {[{quoted, env} | stack], queue} ->
        code = Rex.Core.rex_fn(quoted, env)
        {fun, _} = Code.eval_quoted(code, [], env)
        {stack, queue} |> fun.()
      end
    end
  end

  defp fun_expr({:^, _, [expr]}) do
    quote do
      fn {stack, queue} -> {[unquote(expr) | stack], queue} end
    end
  end

  defp fun_expr({ref = {:., _, [{_, _, _}, name]}, _, []}) when is_atom(name) do
    quote do
      fn state -> state |> unquote(ref)() end
    end
  end

  defp fun_expr({:/, _, [expr = {name, _, nil}, 0]}) when is_atom(name) do
    quote do
      fn {stack, queue} -> {[unquote(expr) | stack], queue} end
    end
  end

  defp fun_expr({:/, _, [{name, _, nil}, arity]}) when is_atom(name) and arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn {[unquote_splicing(Enum.reverse(vars)) | stack], queueram} ->
        {[unquote(name)(unquote_splicing(vars)) | stack], queueram}
      end
    end
  end

  defp fun_expr({:/, _, [{ref, _, []}, 0]}) do
    quote do
      fn {stack, queue} -> {[unquote(ref)() | stack], queue} end
    end
  end

  defp fun_expr({:/, _, [{ref, _, []}, arity]}) do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn {[unquote_splicing(Enum.reverse(vars)) | stack], queue} ->
        {[unquote(ref)(unquote_splicing(vars)) | stack], queue}
      end
    end
  end

  defp fun_expr(expr = {:quote, _, _}) do
    code = expr |> Macro.escape
    quote do
      fn {stack, queue} -> {[unquote(code) | stack], queue} end
    end
  end

  defp fun_expr(word = {_, _, nil}) do
    quote do
      fn state -> state |> unquote(word) end
    end
  end

  defp fun_expr(expr) do
    quote do
      fn {stack, queue} -> {[unquote(expr) | stack], queue} end
    end
  end

end
