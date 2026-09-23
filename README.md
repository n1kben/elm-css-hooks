# CSS Hooks for Elm

If you use `elm/html` with inline styles, those styles cannot respond to
`:hover` or a media query on their own. This package uses
[CSS Hooks](https://css-hooks.com/docs/introduction/) to add those conditions.
Your style values stay inline, and one stylesheet switches between them. You
do not need a JavaScript library or a CSS build step.

## A button that responds to hover and screen width

```elm
import CssHooks
import Html exposing (button, div, text)

config =
    CssHooks.define (\hover wide -> { hover = hover, wide = wide })
        |> CssHooks.add "&:hover"
        |> CssHooks.add "@media (min-width: 600px)"

view =
    div []
        [ CssHooks.styleElement config
        , button
            [ CssHooks.attribute
                ([ ( "background", "navy" ), ( "padding", "8px" ) ]
                    |> CssHooks.on config .hover
                        [ ( "background", "blue" ) ]
                    |> CssHooks.on config .wide
                        [ ( "padding", "12px" ) ]
                )
            ]
            [ text "Save" ]
        ]
```

`define` names the conditions in a record. Each `add` supplies one condition
to that record and adds its CSS rule. The order of the `add` calls must match
the order of the arguments to `define`: `hover` gets `&:hover`, then `wide`
gets the media query.

Start with a list of CSS properties and values. `on config .hover overrides`
changes those properties when the button is hovered; `on config .wide`
does the same at widths of 600px or more. `attribute` turns the result into
an HTML `style` attribute. Put `styleElement config` in the page once so those
conditions can work.

The record names are checked by Elm. If you write `.hovre`, the compiler
reports an error. Each named condition and its CSS rule also come from the
same `add` call, so there is no second registration list to maintain.

## Selectors and conditions

Use `&` where the styled element belongs in a selector. `&:hover` matches
that element when hovered. `.group:hover &` matches it when an ancestor with
the `group` class is hovered. `add` also accepts `@media`, `@container`,
`@supports`, `@scope`, and `@starting-style` rules.

You can combine named conditions:

```elm
CssHooks.on config
    (\c -> CssHooks.and [ c.hover, c.wide ])
    [ ( "background", "blue" ) ]
```

`CssHooks.and` requires every condition to match, `CssHooks.or` requires at
least one, and `CssHooks.not` reverses a condition. If two `on` calls set the
same property, the later call wins.

CSS property names and values are strings. Write property names in kebab case
and include units where needed, such as `( "padding", "12px" )`. Elm does not
check CSS syntax in a selector or value. Pass trusted selector strings to
`add`, since they become part of the stylesheet.

Avoid mixing a shorthand such as `margin` with `margin-left` on the same
element. The [CSS Hooks usage guide](https://css-hooks.com/docs/usage/)
explains why they conflict.

## Running the example

```sh
cd examples
elm reactor
```

Open `src/Main.elm` in the reactor. The button uses hover, keyboard focus,
and a media query. You can also compile it with
`elm make src/Main.elm --output=main.js`.

## Related packages

The official project has packages for
[React, Preact, Solid, and Qwik](https://css-hooks.com/docs/setup/). They use
the same CSS custom property technique. This Elm package takes CSS values as
strings and returns an `Html.Attribute`.
