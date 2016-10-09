defmodule Rex do

  defmacro __using__(_) do
    quote do
      use Rex.Core
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

  defmacro drex({name, _, [program]}) do
    quote do
      def unquote(name)(stack) when is_list(stack) do
        stack |> unquote(piped(program))
      end
    end
  end

  defmacro rex(program) do
    quote do
      fn stack ->
        stack |> unquote(piped(program))
      end
    end
  end

  defmacro rex(stack, program) do
    quote do
      unquote(stack) |> unquote(piped(program))
    end
  end

  def compile(quoted) do
    {fun, _} =
      quoted
      |> Enum.reduce(fn a, b -> {:~>, [], [a, b]} end)
      |> piped
      |> fn rex -> quote(do: fn stack -> stack |> unquote(rex) end) end.()
      |> Code.eval_quoted
    fun
  end

  defp quoted({:~>, _, [a, b]}, rest) do
    [b | quoted(a, rest)]
  end

  defp quoted({:<~, _, [a, b]}, rest) do
    quoted(a, []) ++ quoted(b, rest)
  end

  defp quoted(x, rest) do
    [x | rest]
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

  defp piped({:quote, _, [program]}) do
    list = program |> quoted([]) |> Macro.escape
    quote do
      (fn stack when is_list(stack) -> [unquote(list) | stack] end).()
    end
  end

  defp piped({:unquote, _, x}) when is_atom(x) do
    quote do
      (fn [quoted | stack] when is_list(quoted) ->
        compile(quoted).(stack)
      end).()
    end
  end

  defp piped(x = {:&, _, [{:/, _, [_, arity]}]}) when is_integer(arity) do
    quote do
      (fn stack when is_list(stack) -> [unquote(x) | stack] end).()
    end
  end

  defp piped({:/, _, [{ref, _, []}, 0]}) do
    quote do
      (fn stack when is_list(stack) -> [unquote(ref)() | stack] end).()
    end
  end

  defp piped({:/, _, [{ref, _, []}, arity]}) when arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      (fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(ref)(unquote_splicing(vars)) | stack]
      end).()
    end
  end

  defp piped({:/, _, [ref = {a, _, b}, 0]}) when is_atom(a) and is_atom(b) do
    quote do
      (fn stack when is_list(stack) -> [unquote(ref) | stack] end).()
    end
  end

  defp piped({:/, _, [{a, _, b}, arity]}) when is_atom(a) and is_atom(b) and arity > 0 do
    vars = for i <- 0..arity-1, do: Macro.var(:"v#{i}", nil)
    quote do
      (fn [unquote_splicing(Enum.reverse(vars)) | stack] ->
        [unquote(a)(unquote_splicing(vars)) | stack]
      end).()
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
