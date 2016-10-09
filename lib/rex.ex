defmodule Rex do

  @moduledoc ~S"""

  ## Examples

      iex> # drop: removes the topmost element from the stack
      iex> use Rex
      ...> [1, 2, 3] |> rex(drop)
      [2, 3]

  """

  defmacro __using__(_) do
    quote do
      import Rex
      import Rex.Core
    end
  end

  #defmacro drex(x), do: IO.puts(inspect(x))

  defmacro drex({{name, _, pattern}, _, expr}) when length(pattern) > 0 do
    quote do
      def unquote(name)([unquote_splicing(pattern) | stack]) do
        [unquote_splicing(expr) | stack]
      end
    end
  end

  defmacro drex({name, _, [program = {p, _, _}]}) when p == :~> or p == :<~ do
    quote do
      def unquote(name)(stack) when is_list(stack) do
        stack |> unquote(piped(program))
      end
    end
  end

  defmacro drex({name, _, [program]}) do
    quote do
      def unquote(name)(stack) when is_list(stack )do
        stack |> unquote(piped(program))
      end
    end
  end

  defmacro rex(stack, program) do
    quote do
      unquote(stack) |> unquote(piped(program))
    end
  end

  defp piped({:~>, _, [a, b]}) do
    quote do
      unquote(piped(a)) |> unquote(piped(b))
    end
  end

  defp piped({:<~, _, [a, b]}) do
    quote do
      unquote(piped(b)) |> unquote(piped(a))
    end
  end

  defp piped(x = {:&, _, [{:/, _, [_, arity]}]}) when is_integer(arity) do
    quote do
      (fn stack when is_list(stack) -> [unquote(x) | stack] end).()
    end
  end

  defp piped({:/, _, [{ref, _, []}, arity]}) when is_integer(arity) do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      (fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack] end
      ).()
    end
  end

  defp piped(expr = {_, _, _}) do
    quote do
      unquote(expr)
    end
  end

  defp piped(x) do
    quote do
      (fn stack when is_list(stack) -> [unquote(x) | stack] end).()
    end
  end


end
