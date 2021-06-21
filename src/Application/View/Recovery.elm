module View.Recovery exposing (..)

import Css
import Css.Global as Css
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, classList, css, disabled, href, placeholder, type_, value)
import Html.Styled.Events as Events
import Json.Decode as Json
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
                , w_full
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

                --
                , transition_colors
                , duration_500
                , delay_500

                --
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


backupUpload : { onUpload : Json.Decoder msg } -> Html msg
backupUpload element =
    label
        [ css
            [ dark [ border_gray_200 ]
            , border_2
            , border_dashed
            , border_gray_500
            , h_20
            , rounded_lg
            , cursor_pointer
            , flex
            , flex_grow
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
            , Events.on "change" element.onUpload
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


iHaveNoBackupButton : { onClick : msg } -> Html msg
iHaveNoBackupButton element =
    button
        [ Events.onClick element.onClick
        , css
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


contactSupportMessage : Bool -> Html msg
contactSupportMessage contactSupportRequested =
    span []
        [ if contactSupportRequested then
            text "Please try again or "

          else
            text "If you need any help "
        , a
            [ css
                [ underline
                , decoration_color_red
                , decoration_thickness_1_dot_5
                ]
            , href "https://fission.codes/support"
            ]
            [ text "contact our support" ]
        , text "."
        ]


importedBackupCheckmark : Html msg
importedBackupCheckmark =
    span
        [ css
            [ flex
            , flex_row
            , items_center
            , text_green
            , text_sm
            ]
        ]
        [ View.Common.icon
            { icon = FeatherIcons.checkCircle
            , size = View.Common.Small
            , tag = span [ css [ ml_auto ] ]
            }
        , span [ css [ ml_2, mr_auto ] ]
            [ text "Imported Backup File" ]
        ]


welcomeBackMessage : String -> Html msg
welcomeBackMessage username =
    span
        [ css
            [ text_center
            , View.Common.infoTextStyle
            ]
        ]
        [ text "Welcome back "
        , span [ css [ italic ] ] [ text username ]
        , text "!"
        ]


buttonSendEmail : { onClickSendEmail : msg } -> Html msg
buttonSendEmail element =
    buttonSendEmailBase [ Events.onClick element.onClickSendEmail ]


buttonSendEmailBase : List (Attribute msg) -> Html msg
buttonSendEmailBase attributes =
    button
        (List.append attributes
            [ css
                [ View.Common.primaryButtonStyle
                , flex
                , flex_row
                , items_center
                ]
            ]
        )
        [ View.Common.icon
            { icon = FeatherIcons.mail
            , size = View.Common.Small
            , tag = span [ css [ ml_auto ] ]
            }
        , span [ css [ ml_2, mr_auto ] ] [ text "Send Email" ]
        ]


inputsRegainAccount : { onSubmit : msg } -> Html msg
inputsRegainAccount element =
    form
        [ Events.onSubmit element.onSubmit
        , css
            [ flex
            , flex_col
            , space_y_5
            , View.Dashboard.sectionGroupSpacings
            ]
        ]
        [ label
            [ css
                [ font_body
                , text_sm
                , text_gray_300
                , flex
                , flex_col
                ]
            ]
            [ span [] [ text "Enter your Account Username" ]
            , input
                [ type_ "text"
                , css
                    [ mt_1
                    , View.Common.basicInputStyle
                    ]
                ]
                []
            ]
        , buttonSendEmailBase
            [ type_ "submit" ]
        ]


buttonGoBack : { onGoBack : msg } -> Html msg
buttonGoBack element =
    button
        [ Events.onClick element.onGoBack
        , css
            [ View.Common.secondaryButtonStyle
            , flex
            , flex_row
            , items_center
            ]
        ]
        [ View.Common.icon
            { icon = FeatherIcons.arrowLeft
            , size = View.Common.Small
            , tag = span [ css [ ml_auto ] ]
            }
        , span [ css [ ml_2, mr_auto ] ] [ text "I have a backup! Go Back" ]
        ]
