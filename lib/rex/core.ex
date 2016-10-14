defmodule Rex.Core do
  @moduledoc false

  import Rex.Macro, only: [to_rex_program: 2]

  def run(state = {_, []}), do: state
  def run(state) do
    state |> run_top |> run
  end

  def run_top({data, [top | program]}) do
    top.({data, program})
  end

  def rex_def({:def, :shuffler}, {name, patterns, exprs}, _env) do
    quote do
      def unquote(name)({[unquote_splicing(patterns) | stack], prog}) do
        {[unquote_splicing(exprs) | stack], prog}
      end
    end
  end

  def rex_def({:def, :operator}, {name, args, expr}, env) when length(args) > 0 do
    quote do
      def unquote(name)(state = {data = [unquote_splicing(args) | _rest], prog}) do
        {data, unquote(to_rex_program(expr, env)) ++ prog} |> Rex.Core.run
      end
    end
  end

  def rex_def({:def, :operator}, {name, _, expr}, env) do
    quote do
      def unquote(name)(state = {data, prog}) when is_list(data) do
        {data, unquote(to_rex_program(expr, env)) ++ prog} |> Rex.Core.run
      end
    end
  end

  def rex_fn(expr, env) do
    quote do
      fn
        state = {data, prog} when is_list(data) ->
          {data, unquote(to_rex_program(expr, env)) ++ prog} |> Rex.Core.run
      end
    end
  end


end

