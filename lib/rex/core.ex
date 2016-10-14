defmodule Rex.Core do
  @moduledoc false

  import Rex.Macro, only: [to_rex_queue: 2]

  def run(state = {_, []}), do: state
  def run(state) do
    state |> run_top |> run
  end

  def run_top({stack, [top | queue]}) do
    top.({stack, queue})
  end

  def rex_def({:def, :shuffler}, {name, patterns, exprs}, _env) do
    quote do
      def unquote(name)({[unquote_splicing(patterns) | stack], queue}) do
        {[unquote_splicing(exprs) | stack], queue}
      end
    end
  end

  def rex_def({:def, :operator}, {name, args, expr}, env) when length(args) > 0 do
    quote do
      def unquote(name)(state = {stack = [unquote_splicing(args) | _rest], queue}) do
        {stack, unquote(to_rex_queue(expr, env)) ++ queue} |> Rex.Core.run
      end
    end
  end

  def rex_def({:def, :operator}, {name, _, expr}, env) do
    quote do
      def unquote(name)(state = {stack, queue}) when is_list(stack) do
        {stack, unquote(to_rex_queue(expr, env)) ++ queue} |> Rex.Core.run
      end
    end
  end

  def rex_fn(expr, env) do
    quote do
      fn
        state = {stack, queue} when is_list(stack) ->
          {stack, unquote(to_rex_queue(expr, env)) ++ queue} |> Rex.Core.run
      end
    end
  end


end

