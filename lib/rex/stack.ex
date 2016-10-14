defmodule Rex.Stack do
  import Rex

  @doc ~S"""
  Drops the top level item from stack

  [a, b | s] -> [b | s]
  """
  def drop({[_ | stack], queue}) do
    {stack, queue}
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
  def show({stack, queue}) do
    IO.inspect stack
    {stack, queue}
  end


  def app({[func | stack], queue}) when is_function(func) do
    {:arity, arity} = :erlang.fun_info(func, :arity)
    app(func, arity, stack, queue)
  end

  defp app(func, 0, stack, queue) do
    {[func.() | stack], queue}
  end

  defp app(func, arity, stack, queue) when length(stack) >= arity do
    args = Enum.slice(stack, 0..arity-1)
    rest = Enum.slice(stack, arity..-1)
    {[apply(func, args) | rest], queue}
  end


end
