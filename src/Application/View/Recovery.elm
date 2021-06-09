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
            [ sm [ pt_5 ]
            , bg_gray_600
            , flex
            , flex_col
            , flex_grow
            , items_center
            ]
        ]
        [ View.Dashboard.appHeader
            { styles = [ max_w_xl, w_full ]
            , subtitle = "Recovery"
            , content = []
            }
        , main_
            [ css
                [ sm
                    [ flex_grow_0
                    , mt_5
                    , rounded_lg
                    ]
                , bg_gray_900
                , flex
                , flex_col
                , flex_grow
                , max_w_xl
                ]
            ]
            content
        , footer
            [ css
                [ sm
                    [ mt_5
                    , px_10
                    ]
                , px_5
                , max_w_xl
                , w_full
                ]
            ]
            [ View.Dashboard.appFooterMobile [] ]
        ]


steps : List (Html msg) -> Html msg
steps content =
    ol
        [ css
            [ View.Dashboard.sectionGroupSpacings
            , flex
            , flex_col
            , space_y_3
            ]
        ]
        content


step : Int -> Bool -> String -> Html msg
step number active description =
    li
        [ css
            [ flex
            , flex_row
            , items_center
            , px_3
            ]
        ]
        [ span
            [ classList [ ( "active", active ) ]
            , css
                [ bg_gray_600
                , flex
                , font_mono
                , h_8
                , rounded_full
                , text_gray_300
                , text_lg
                , w_8
                , Css.withClass "active"
                    [ bg_purple_tint
                    , text_purple
                    ]
                ]
            ]
            [ span [ css [ m_auto ] ]
                [ text (String.fromInt number) ]
            ]
        , span
            [ css
                [ font_display
                , ml_3
                , text_sm
                ]
            ]
            [ text description ]
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
        , span [ css [ ml_2 ] ]
            [ text "Imported Backup" ]
        ]


backupUpload : Html msg
backupUpload =
    button
        [ css
            [ dark [ border_gray_200 ]
            , border_2
            , border_dashed
            , border_gray_500
            , flex
            , h_20
            , rounded_lg
            ]
        ]
        [ label
            [ css
                [ cursor_pointer
                , flex
                , flex_grow
                , items_center
                ]
            ]
            [ span
                [ css
                    [ font_display
                    , italic
                    , m_auto
                    , text_gray_300
                    , text_sm
                    ]
                ]
                [ text "drop or tap to upload your backup file" ]
            , input
                [ type_ "file"
                , css
                    [ absolute
                    , h_0
                    , opacity_0
                    , pointer_events_none
                    , w_0
                    ]
                ]
                []
            ]
        ]


iHaveNoBackupButton : Html msg
iHaveNoBackupButton =
    button
        [ css
            [ decoration_color_gray_300
            , font_display
            , italic
            , mx_auto
            , text_gray_300
            , text_sm
            , underline
            ]
        ]
        [ text "I don’t have a backup" ]
