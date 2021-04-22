module View.Backup exposing (..)

import Css
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, css, id, readonly, type_, value)
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


askForPermissionButton : msg -> Html msg
askForPermissionButton msg =
    View.Common.button
        { isLoading = False
        , disabled = False
        , label = "Give Permission for a Backup"
        , onClick = Just msg
        , style =
            Css.batch
                [ sm [ flex_grow_0 ]
                , flex_grow
                , View.Common.primaryButtonStyle
                ]
        , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
        }


secureBackupButton : msg -> Html msg
secureBackupButton msg =
    View.Common.button
        { isLoading = False
        , disabled = False
        , label = "Secure Backup"
        , onClick = Just msg
        , style =
            Css.batch
                [ sm [ flex_grow_0 ]
                , flex_grow
                , View.Common.primaryButtonStyle
                ]
        , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
        }


keyTextField : { id : String, key : String, onCopyToClipboard : msg } -> Html msg
keyTextField element =
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
                , h_full
                , rounded_r_none
                ]
            , readonly True
            , id element.id
            , value element.key
            ]
            []
        , button
            [ css
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
                , flex
                , flex_row
                , items_center
                , px_4
                , rounded_r
                , text_gray_300
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


storeInBrowserButton : { onStore : msg, username : String, key : String } -> Html msg
storeInBrowserButton element =
    form
        [ Events.onSubmit element.onStore ]
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
            [ text "Store in Browser" ]
        ]
