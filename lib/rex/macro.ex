defmodule Rex.Macro do

  @moduledoc ~S"""
  Functions dealing with Rex AST.

  Rex is a concatenative language written in Elixir syntax.

  A Rex AST is a list of Elixir terms in RPN (Reverse Polish Notation)

  A Rex program stack is a list of functions in that same order,
  each function takes and returns a tuple with the form:

  `{data_stack, program_stack, env}`
  """


  @left_right_ops [:+, :-, :*, :/, :<, :>]

  @doc false
  defmacrop is_left_right_op(x) do
    @left_right_ops
    |> Enum.map(fn o -> quote(do: unquote(x) == unquote(o)) end)
    |> Enum.reduce(fn a, b -> quote(do: unquote(a) or unquote(b)) end)
  end

  @doc ~S"""
  Turns Elixir code into a Rex program stack.
  """
  defmacro to_rex(elixir_ast) do
    elixir_ast |> to_rex_program
  end

  @doc false
  def to_rex_program(elixir_ast) do
    elixir_ast |> to_rex_ast |> Enum.map(&fun_expr/1)
  end

  @doc ~S"""
  Transforms an Elixir AST into a Rex AST
  """
  def to_rex_ast(elixir_ast) do
    unroll_expr(elixir_ast)
  end

  defp unroll_expr([do: {:__block__, _, lines}]) do
    lines
    |> Stream.map(fn line -> unroll_expr(do: line) |> Enum.reverse end)
    |> Enum.reduce(&Kernel.++/2)
    |> Enum.reverse
  end

  defp unroll_expr([do: line]) do
    line |> unroll_line
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

  defp unroll_line(ref = {:&, _, [{:/, _, [_name, arity]}]}) when is_integer(arity) do
    [ref]
  end

  defp unroll_line(ref = {:/, _, [{name, _, _}, arity]}) when is_atom(name) and is_integer(arity) do
    [ref]
  end

  defp unroll_line(ref = {:/, _, [{{:., _, [_, name]}, _, _}, arity]}) when is_atom(name) and is_integer(arity) do
    [ref]
  end

  defp unroll_line({op, _, [a, b]}) when is_left_right_op(op) do
    unroll_line(a) ++ unroll_line(b) ++ [{op, [], nil}]
  end

  defp unroll_line({name, loc, args}) when (name != :quote and name != :.) and length(args) > 0 do
    (for a <- args, do: unroll_line(a))
    |> Enum.reduce(&Kernel.++/2)
    |> List.insert_at(0, {name, loc, nil})
  end

  defp unroll_line(expr) do
    [expr]
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

  @doc false
  def eval_at_env(code, env) do
    with {val, _} <- Code.eval_quoted(code, [], env), do: val
  end

  @doc false
  def show_code(expr) do
    IO.puts Macro.to_string(expr)
    expr
  end

  @doc false
  def dequote_fn(env) do
    quote(do: dequote)
    |> to_rex_program
    |> eval_at_env(env)
    |> fn [fun] -> fun end.()
  end

end
