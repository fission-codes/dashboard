module View.Recovery exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark)
import View.Dashboard


appShell : List (Html msg) -> Html msg
appShell content =
    div
        [ css
            [ flex
            , flex_col
            , flex_grow
            ]
        ]
        [ div
            [ css
                [ dark
                    [ bg_darkness_above
                    , border_gray_200
                    ]
                , bg_gray_600
                , border_gray_500
                , fixed
                , flex
                , flex_col
                , inset_x_0
                , top_0
                , z_10
                ]
            ]
            [ View.Dashboard.appHeader "Recovery" [] ]
        , main_
            [ css
                [ container
                , flex
                , flex_col
                , flex_grow
                , mx_auto
                ]
            ]
            content
        , div
            [ css
                [ dark [ bg_darkness_above ]
                , bg_gray_600
                , flex
                , flex_col
                , px_6
                ]
            ]
            [ footer
                [ css
                    [ container
                    , mx_auto
                    ]
                ]
                View.Dashboard.appFooterMobile
            ]
        ]
