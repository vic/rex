defmodule Rex.Core do
  import Rex

  def drop([_ | stack]) do
    stack
  end

  drex swap(a, b) (b, a)

end
