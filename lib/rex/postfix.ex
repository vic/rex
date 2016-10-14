defmodule Rex.Postfix do

  # Converts Elixir AST expressions into postfix form.
  @moduledoc false

  def to_postfix(elixir_ast) do
    postfix_elixir(elixir_ast)
  end

  @left_right_ops [:+, :-, :*, :/, :<, :>]

  @doc false
  defmacrop is_left_right_op(x) do
    @left_right_ops
    |> Enum.map(fn o -> quote(do: unquote(x) == unquote(o)) end)
    |> Enum.reduce(fn a, b -> quote(do: unquote(a) or unquote(b)) end)
  end


  defp postfix_elixir([do: {:__block__, _, lines}]) do
    lines
    |> Stream.map(fn line -> postfix_elixir(do: line) |> Enum.reverse end)
    |> Enum.reduce(&Kernel.++/2)
    |> Enum.reverse
  end

  defp postfix_elixir([do: line]) do
    line |> postfix_line
  end

  defp postfix_elixir(expr) do
    postfix_elixir(do: expr)
  end

  defp postfix_line({:~>, _, [a, b]}) do
    postfix_line(a) ++ postfix_line(b)
  end

  defp postfix_line({:<~, _, [a, b]}) do
    postfix_line(b) ++ postfix_line(a)
  end

  defp postfix_line({:^, _, [ref = {_, _, nil}]}) do
    [{:^, [], [ref]}]
  end

  defp postfix_line({:^, _, [{name, _, more}]}) when is_list(more) do
    (for a <- more, do: postfix_line(a))
    |> Enum.reduce(&Kernel.++/2)
    |> List.insert_at(0, {:^, [], [{name, [], nil}]})
  end

  defp postfix_line(ref = {:&, _, [{:/, _, [_name, arity]}]}) when is_integer(arity) do
    [ref]
  end

  defp postfix_line(ref = {:/, _, [{name, _, _}, arity]}) when is_atom(name) and is_integer(arity) do
    [ref]
  end

  defp postfix_line(ref = {:/, _, [{{:., _, [_, name]}, _, _}, arity]}) when is_atom(name) and is_integer(arity) do
    [ref]
  end

  defp postfix_line({op, _, [a, b]}) when is_left_right_op(op) do
    postfix_line(a) ++ postfix_line(b) ++ [{op, [], nil}]
  end

  defp postfix_line({name, loc, args}) when (name != :quote and name != :@) and length(args) > 0 do
    (for a <- args, do: postfix_line(a))
    |> Enum.reduce(&Kernel.++/2)
    |> List.insert_at(0, {name, loc, nil})
  end

  defp postfix_line(expr) do
    [expr]
  end

end
