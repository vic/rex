defmodule Rex.Core do

  @moduledoc false

  def rex_def({:def, :shuffler}, {name, patterns, exprs}) do
    quote context: Rex.Code do
      def unquote(name)([unquote_splicing(patterns) | stack]) do
        [unquote_splicing(exprs) | stack]
      end
    end
  end

  def rex_def({:def, :operator}, {name, args, expr}, env) when length(args) > 0 do
    exprs = unroll_expr(expr)
    qenv = Macro.escape(env)
    quote context: Rex.Code do
      def unquote(name)(stack = [unquote_splicing(args) | _rest]) do
        stack |> unquote(exprs_pipe(exprs)) |> Rex.Core.expand_head(unquote(qenv))
      end
    end
  end

  def rex_def({:def, :operator}, {name, _, expr}, env) do
    exprs = unroll_expr(expr)
    qenv = Macro.escape(env)
    quote context: Rex.Code do
      def unquote(name)(stack) when is_list(stack) do
        stack |> unquote(exprs_pipe(exprs)) |> Rex.Core.expand_head(unquote(qenv))
      end
    end
  end

  def rex_fn(expr, env) do
    exprs = unroll_expr(expr)
    qenv = Macro.escape(env)
    quote context: Rex.Code do
      fn stack when is_list(stack) ->
        stack |> unquote(exprs_pipe(exprs)) |> Rex.Core.expand_head(unquote(qenv))
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
    code = exprs_pipe(quoted)
    code = quote(context: Rex.Code, do: fn stack -> stack |> unquote(code) end)
    {fun, _} = Code.eval_quoted(code, [], env)
    fun
  end

  defp exprs_pipe(exprs) do
    funs = for expr <- exprs, do: piped_expr(expr)
    Enum.reduce(funs, &({:|>, [], [&1, &2]}))
  end

  defp piped_expr({:quote, _, [expr]}) do
    exprs = unroll_expr(expr) |> Macro.escape
    quote context: Rex.Code do
      fn stack when is_list(stack) -> [unquote(exprs) | stack] end.()
    end
  end

  defp piped_expr({:unquote, _, _}) do
    quote context: Rex.Code do
      fn stack when is_list(stack) -> [{:unquote, [], nil} | stack] end.()
    end
  end

  # remote fun ref with arity = 0
  defp piped_expr({:/, _, [{ref, _, []}, 0]}) do
    quote context: Rex.Code do
      fn stack when is_list(stack) -> [unquote(ref)() | stack] end.()
    end
  end

  # remote fun ref with arity > 0
  defp piped_expr({:/, _, [{ref, _, []}, arity]}) when arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote context: Rex.Code do
      fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack]
      end.()
    end
  end

  # local fun ref with arity = 0
  defp piped_expr({:/, _, [ref = {a, _, b}, 0]}) when is_atom(a) and is_atom(b) do
    quote context: Rex.Code do
      fn stack when is_list(stack) -> [unquote(ref) | stack] end.()
    end
  end

  # local fun ref with arity > 0
  defp piped_expr({:/, _, [{ref, _, b}, arity]}) when is_atom(ref) and is_atom(b) and arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote context: Rex.Code do
      fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack]
      end.()
    end
  end

  # push expr reference
  defp piped_expr({:^, _, [value]}) do
    quote context: Rex.Code do
      fn stack when is_list(stack) -> [unquote(value) | stack] end.()
    end
  end

  # any other expr
  defp piped_expr(expr = {_, _, x}) when is_atom(x) or x == [] do
    expr
  end

  # any other expr
  defp piped_expr(expr) do
    quote context: Rex.Code do
      fn stack when is_list(stack) -> [unquote(expr) | stack] end.()
    end
  end

  @operators [:quote, :unquote, :/, :&, :~>, :<~]
  defmacrop is_operator(x) do
    (for o <- @operators, do: quote(context: Rex.Code, do: unquote(x) == unquote(o)))
    |> Enum.reduce(fn a, b -> quote(context: Rex.Code, do: unquote(a) or unquote(b)) end)
  end

  defp unroll_expr([do: {:__block__, _, lines}]) do
    lines
    |> Enum.map(fn line -> unroll_expr(do: line) end)
    |> Enum.reduce(&Kernel.++/2)
  end

  defp unroll_expr([do: line]) do
    line |> unroll_line |> Enum.reverse
  end

  defp unroll_expr(expr) do
    unroll_expr(do: expr)
  end

  defp unroll_line({:~>, _, [a, b]}) do
    unroll_line(a) ++ unroll_line(b)
  end

  defp unroll_line({:<~, _, [a, b]}) do
    unroll_line(b) ++ unroll_line(a)
  end

  defp unroll_line({:^, _, [ref = {_, _, nil}]}) do
    [{:^, [], [ref]}]
  end

  defp unroll_line({:^, _, [{name, _, more}]}) when is_list(more) do
    (for a <- more, do: unroll_line(a))
    |> Enum.reduce(&Kernel.++/2)
    |> List.insert_at(0, {:^, [], [{name, [], nil}]})
  end

  defp unroll_line({name, loc, args}) when not is_operator(name) and length(args) > 0 do
    (for a <- args, do: unroll_line(a))
    |> Enum.reduce(&Kernel.++/2)
    |> List.insert_at(0, {name, loc, nil})
  end

  defp unroll_line(expr) do
    [expr]
  end

  def show(quoted) do
    IO.puts Macro.to_string(quoted)
    quoted
  end

end
