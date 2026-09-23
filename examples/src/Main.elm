module Main exposing (main)

import CssHooks
import Html exposing (Html, button, div, text)


config : CssHooks.Config
    { hover : CssHooks.Condition
    , focusVisible : CssHooks.Condition
    , wide : CssHooks.Condition
    }
config =
    CssHooks.define
        (\hover focusVisible wide ->
            { hover = hover
            , focusVisible = focusVisible
            , wide = wide
            }
        )
        |> CssHooks.add "&:hover"
        |> CssHooks.add "&:focus-visible"
        |> CssHooks.add "@media (min-width: 600px)"


main : Html msg
main =
    div []
        [ CssHooks.styleElement config
        , button
            [ CssHooks.attribute
                ([ ( "background", "#004982" )
                 , ( "color", "white" )
                 , ( "padding", "8px 12px" )
                 ]
                    |> CssHooks.on config
                        (\c -> CssHooks.or [ c.hover, c.focusVisible ])
                        [ ( "background", "#1b659c" ) ]
                    |> CssHooks.on config
                        .wide
                        [ ( "padding", "12px 20px" ) ]
              )
            ]
            [ text "Save changes" ]
        ]
