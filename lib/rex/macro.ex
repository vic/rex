defmodule Rex.Macro do

  @moduledoc ~S"""
  Functions dealing with Rex AST.

  Rex is a concatenative language written in Elixir syntax.

  A Rex AST is a list of Elixir quoted terms in RPN (Reverse Polish Notation)

  A Rex function (a `word` in concatenative parlance) takes and returns a tuple
  with the form: `{stack, queue}`.

  The `stack` is a list of operands for remaining functions.
  The `queue` is a list of future functions to be executed.
  """

  @doc ~S"""
  Turns Elixir code into a Rex program stack.
  """
  defmacro to_rex(elixir_ast) do
    elixir_ast |> to_rex_queue(__CALLER__)
  end

  @doc false
  def to_rex_queue(elixir_ast, env) do
    elixir_ast |> to_rex_ast |> Enum.map(&Rex.Fun.to_fun(&1, env))
  end

  @doc ~S"""
  Transforms an Elixir AST into a Rex AST
  """
  def to_rex_ast(elixir_ast) do
    Rex.Postfix.to_postfix(elixir_ast)
  end

  @doc false
  def show_code(expr) do
    IO.puts Macro.to_string(expr)
    expr
  end

end
