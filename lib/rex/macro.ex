defmodule Rex.Macro do

  @moduledoc ~S"""
  Functions dealing with Rex AST.

  Rex is a concatenative language written in Elixir syntax.

  A Rex AST is a list of Elixir terms in RPN (Reverse Polish Notation)

  A Rex program stack is a list of functions in that same order,
  each function takes and returns a tuple with the form:

  `{data_stack, program_stack, env}`
  """

  @doc ~S"""
  Turns Elixir code into a Rex program stack.
  """
  defmacro to_rex(elixir_ast) do
    elixir_ast |> to_rex_program
  end

  @doc false
  def to_rex_program(elixir_ast) do
    elixir_ast |> to_rex_ast |> Enum.map(&Rex.Fun.to_fun/1)
  end

  @doc ~S"""
  Transforms an Elixir AST into a Rex AST
  """
  def to_rex_ast(elixir_ast) do
    Rex.Postfix.to_postfix(elixir_ast)
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
