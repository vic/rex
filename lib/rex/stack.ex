defmodule Rex.Stack do
  import Rex

  drex swap(a, b) (b, a)

  def drop([_ | stack]) do
    stack
  end

  def show(stack) do
    IO.inspect stack
  end

end
