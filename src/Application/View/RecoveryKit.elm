module View.RecoveryKit exposing (..)

import Base64
import Common
import Css
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, css, download, href, id, readonly, type_, value)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark)
import View.Dashboard


loggedInAs : String -> Html msg
loggedInAs username =
    p
        [ css
            [ View.Dashboard.sectionGroupSpacings
            , flex
            ]
        ]
        [ span
            [ css
                [ sm [ ml_0 ]
                , flex
                , flex_row
                , mx_auto
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
        ]


buttonGroup : List (Html msg) -> Html msg
buttonGroup content =
    div
        [ css
            [ View.Dashboard.sectionGroupSpacings
            , flex
            , flex_row
            , space_x_2
            , max_w_3xl
            ]
        ]
        content


buttonAskForPermission : msg -> Html msg
buttonAskForPermission msg =
    View.Common.button
        { isLoading = False
        , disabled = False
        , icon = Nothing
        , label = "Allow Creating a Recovery Kit"
        , onClick = Just msg
        , style =
            Css.batch
                [ sm [ flex_grow_0 ]
                , flex_grow
                , View.Common.primaryButtonStyle
                ]
        , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
        }


buttonCreateRecoveryKit : msg -> Html msg
buttonCreateRecoveryKit msg =
    View.Common.button
        { isLoading = False
        , disabled = False
        , icon = Nothing
        , label = "Create Recovery Kit"
        , onClick = Just msg
        , style =
            Css.batch
                [ sm [ flex_grow_0 ]
                , flex_grow
                , View.Common.primaryButtonStyle
                ]
        , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
        }


keyTextField :
    { id : String
    , key : String
    , keyVisible : Bool
    , onToggleVisibility : msg
    , onCopyToClipboard : msg
    }
    -> Html msg
keyTextField element =
    let
        buttonStyle =
            Css.batch
                [ dark
                    [ Css.active [ bg_gray_100 ]
                    , bg_gray_200
                    , border_gray_200
                    , text_gray_600
                    ]
                , Css.active [ bg_gray_900 ]
                , bg_gray_700
                , border
                , border_gray_500
                , text_gray_300
                ]
    in
    div
        [ css
            [ sm [ h_10 ]
            , flex
            , flex_row
            , h_12
            , w_full
            ]
        ]
        [ input
            [ css
                [ View.Common.basicInputStyle
                , border_r_0
                , flex_grow
                , flex_shrink
                , font_mono
                , h_full
                , rounded_r_none
                ]
            , type_ (Common.ifThenElse element.keyVisible "text" "password")
            , readonly True
            , id element.id
            , value element.key
            ]
            []
        , button
            [ css
                [ buttonStyle
                , border_r_0
                , flex
                , px_4
                ]
            , Events.onClick element.onToggleVisibility
            ]
            [ View.Common.icon
                { icon =
                    Common.ifThenElse element.keyVisible
                        FeatherIcons.eyeOff
                        FeatherIcons.eye
                , size = View.Common.Small
                , tag =
                    span
                        [ css
                            [ dark [ text_gray_600 ]
                            , m_auto
                            , text_gray_300
                            ]
                        ]
                }
            ]
        , button
            [ css
                [ buttonStyle
                , flex
                , flex_row
                , items_center
                , px_4
                , rounded_r
                ]
            , Events.onClick element.onCopyToClipboard
            ]
            [ span
                [ css
                    [ sm [ inline, mr_1 ]
                    , hidden
                    ]
                ]
                [ text "Copy to Clipboard" ]
            , View.Common.icon
                { icon = FeatherIcons.clipboard
                , size = View.Common.Small
                , tag =
                    span
                        [ css
                            [ dark [ text_gray_600 ]
                            , text_gray_300
                            ]
                        ]
                }
            ]
        ]


twoOptions : Html msg -> Html msg -> Html msg
twoOptions option1 option2 =
    div
        [ css
            [ sm
                [ flex_row
                , space_x_5
                , space_y_0
                ]
            , flex
            , flex_col
            , flex_grow
            , items_center
            , space_y_5
            ]
        ]
        [ option1
        , span
            [ css
                [ dark [ text_gray_600 ]
                , sm [ inline ]
                , italic
                , text_gray_300
                , hidden
                ]
            ]
            [ text "- or -" ]
        , option2
        ]


buttonStoreInPasswordManager : { onStore : msg, username : String, key : String } -> Html msg
buttonStoreInPasswordManager element =
    form
        [ css
            [ sm
                [ flex_grow_0
                , w_auto
                ]
            , flex
            , flex_grow
            , w_full
            ]
        , Events.onSubmit element.onStore
        ]
        [ input
            [ css [ hidden ]
            , type_ "text"
            , attribute "autocomplete" "username"
            , value element.username
            ]
            []
        , input
            [ css [ hidden ]
            , type_ "password"
            , attribute "autocomplete" "password"
            , value element.key
            ]
            []
        , button
            [ type_ "submit"
            , css
                [ sm [ flex_grow_0 ]
                , flex_grow
                , View.Common.primaryButtonStyle
                ]
            ]
            [ text "Store in Password Manager" ]
        ]


buttonDownload : { filename : String, file : String } -> Html msg
buttonDownload element =
    a
        [ css
            [ sm
                [ flex_grow_0
                , w_auto
                , mr_auto
                ]
            , View.Common.primaryButtonStyle
            , flex
            , flex_row
            , flex_grow
            , items_center
            , w_full
            ]
        , href
            ("data:text/plain;base64," ++ Base64.encode element.file)
        , download element.filename
        ]
        [ View.Common.icon
            { icon = FeatherIcons.download
            , size = View.Common.Small
            , tag = span [ css [ ml_auto, text_white ] ]
            }
        , span [ css [ ml_2, mr_auto ] ] [ text "Download" ]
        ]


buttonRecoveryKitCancel : msg -> Html msg
buttonRecoveryKitCancel msg =
    View.Common.button
        { icon = Nothing
        , label = "CANCEL"
        , onClick = Just msg
        , isLoading = False
        , disabled = False
        , style =
            Css.batch
                [ View.Common.uppercaseButtonStyle
                , ml_auto
                ]
        , spinnerStyle = []
        }
