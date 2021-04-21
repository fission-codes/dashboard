module View.Backup exposing (..)

import Css
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark)
import View.Dashboard


loggedInAs : String -> Html msg
loggedInAs username =
    p
        [ css
            [ View.Dashboard.sectionParagraphSpacings
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
            [ View.Dashboard.sectionParagraphSpacings
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
