defmodule Rex.Core do
  @moduledoc false

  import Rex.Macro, only: [to_rex_program: 1]

  def run(state = {_, [], _}), do: state
  def run(state) do
    state |> run_top |> run
  end

  def run_top({data, [top | program], env}) do
    top.({data, program, env})
  end

  def rex_def({:def, :shuffler}, {name, patterns, exprs}) do
    quote do
      def unquote(name)({[unquote_splicing(patterns) | stack], prog, env}) do
        {[unquote_splicing(exprs) | stack], prog, env}
      end
    end
  end

  def rex_def({:def, :operator}, {name, args, expr}) when length(args) > 0 do
    quote do
      def unquote(name)(state = {data = [unquote_splicing(args) | _rest], prog, env}) do
        {data, unquote(to_rex_program(expr)) ++ prog, env} |> Rex.Core.run
      end
    end
  end

  def rex_def({:def, :operator}, {name, _, expr}) do
    quote do
      def unquote(name)(state = {data, prog, env}) when is_list(data) do
        {data, unquote(to_rex_program(expr)) ++ prog, env} |> Rex.Core.run
      end
    end
  end

  def rex_fn(expr) do
    quote do
      fn
        state = {data, prog, env} when is_list(data) ->
          {data, unquote(to_rex_program(expr)) ++ prog, env} |> Rex.Core.run
      end
    end
  end


end

