module View.Recovery exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, css, placeholder, type_, value)
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
                [ flex_shrink_0
                , View.Dashboard.headerHeight
                ]
            ]
            []
        , div
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


startRecoveryProcessButton : Html msg
startRecoveryProcessButton =
    button
        [ type_ "submit"
        , css
            [ View.Common.primaryButtonStyle
            , sm
                [ flex_grow_0
                , w_auto
                ]
            , flex_grow
            , flex
            , flex_row
            , flex_shrink_0
            , items_center
            , w_full
            ]
        ]
        [ span [ css [ ml_auto ] ] [ text "Start Recovery Process" ]
        , View.Common.icon
            { icon = FeatherIcons.arrowRight
            , size = View.Common.Small
            , tag = span [ css [ ml_1, mr_auto ] ]
            }
        ]


accountInput :
    { username : String
    , onUsernameInput : String -> msg
    , onBackupAutocompleted : String -> msg
    , onStartRecovery : msg
    }
    -> Html msg
accountInput element =
    form
        [ Events.onSubmit element.onStartRecovery
        , css
            [ sm
                [ flex_row
                , space_x_3
                , space_y_0
                ]
            , flex
            , flex_col
            , items_stretch
            , space_y_3
            , View.Dashboard.sectionGroupSpacings
            ]
        ]
        [ input
            [ type_ "text"
            , placeholder "my_username"
            , attribute "autocomplete" "username"
            , value element.username
            , Events.onInput element.onUsernameInput
            , css
                [ w_full
                , max_w_xl
                , View.Common.basicInputStyle
                ]
            ]
            []
        , input
            [ css [ hidden ]
            , type_ "password"
            , attribute "autocomplete" "password"
            , Events.onInput element.onBackupAutocompleted
            ]
            []
        , startRecoveryProcessButton
        ]
