module View.Backup exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (action, attribute, autocomplete, css, href, method, name, readonly, src, tabindex, target, title, type_, value)
import Html.Styled.Events as Events
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, px)
import View.Dashboard


loggedInAs : String -> Html msg
loggedInAs username =
    p
        [ css
            [ View.Dashboard.sectionParagraphSpacings
            , flex
            , flex_row
            , space_x_2
            ]
        ]
        [ View.Common.icon
            { icon = FeatherIcons.user
            , size = View.Common.Medium
            , tag =
                span
                    [ css
                        [ dark [ text_darkmode_purple ]
                        , text_purple
                        ]
                    ]
            }
        , span
            [ css
                [ dark [ text_gray_600 ]
                , text_gray_300
                ]
            ]
            [ text "Logged in as "
            , span [ css [ italic ] ] [ text username ]
            ]
        ]


buttonGroup : List (Html msg) -> Html msg
buttonGroup content =
    div
        [ css
            [ View.Dashboard.sectionParagraphSpacings
            , flex
            , flex_row
            , space_x_2
            , max_w_3xl
            ]
        ]
        content
