# CSS Hooks for Elm

Use pseudo-classes, media queries, and container queries with `elm/html`
inline styles. This package follows the
[CSS Hooks](https://css-hooks.com/docs/introduction/) approach and needs no
JavaScript library or CSS build step.

## Install

```sh
elm install n1kben/elm-css-hooks
```

## Example

```elm
module Main exposing (main)

import CssHooks
import Html exposing (Html, button, div, text)


config =
    CssHooks.define
        (\hover wide ->
            { hover = hover
            , wide = wide
            }
        )
        |> CssHooks.add "&:hover"
        |> CssHooks.add "@media (min-width: 600px)"


main : Html msg
main =
    div []
        [ CssHooks.styleElement config
        , button
            [ CssHooks.attribute
                ([ ( "background", "navy" )
                 , ( "padding", "8px" )
                 ]
                    |> CssHooks.on config .hover
                        [ ( "background", "blue" ) ]
                    |> CssHooks.on config .wide
                        [ ( "padding", "12px" ) ]
                )
            ]
            [ text "Save" ]
        ]
```

`define` names the conditions in a record. Each `add` supplies the next
condition, so its order must match the arguments to `define`. The record fields
are checked by Elm.

`on` changes properties when its condition matches. `attribute` turns the
result into an HTML `style` attribute. Include `styleElement config` once on a
page that uses the config.

## Selectors and conditions

Use `&` where the styled element belongs in a selector. `&:hover` matches the
element when hovered, while `.group:hover &` matches it when an ancestor with
the `group` class is hovered.

`add` also accepts `@media`, `@container`, `@supports`, `@scope`, and
`@starting-style` rules.

Combine conditions with `and`, `or`, and `not`:

```elm
CssHooks.on config
    (\c -> CssHooks.and [ c.hover, c.wide ])
    [ ( "background", "blue" ) ]
```

If multiple `on` calls change the same property, the later call wins. Elm does
not check CSS property names, values, or selectors. Include units where needed,
and avoid mixing a shorthand such as `margin` with `margin-left` on the same
element.

## Combining configs

One style can use conditions from multiple configs. This lets components share
conditions such as hover while keeping separate container queries. Include one
`styleElement` for every config used on the page, even when a component is
rendered more than once.

## Example project

The [example project](https://github.com/n1kben/elm-css-hooks/tree/main/examples)
uses hover, keyboard focus, and a media query. From a repository checkout:

```sh
cd examples
elm reactor
```

Then open `src/Main.elm` in the reactor.
