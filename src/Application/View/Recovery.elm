module View.Recovery exposing (..)

import Css
import Css.Global as Css
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (classList, css, href, type_, value)
import Html.Styled.Events as Events
import Json.Decode as Json
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import Url exposing (Url)
import View.Common exposing (dark)
import View.Dashboard


appShell : List (Html msg) -> Html msg
appShell content =
    div
        [ css
            [ dark [ bg_darkness_above ]
            , sm [ pt_5 ]
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
                [ dark [ bg_darkness ]
                , sm
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
                [ dark
                    [ bg_gray_100
                    , text_gray_500
                    ]
                , bg_gray_600
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
                    [ dark
                        [ bg_darkmode_purple
                        , text_purple_tint
                        ]
                    , bg_purple_tint
                    , text_purple
                    ]
                ]
            ]
            [ span [ css [ m_auto ] ]
                [ text (String.fromInt number) ]
            ]
        , span
            [ css
                [ dark [ text_gray_400 ]
                , font_display
                , ml_3
                , text_sm
                , text_gray_200
                ]
            ]
            [ text description ]
        ]


backupUpload : { onUpload : Json.Decoder msg, isLoading : Bool } -> Html msg
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
        (if element.isLoading then
            [ span [ css [ m_auto ] ]
                [ View.Common.loadingAnimation View.Common.Medium
                    []
                ]
            ]

         else
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
        )


iHaveNoBackupButton : { onClick : msg } -> Html msg
iHaveNoBackupButton element =
    button
        [ Events.onClick element.onClick
        , css [ secondaryLinkStyle ]
        ]
        [ text "I don’t have a backup" ]


secondaryLinkStyle : Css.Style
secondaryLinkStyle =
    Css.batch
        [ decoration_color_gray_300
        , font_display
        , italic
        , mx_auto
        , text_gray_300
        , text_sm
        , underline
        ]


contactSupportMessage : Bool -> Html msg
contactSupportMessage shouldTryRetry =
    span []
        [ if shouldTryRetry then
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


buttonSendEmail :
    { isLoading : Bool
    , disabled : Bool
    , onClick : Maybe msg
    }
    -> Html msg
buttonSendEmail element =
    View.Common.button
        { isLoading = element.isLoading
        , disabled = element.disabled
        , onClick = element.onClick
        , icon = Just FeatherIcons.mail
        , label = "Send Email"
        , style = View.Common.primaryButtonStyle
        , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
        }


inputsRegainAccount :
    { onSubmit : msg
    , username : String
    , onInputUsername : String -> msg
    , isLoading : Bool
    , disabled : Bool
    , errors : List (Html msg)
    }
    -> Html msg
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
                [ dark [ text_gray_600 ]
                , font_body
                , text_sm
                , text_gray_300
                , flex
                , flex_col
                , space_y_1
                ]
            ]
            (List.concat
                [ [ span [] [ text "Enter your Account Username" ]
                  , input
                        [ type_ "text"
                        , value element.username
                        , Events.onInput element.onInputUsername
                        , css [ View.Common.basicInputStyle ]
                        ]
                        []
                  ]
                , element.errors
                ]
            )
        , buttonSendEmail
            { isLoading = element.isLoading
            , disabled = element.disabled
            , onClick = Nothing
            }
        ]


buttonGoBack : { onGoBack : msg, disabled : Bool } -> Html msg
buttonGoBack element =
    View.Common.button
        { isLoading = False
        , disabled = element.disabled
        , onClick = Just element.onGoBack
        , icon = Just FeatherIcons.arrowLeft
        , label = "I have no backup! Go Back"
        , style = View.Common.secondaryButtonStyle
        , spinnerStyle = []
        }


buttonRecoverAccount : { onRecoverAccount : msg, isLoading : Bool } -> Html msg
buttonRecoverAccount element =
    View.Common.button
        { icon = Just FeatherIcons.unlock
        , label = "Recover Account"
        , onClick = Just element.onRecoverAccount
        , isLoading = element.isLoading
        , disabled = element.isLoading
        , style = View.Common.primaryDangerButtonStyle
        , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
        }


restartRecoveryLink : Url -> Html msg
restartRecoveryLink url =
    a
        [ href (Url.toString url)
        , css [ secondaryLinkStyle ]
        ]
        [ text "Restart Recovery Process" ]


openAuthLobbyMessage : { lobbyUrl : String, username : String } -> Html msg
openAuthLobbyMessage element =
    View.Dashboard.sectionGroup [ min_h_120px ]
        [ div
            [ css
                [ m_auto
                , max_w_sm
                , text_center
                , View.Common.infoTextStyle
                ]
            ]
            [ text "Keep this page open."
            , br [] []
            , text "Open "
            , View.Common.underlinedLink []
                { location = element.lobbyUrl
                , external = True
                }
                [ text element.lobbyUrl ]
            , text " and sign in as "
            , i [] [ text element.username ]
            , text " to complete recovery."
            ]
        ]
