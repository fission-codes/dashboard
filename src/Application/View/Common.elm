module View.Common exposing (..)

import Css.Classes exposing (..)
import Html exposing (..)
import Html.Attributes exposing (checked, height, href, placeholder, src, style, type_, value, width)


logo :
    { attributes : List (Attribute msg)
    , fissionAttributes : List (Attribute msg)
    }
    -> Html msg
logo { attributes, fissionAttributes } =
    span
        (List.append attributes
            [ flex
            , flex_row
            , items_start
            , space_x_2
            ]
        )
        [ img
            (src "images/logo-dark-textonly.svg"
                :: dark__hidden
                :: fissionAttributes
            )
            []
        , img
            (src "images/logo-light-textonly.svg"
                :: hidden
                :: dark__block
                :: fissionAttributes
            )
            []
        , span
            [ bg_purple
            , uppercase
            , text_white
            , font_display
            , tracking_widest
            , rounded
            , p_1
            , text_xs
            ]
            [ text "Dashboard" ]
        ]
