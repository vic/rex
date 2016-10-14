defmodule Rex.Fun do

  # Converts a quoted Rex word into a quoted Elixir
  # function that handles the program state.
  @moduledoc false

  def to_fun(expr) do
    fun_expr(expr)
  end

  defp fun_expr({:^, _, [expr]}) do
    quote do
      fn {data, prog, env} -> {[unquote(expr) | data], prog, env} end
    end
  end

  defp fun_expr({ref = {:., _, [{_, _, _}, name]}, _, []}) when is_atom(name) do
    quote do
      fn state -> state |> unquote(ref)() end
    end
  end

  defp fun_expr(word = {_, _, nil}) do
    quote do
      fn state -> state |> unquote(word) end
    end
  end

  defp fun_expr({:/, _, [expr = {name, _, nil}, 0]}) when is_atom(name) do
    quote do
      fn {data, prog, env} -> {[unquote(expr) | data], prog, env} end
    end
  end

  defp fun_expr({:/, _, [{name, _, nil}, arity]}) when is_atom(name) and arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn {[unquote_splicing(Enum.reverse(vars)) | stack], program, env} ->
        {[unquote(name)(unquote_splicing(vars)) | stack], program, env}
      end
    end
  end

  defp fun_expr({:/, _, [{ref, _, []}, 0]}) do
    quote do
      fn {data, prog, env} -> {[unquote(ref)() | data], prog, env} end
    end
  end

  defp fun_expr({:/, _, [{ref, _, []}, arity]}) do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn {[unquote_splicing(Enum.reverse(vars)) | stack], prog, env} ->
        {[unquote(ref)(unquote_splicing(vars)) | stack], prog, env}
      end
    end
  end

  defp fun_expr({:dequote, _, _}) do
    quote unquote: false do
      fn {[quoted | data], prog, env} ->
        fun = Rex.Core.rex_fn(quoted) |> Rex.Macro.eval_at_env(env)
        {data, prog, env} |> fun.()
      end
    end
  end

  defp fun_expr(expr = {:quote, _, [[do: _]]}) do
    quote do
      fn {data, prog, env} -> {[unquote(expr) | data], prog, env} end
    end
  end

  defp fun_expr({:quote, _, [expr]}) do
    code = expr |> Macro.escape
    quote do
      fn {data, prog, env} -> {[unquote(code) | data], prog, env} end
    end
  end

  defp fun_expr(expr) do
    quote do
      fn {data, prog, env} -> {[unquote(expr) | data], prog, env} end
    end
  end

end
