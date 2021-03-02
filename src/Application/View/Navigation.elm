module View.Navigation exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (classList, css, href)
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark)


header : String -> Html msg
header label =
    h4
        [ css
            [ dark [ text_gray_400 ]
            , pt_4
            , px_3
            , pb_2
            , font_display
            , text_xs
            , tracking_wider
            , uppercase
            , text_gray_300
            ]
        ]
        [ text label ]


item :
    List Css.Style
    ->
        { active : Bool
        , icon : FeatherIcons.Icon
        , label : String
        , link : Route
        }
    -> Html msg
item styles element =
    a
        [ href (Route.toUrl element.link)
        , classList
            [ ( "active", element.active ) ]
        , css
            [ Css.batch styles
            , Css.Global.withClass "active"
                [ dark
                    [ bg_gray_200
                    , border_darkmode_purple
                    ]
                , bg_purple_tint
                , border_purple
                ]
            , lg
                [ h_10 ]
            , bg_transparent
            , border_l_2
            , border_transparent
            , flex
            , flex_grow
            , flex_row
            , h_14
            , items_center
            ]
        ]
        [ element.icon
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span
                [ classList
                    [ ( "active", element.active ) ]
                , css
                    [ Css.Global.withClass "active"
                        [ dark [ text_gray_600 ]
                        , text_purple
                        ]
                    , dark [ text_gray_400 ]

                    --
                    , flex_shrink_0
                    , pl_5
                    , pr_3
                    , text_gray_300
                    ]
                ]
        , span
            [ classList
                [ ( "active", element.active ) ]
            , css
                [ Css.Global.withClass "active"
                    [ dark [ text_gray_800 ]
                    , text_purple
                    ]
                , dark [ text_gray_400 ]
                , flex_grow
                , text_left
                , font_body
                , py_2
                , text_base
                , text_gray_300
                ]
            ]
            [ text element.label ]
        , FeatherIcons.chevronRight
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span
                [ classList
                    [ ( "active", element.active ) ]
                , css
                    [ Css.Global.withClass "active"
                        [ dark [ text_gray_600 ]
                        , block
                        , text_purple
                        ]
                    , flex_shrink_0
                    , hidden
                    , ml_auto
                    , pr_2
                    ]
                ]
        ]
