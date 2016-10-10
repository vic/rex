defmodule Rex.Core do

  defmacro __using__(_) do
    quote do
      import Rex
      import Rex.Core
      import Rex.Stack
      import Rex.Control
      import Rex.Math
    end
  end

end
