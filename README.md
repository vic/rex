# Rex - Concatenative elixir macro language.

![rex](https://cloud.githubusercontent.com/assets/331/19221774/310460ee-8e0f-11e6-864b-0a4f2c34b5b2.png)

Rex is a [concatenative language](http://concatenative.org) built with Elixir macros.

Being powered by Elixir macros means that Rex has no parser of its own as it just
uses valid Elixir syntax and thus can be embedded on any elixir program.


#### Stack based

Rex is stack based, that is all Rex functions take a list and return another list.

The topmost element in a stack is the one at index zero, for example, for
`[1, 2, 3]` the top of the stack is `1`. Most Rex functions will operate on
top-most elements as they need and then push the result back to the top.


Inside the `rex` macro, the `~>` operator indicates the order in which to push
values or operators on to the top of the stack.

For example, `rex(1 ~> 2 ~> add)` would result on the following 
`[add, 2, 1]` stack that when executed will yield `[3]`.

So the `~>` allows post-fix notation (operands first, operator last) syntax.
This is the preferred way as most concatenative languages are postfix, but
Rex also has a `<~` operator which just pushes values in the reverse order:
`rex(add <~ 2 <~ 1)` will result on `[add, 2, 1]`.


The following example uses functions from `Rex.Stack` for stack manipulation
and `Rex.Math` that defines aliases to standard elixir math operators.

```elixir
iex> [4, 5] |> rex(3 ~> 2 ~> 1 ~> add ~> mul ~> swap)
[4, 9, 5] 
```



#### [Pointless programming](https://en.wikipedia.org/wiki/Tacit_programming)

With Rex you can write point-free functions.

```elixir
drex sumr     List.foldr/3 <~ (&Kernel.+/2) <~ 0

assert [6] == sumr([1, 2, 3])
```

## Installation

[Available in Hex](https://hex.pm/packages/rex), the package can be installed as:

  1. Add `rex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rex, "~> 0.1.0"}]
    end
    ```

