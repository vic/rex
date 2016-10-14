defmodule Rex.Stack do
  import Rex

  @doc ~S"""
  Drops the top level item from stack

  [a, b | s] -> [b | s]
  """
  def drop({[_ | stack], prog}) do
    {stack, prog}
  end

  @doc ~S"""
  Swaps two top level items on stack.

  [a, b | s] -> [b, a | s]
  """
  drex swap(a, b) (b, a)

  @doc ~S"""
  Duplicates top level item on stack.

  [a | s] -> [a, a | s]
  """
  drex dup(a) (a, a)

  @doc ~S"""
  Duplicates the top item over the second one.

  [a, b | s] -> [a, b, a | s]
  """
  drex over(a, b) (a, b, a)

  @doc ~S"""
  Rotates top three items.

  [a, b, c | s] -> [c, b, a | s]
  """
  drex rot(a, b, c) (c, b, a)


  @doc ~S"""
  Prints the stack to STDOUT without modifying it.

  [a, b | c] -> [a, b | c]
  """
  def show({data, prog}) do
    IO.inspect data
    {data, prog}
  end


  def app({[func | data], prog}) when is_function(func) do
    {:arity, arity} = :erlang.fun_info(func, :arity)
    app(func, arity, data, prog)
  end

  defp app(func, 0, data, prog) do
    {[func.() | data], prog}
  end

  defp app(func, arity, data, prog) when length(data) >= arity do
    args = Enum.slice(data, 0..arity-1)
    rest = Enum.slice(data, arity..-1)
    {[apply(func, args) | rest], prog}
  end


end
