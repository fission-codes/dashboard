module View.Backup exposing (..)

import Css
import Css.Global
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (action, attribute, autocomplete, css, href, method, name, readonly, src, tabindex, target, title, type_, value)
import Html.Styled.Events as Events
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, px)
import View.Dashboard


view : msg -> Html msg
view msg =
    form
        [ css [ flex, flex_col, max_w_3xl ]
        , action (Route.toUrl Route.Backup)
        , method "POST"
        , Events.onSubmit msg
        ]
        [ input
            [ css [ hidden ]
            , type_ "text"
            , attribute "autocomplete" "username"
            , value "matheus23-fast"
            ]
            []
        , input
            [ css [ View.Common.basicInputStyle ]
            , readonly True
            , type_ "text"
            , attribute "autocomplete" "off"
            , value "x0lmNjRlZjBlNDkxZmRlMjY4NzNhMDBhMDk1ZmY0MDAM="
            ]
            []
        , input
            [ css [ View.Common.basicInputStyle ]
            , type_ "password"
            , attribute "autocomplete" "new-password"
            , value "x0lmNjRlZjBlNDkxZmRlMjY4NzNhMDBhMDk1ZmY0MDAM="
            ]
            []
        , button
            [ css
                [ antialiased
                , appearance_none
                , bg_purple
                , font_semibold
                , inline_block
                , leading_normal
                , mt_5
                , px_5
                , py_3
                , relative
                , rounded
                , text_sm
                , text_white
                , tracking_wider
                , transition_colors
                , uppercase

                --
                , duration_500
                , ease_out

                --
                , Css.focus [ shadow_outline ]
                ]
            , type_ "submit"
            ]
            [ span
                [ css
                    [ text_center
                    ]
                ]
                [ text "Store Recovery Key in Browser" ]
            ]
        ]


loggedInAs : String -> Html msg
loggedInAs username =
    p
        [ css
            [ flex
            , flex_row
            , space_x_2
            ]
        ]
        []
