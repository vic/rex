defmodule Rex.Core do

  @moduledoc false

  def rex_def({:def, :stack_effect}, {name, patterns, exprs}) do
    quote do
      def unquote(name)([unquote_splicing(patterns) | stack]) do
        [unquote_splicing(exprs) | stack]
      end
    end
  end

  def rex_def({:def, :stack_expr}, {name, expr}, env) do
    exprs = unroll_expr(expr)
    qenv = Macro.escape(env)
    quote do
      def unquote(name)(stack) when is_list(stack) do
        stack |> unquote(exprs_fn(exprs)).() |> Rex.Core.expand_head(unquote(qenv))
      end
    end
  end

  def rex_fn(expr, env) do
    exprs = unroll_expr(expr)
    qenv = Macro.escape(env)
    quote do
      fn stack when is_list(stack) ->
        stack |> unquote(exprs_fn(exprs)).() |> Rex.Core.expand_head(unquote(qenv))
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
    code = exprs_fn(quoted)
    {fun, _} = Code.eval_quoted(code, [], env)
    fun
  end

  defp exprs_fn(exprs) do
    funs = for expr <- exprs, do: piped_expr(expr)
    pipe = Enum.reduce(funs, &({:|>, [], [&1, &2]}))
    quote do
      fn stack when is_list(stack) -> stack |> unquote(pipe) end
    end
  end

  defp piped_expr({:quote, _, [expr]}) do
    exprs = unroll_expr(expr) |> Macro.escape
    quote do
      fn stack when is_list(stack) -> [unquote(exprs) | stack] end.()
    end
  end

  defp piped_expr({:unquote, _, _}) do
    quote do
      fn stack when is_list(stack) -> [{:unquote, [], nil} | stack] end.()
    end
  end

  # remote fun ref with arity = 0
  defp piped_expr({:/, _, [{ref, _, []}, 0]}) do
    quote do
      fn stack when is_list(stack) -> [unquote(ref)() | stack] end.()
    end
  end

  # remote fun ref with arity > 0
  defp piped_expr({:/, _, [{ref, _, []}, arity]}) when arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack]
      end.()
    end
  end

  # local fun ref with arity = 0
  defp piped_expr({:/, _, [ref = {a, _, b}, 0]}) when is_atom(a) and is_atom(b) do
    quote do
      fn stack when is_list(stack) -> [unquote(ref) | stack] end.()
    end
  end

  # local fun ref with arity > 0
  defp piped_expr({:/, _, [{ref, _, b}, arity]}) when is_atom(ref) and is_atom(b) and arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack]
      end.()
    end
  end

  # any other expr
  defp piped_expr(expr = {_, _, x}) when is_atom(x) or x == [] do
    expr
  end

  # any other expr
  defp piped_expr(expr) do
    quote do
      fn stack when is_list(stack) -> [unquote(expr) | stack] end.()
    end
  end

  defp unroll_expr(expr = [do: _]) do
    unroll_do(expr)
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

  defp unroll_do([do: line]) do
    unroll_do({:line, line}) |> List.flatten |> Enum.reverse
  end

  defp unroll_do([do: {:__block__, _, lines}]) do
    Enum.map(lines, fn line -> unroll_do({:line, line}) end)
    |> List.flatten
    |> Enum.reverse
  end

  defp unroll_do({:line, expr = {name, _, _}})
  when (name == :/ or name == :&) do
    unroll_expr(expr)
  end

  defp unroll_do({:line, {name, loc, args}}) when length(args) > 0 do
    [{name, loc, []} | (for a <- args, do: unroll_do({:line, a}))]
  end

  defp unroll_do({:line, expr}) do
    unroll_expr(expr)
  end

end
