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
            , flex
            , flex_col
            , items_center
            , flex_grow
            , bg_gray_600
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
                    [ rounded_lg
                    , mt_5
                    , flex_grow_0
                    ]
                , flex
                , flex_col
                , flex_grow
                , bg_gray_900
                , max_w_xl
                ]
            ]
            content
        , footer
            [ css
                [ px_5
                , max_w_xl
                , w_full
                ]
            ]
            [ View.Dashboard.appFooterMobile [] ]
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
