defmodule Rex.Core do

  @moduledoc false

  def rex_def({:def, :shuffler}, {name, patterns, exprs}) do
    quote do
      def unquote(name)([unquote_splicing(patterns) | stack]) do
        [unquote_splicing(exprs) | stack]
      end
    end
  end

  def rex_def({:def, :operator}, {name, args, expr}, env) when length(args) > 0 do
    exprs = unroll_expr(expr)
    qenv = Macro.escape(env)
    quote do
      def unquote(name)(stack = [unquote_splicing(args) | _rest]) do
        stack |> unquote(exprs_fn(exprs)).() |> Rex.Core.expand_head(unquote(qenv))
      end
    end
  end

  def rex_def({:def, :operator}, {name, _, expr}, env) do
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

  # explicit push value reference
  defp piped_expr( x = {:^, _, [value]}) do
    IO.inspect x
    quote do
      fn stack when is_list(stack) -> [unquote(value) | stack] end.()
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

  @operators [:quote, :unquote, :/, :&, :~>, :<~]
  defmacrop is_operator(x) do
    (for o <- @operators, do: quote(do: unquote(x) == unquote(o)))
    |> Enum.reduce(fn a, b -> quote(do: unquote(a) or unquote(b)) end)
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

  defp unroll_line({:^, _, args}) when length(args) > 0 do
    (for a <- args, do: unroll_line(a))
    |> Enum.reduce(&Kernel.++/2)
    |> Enum.map(fn x -> {:^, [], [x]} end)
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
