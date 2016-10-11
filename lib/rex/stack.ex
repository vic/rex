defmodule Rex.Stack do
  import Rex

  @doc ~S"""
  Drops the top level item from stack

  [a, b | s] -> [b | s]
  """
  def drop([_ | stack]) do
    stack
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
  def show(stack) do
    IO.inspect stack
    stack
  end

end
