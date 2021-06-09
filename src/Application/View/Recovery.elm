module View.Recovery exposing (..)

import Css
import Css.Global as Css
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, classList, css, disabled, placeholder, type_, value)
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


accountInput :
    { username : String
    , backupLoaded : Bool
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
                [ items_start ]
            , flex
            , flex_col
            , items_stretch
            , space_y_3
            , View.Dashboard.sectionGroupSpacings
            ]
        ]
        [ label
            [ css
                [ flex
                , flex_col
                , items_start
                , space_y_1
                ]
            ]
            [ span
                [ css
                    [ dark [ text_gray_600 ]
                    , text_sm
                    , text_gray_300
                    ]
                ]
                [ text "Account Username" ]
            , input
                [ type_ "text"
                , placeholder "my_username"
                , attribute "autocomplete" "username"
                , value element.username
                , Events.onInput element.onUsernameInput
                , css
                    [ sm [ text_left ]
                    , w_full
                    , max_w_xl
                    , View.Common.basicInputStyle
                    ]
                ]
                []
            ]
        , input
            [ css [ hidden ]
            , type_ "password"
            , attribute "autocomplete" "password"
            , Events.onInput element.onBackupAutocompleted
            ]
            []
        , importedBackupCheckmark
            { backupLoaded = element.backupLoaded
            }
        , startRecoveryProcessButton
            { backupLoaded = element.backupLoaded
            , disabled = String.trim element.username == ""
            }
        ]


importedBackupCheckmark : { backupLoaded : Bool } -> Html msg
importedBackupCheckmark element =
    span
        [ classList [ ( "no-backup-loaded", not element.backupLoaded ) ]
        , css
            [ flex
            , flex_row
            , items_center
            , text_green
            , Css.withClass "no-backup-loaded" [ hidden ]
            ]
        ]
        [ View.Common.icon
            { icon = FeatherIcons.check
            , size = View.Common.Small
            , tag = span []
            }
        , span [ css [ ml_2 ] ] [ text "Imported Backup" ]
        ]


startRecoveryProcessButton : { backupLoaded : Bool, disabled : Bool } -> Html msg
startRecoveryProcessButton element =
    button
        [ type_ "submit"
        , disabled element.disabled
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
        [ span [ css [ ml_auto ] ]
            [ text
                (if element.backupLoaded then
                    "Recover Account"

                 else
                    "Start Recovery Process"
                )
            ]
        , View.Common.icon
            { icon = FeatherIcons.arrowRight
            , size = View.Common.Small
            , tag = span [ css [ ml_1, mr_auto ] ]
            }
        ]


loadingScreen : Html msg
loadingScreen =
    div
        [ css
            [ View.Dashboard.sectionGroupSpacings
            , sm
                [ min_h_120px
                , h_auto
                ]
            , flex
            , flex_grow
            , items_center
            , h_full
            ]
        ]
        [ div
            [ css
                [ flex
                , flex_col
                , items_center
                , m_auto
                , space_y_3
                ]
            ]
            [ View.Common.loadingAnimation View.Common.Small [ mx_auto ]
            , span [ css [ View.Common.infoTextStyle ] ]
                [ text "Reconstructing your account..." ]
            ]
        ]
