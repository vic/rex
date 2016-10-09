# Rex - Concatenative elixir macro language.

Rex is a [concatenative language](http://concatenative.org) built with Elixir macros.


This means that rex has no parser as it just uses valid Elixir syntax.


#### Stack based

Rex is stack based, that is all rex functions take a list and return another list.

The topmost element in a stack is the one at index zero, for example, for
`[1, 2, 3]` the top of the stack is `1`. Most rex functions will operate on as much
top-most elements as they needs and then push the result back on the top if needed.

For example, the following program will pipe an initial stack into a rex program:

```elixir
iex> [4, 5] |> rex(3 ~> 2 ~> 1 ~> add ~> mul ~> swap)
[4, 9, 5] 
```

#### [Pointless programming](https://en.wikipedia.org/wiki/Tacit_programming)

With Rex you can write point-free functions.

```elixir
drex sumr          List.foldr/3 <~ (&Kernel.+/2) <~ 0

assert [6] == [] |> rex([1, 2, 3] ~> sumr)
```

## Installation

[Available in Hex](https://hex.pm/packages/rex), the package can be installed as:

  1. Add `rex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rex, "~> 0.1.0"}]
    end
    ```

