module CssHooks exposing
    ( Config, Condition, Style
    , define, add, and, or, not
    , on, attribute, styleSheet, styleElement
    )

{-| Make Elm inline styles respond to selectors and CSS at-rules. Start with a
base style, then use `on` to change it when a condition matches.

    config =
        CssHooks.define (\hover -> { hover = hover })
            |> CssHooks.add "&:hover"

    buttonStyle =
        [ ( "background", "navy" ) ]
            |> CssHooks.on config .hover
                [ ( "background", "blue" ) ]

    view =
        Html.div []
            [ CssHooks.styleElement config
            , Html.button [ CssHooks.attribute buttonStyle ] [ Html.text "Save" ]
            ]

`define` gives the condition a name. `add` supplies its selector and registers
the CSS rule. Put `styleElement config` in the page once; the style values on
each element remain inline. The [CSS Hooks introduction](https://css-hooks.com/docs/introduction/)
explains the CSS custom properties behind this.

# Configuring hooks

@docs Config, Condition, define, add

# Styling elements

@docs Style, on, attribute, styleElement, styleSheet

# Combining conditions

@docs and, or, not

-}

import Char
import Html exposing (Html)
import Html.Attributes


{-| The conditions created by `define` and `add`, along with their stylesheet
rules. The type parameter is the record of names you choose for the conditions.
-}
type Config a
    = Config (List ( String, String )) a


{-| A condition created by `add`, or a combination made with `and`, `or`, or
`not`. Use one with `on` to change an inline style.
-}
type Condition
    = Hook String
    | All (List Condition)
    | Any (List Condition)
    | Not Condition


{-| CSS property and value pairs. Write property names in kebab case and include
units where needed, as in `( "padding", "12px" )`. Elm does not check CSS syntax
in these strings.
-}
type alias Style =
    List ( String, String )


{-| Start a config. The function names the conditions supplied by later `add`
calls. Its arguments and the `add` calls must be in the same order:

    CssHooks.define (\hover wide -> { hover = hover, wide = wide })
        |> CssHooks.add "&:hover"
        |> CssHooks.add "@media (min-width: 600px)"

-}
define : a -> Config a
define make =
    Config [] make


{-| Add a selector or at-rule. This registers its stylesheet rule and supplies
its condition to the function in `define`. Each call fills one argument of that
function. Supported at-rules are `@media`, `@container`, `@supports`, `@scope`,
and `@starting-style`.

    config =
        CssHooks.define (\hover -> { hover = hover })
            |> CssHooks.add "&:hover"

Use `&` to mark the styled element in a selector. For example, `&:hover`
matches the element when hovered; `.group:hover &` matches it when an ancestor
with the `group` class is hovered. Elm does not check selector syntax, so pass
trusted strings to `add`.
-}
add : String -> Config (Condition -> a) -> Config a
add selector (Config selectors make) =
    let
        variable =
            variableName selector
    in
    Config (selectors ++ [ ( selector, variable ) ]) (make (Hook variable))


{-| Match when every condition matches. An empty list always matches.

    CssHooks.on config
        (\c -> CssHooks.and [ c.hover, c.wide ])
        [ ( "background", "blue" ) ]

-}
and : List Condition -> Condition
and =
    All


{-| Match when at least one condition matches. An empty list never matches.

    CssHooks.on config
        (\c -> CssHooks.or [ c.hover, c.wide ])
        [ ( "background", "blue" ) ]

-}
or : List Condition -> Condition
or =
    Any


{-| Match when a condition does not match. For example, `not c.wide` matches
widths below the registered media query:

    CssHooks.on config
        (\c -> CssHooks.not c.wide)
        [ ( "padding", "8px" ) ]

-}
not : Condition -> Condition
not =
    Not


{-| Set properties when a condition matches. Select a named condition with a
record accessor such as `.hover`, or combine conditions with a function such
as `(\c -> CssHooks.or [ c.hover, c.wide ])`.

Start with a base style and pipe it through `on`. Each call takes the config,
the condition to select, and the properties to change:

    [ ( "background", "navy" ) ]
        |> CssHooks.on config .hover [ ( "background", "blue" ) ]

You can use multiple `on` calls. The later call wins if two calls set the same
property. A property with no base value falls back to `revert-layer` when its
condition does not match.

Avoid mixing a shorthand such as `margin` with a longhand such as `margin-left`
on the same element.
-}
on : Config a -> (a -> Condition) -> Style -> Style -> Style
on (Config _ conditions) select overrides base =
    let
        condition =
            select conditions
    in
    List.foldl
        (\( property, overrideValue ) style ->
            let
                fallback =
                    styleValue property style
                        |> Maybe.withDefault "revert-layer"

                value =
                    expression condition overrideValue fallback
            in
            setProperty property value style
        )
        base
        overrides


{-| Turn a style into one HTML `style` attribute. Apply `on` before calling
this function.

    Html.button
        [ CssHooks.attribute [ ( "color", "white" ) ] ]
        [ Html.text "Save" ]

-}
attribute : Style -> Html.Attribute msg
attribute declarations =
    declarations
        |> List.map (\( property, value ) -> property ++ ":" ++ value)
        |> String.join ";"
        |> Html.Attributes.attribute "style"


{-| Get the stylesheet as a string, for use when you manage the page's CSS
yourself. Include it once. For Elm views, `styleElement` does this for you.
-}
styleSheet : Config a -> String
styleSheet (Config selectors _) =
    unique selectors
        |> List.map rulesFor
        |> String.join "\n"


{-| Add the hook stylesheet to the page. Place this element once near the root
of a view that uses `on` with this config.
-}
styleElement : Config a -> Html msg
styleElement config =
    Html.node "style" [] [ Html.text (styleSheet config) ]


unique : List ( String, String ) -> List ( String, String )
unique selectors =
    List.foldl
        (\selector seen ->
            if List.member selector seen then
                seen

            else
                seen ++ [ selector ]
        )
        []
        selectors


styleValue : String -> Style -> Maybe String
styleValue property style =
    List.foldl
        (\( name, value ) found ->
            if name == property then
                Just value

            else
                found
        )
        Nothing
        style


setProperty : String -> String -> Style -> Style
setProperty property value style =
    List.filter (\( name, _ ) -> name /= property) style
        ++ [ ( property, value ) ]


expression : Condition -> String -> String -> String
expression condition whenTrue whenFalse =
    case condition of
        Hook variable ->
            "var(" ++ variable ++ "1, " ++ whenTrue ++ ") var(" ++ variable ++ "0, " ++ whenFalse ++ ")"

        All conditions ->
            List.foldr
                (\item result -> expression item result whenFalse)
                whenTrue
                conditions

        Any conditions ->
            expression (All (List.map Not conditions)) whenFalse whenTrue

        Not inner ->
            expression inner whenFalse whenTrue


rulesFor : ( String, String ) -> String
rulesFor ( selector, variable ) =
    let
        off =
            "*{" ++ variable ++ "0:initial;" ++ variable ++ "1: ;}"

        onDeclarations =
            "{" ++ variable ++ "0: ;" ++ variable ++ "1:initial;}"
    in
    if String.startsWith "@scope " selector then
        off ++ "\n" ++ selector ++ "{:scope" ++ onDeclarations ++ "}"

    else if isAtRule selector then
        off ++ "\n" ++ selector ++ "{*" ++ onDeclarations ++ "}"

    else
        off ++ "\n:where(" ++ String.replace "&" "*" selector ++ ")" ++ onDeclarations


isAtRule : String -> Bool
isAtRule selector =
    List.any (\prefix -> String.startsWith prefix selector)
        [ "@media ", "@container ", "@supports ", "@starting-style" ]


variableName : String -> String
variableName selector =
    "--ech-" ++ encode selector ++ "-"


encode : String -> String
encode value =
    "x"
        ++ (value
                |> String.toList
                |> List.map (Char.toCode >> String.fromInt)
                |> String.join "_"
           )
