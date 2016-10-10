defmodule Rex.Core do

  @moduledoc false

  def rex_def({:def, :stack_effect}, {name, patterns, exprs}, env) do
    qenv = Macro.escape(env)
    quote do
      def unquote(name)([unquote_splicing(patterns) | stack]) do
        [unquote_splicing(exprs) | stack] |> Rex.Core.expand_head(unquote(qenv))
      end
    end
  end

  def rex_def({:def, :stack_expr}, {name, expr}, env) do
    exprs = unroll_expr(expr)
    quote do
      def unquote(name)(stack) when is_list(stack) do
        stack |> unquote(exprs_fn(exprs, env)).()
      end
    end
  end

  def rex_fn(expr, env) do
    exprs = unroll_expr(expr)
    quote do
      fn stack when is_list(stack) ->
        stack |> unquote(exprs_fn(exprs, env)).()
      end
    end
  end

  def expand_head([{:unquote, _, _}, quoted | stack], env) do
    unquote_fn(quoted, env).(stack)
  end

  def expand_head(stack, _env) do
    stack
  end

  def unquote_fn(quoted, env) do
    code = exprs_fn(quoted, env)
    {fun, _} = Code.eval_quoted(code, [], env: env)
    fun
  end

  defp exprs_fn(exprs, env) do
    funs = for expr <- exprs, do: piped_expr(expr, env)
    pipe = Enum.reduce(funs, &({:|>, [], [&1, &2]}))
    quote do
      fn stack when is_list(stack) -> stack |> unquote(pipe) end
    end
  end

  defp piped_expr({:quote, _, [expr]}, _env) do
    exprs = unroll_expr(expr) |> Macro.escape
    quote do
      fn stack when is_list(stack) -> [unquote(exprs) | stack] end.()
    end
  end

  defp piped_expr({:unquote, _, _}, env) do
    env = Macro.escape(env)
    quote do
      fn [quoted | stack] -> Rex.Core.unquote_fn(quoted, unquote(env)).(stack) end.()
    end
  end

  # remote fun ref with arity = 0
  defp piped_expr({:/, _, [{ref, _, []}, 0]}, _env) do
    quote do
      fn stack when is_list(stack) -> [unquote(ref)() | stack] end.()
    end
  end

  # remote fun ref with arity > 0
  defp piped_expr({:/, _, [{ref, _, []}, arity]}, _env) when arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack]
      end.()
    end
  end

  # local fun ref with arity = 0
  defp piped_expr({:/, _, [ref = {a, _, b}, 0]}, _env) when is_atom(a) and is_atom(b) do
    quote do
      fn stack when is_list(stack) -> [unquote(ref) | stack] end.()
    end
  end

  # local fun ref with arity > 0
  defp piped_expr({:/, _, [{ref, _, b}, arity]}, _env) when is_atom(ref) and is_atom(b) and arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack]
      end.()
    end
  end

  # any other expr
  defp piped_expr(expr = {_, _, x}, _env) when is_atom(x) or x == [] do
    expr
  end

  # any other expr
  defp piped_expr(expr, _env) do
    quote do
      fn stack when is_list(stack) -> [unquote(expr) | stack] end.()
    end
  end

  defp unroll_expr({:~>, _, [a, b]}) do
    unroll_expr(b) ++ unroll_expr(a)
  end

  defp unroll_expr({:<~, _, [a, b]}) do
    unroll_expr(a) ++ unroll_expr(b)
  end

  defp unroll_expr(expr) do
    [expr]
  end

end
