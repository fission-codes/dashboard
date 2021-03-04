module View.AppList exposing (..)

import Common
import Css
import Css.Global
import FeatherIcons
import Html.Attributes
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, class, css, href, placeholder, type_, value)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, infoTextStyle, px)


sectionNewApp : Html msg
sectionNewApp =
    section
        [ css
            [ px_10
            , my_5
            , max_w_xl
            ]
        ]
        [ p [ css [ infoTextStyle ] ]
            [ text "Create a new app by uploading a folder with html, css and javascript files:" ]
        , label
            [ css
                [ dark
                    [ border_gray_200
                    , text_gray_300
                    ]
                , border_2
                , border_dashed
                , border_gray_400
                , cursor_pointer
                , flex
                , items_center
                , mt_4
                , rounded_lg
                , text_gray_300
                , Css.minHeight (px 120)
                , Css.hover
                    [ text_purple
                    , border_purple
                    , dark
                        [ border_darkmode_purple
                        , text_darkmode_purple
                        ]
                    ]
                ]
            ]
            [ span [ css [ mx_auto ] ]
                [ text "click, or drop a folder" ]
            , input
                [ type_ "file"
                , attribute "multiple" ""
                , attribute "directory" ""
                , attribute "webkitdirectory" ""
                , css
                    [ opacity_0
                    , absolute
                    , pointer_events_none
                    , w_0
                    , h_0
                    ]
                ]
                []
            ]
        , p
            [ css
                [ mt_10
                , infoTextStyle
                ]
            ]
            [ text "Don’t know how to get started? Start with the "
            , View.Common.underlinedLink []
                { location = "https://generator.fission.codes" }
                [ text "app generator" ]
            , text "!"
            , br [] []
            , br [] []
            , text "Are you comfortable with a terminal? Use the "
            , View.Common.underlinedLink []
                { location = "https://guide.fission.codes/developers/installation#installing-the-fission-cli" }
                [ text "fission command line interface" ]
            , text "!"
            ]
        ]


sectionAppList : List (Html msg) -> Html msg
sectionAppList appList =
    section
        [ css
            [ my_5
            , max_w_xl
            ]
        ]
        [ p
            [ css
                [ infoTextStyle
                , px_10
                ]
            ]
            [ text "Manage all Apps you’ve published:" ]
        , ul
            [ css
                [ px_8
                , mt_5
                , space_y_2
                ]
            ]
            (List.intersperse (View.Common.spacer [ mx_2 ])
                appList
            )
        ]


appListItem : { name : String, url : String } -> Html msg
appListItem { name, url } =
    li []
        [ a
            [ href url
            , css
                [ rounded_lg
                , block
                , p_2
                , Css.hover
                    [ dark [ bg_gray_200 ]
                    , bg_gray_600
                    ]
                ]
            ]
            [ p
                [ css
                    [ dark [ text_gray_400 ]
                    , font_body
                    , text_base
                    , text_gray_200
                    ]
                ]
                [ text name ]
            , View.Common.underlinedLink
                [ dark
                    [ text_darkmode_purple
                    , decoration_color_darkmode_purple
                    ]
                , decoration_color_purple
                , text_purple
                , whitespace_nowrap
                ]
                { location = url }
                [ text url
                , FeatherIcons.externalLink
                    |> FeatherIcons.withSize 16
                    |> FeatherIcons.toHtml [ Html.Attributes.style "display" "inline" ]
                    |> fromUnstyled
                    |> List.singleton
                    |> span [ css [ ml_1 ] ]
                ]
            ]
        ]
