module View.Dashboard exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (checked, class, classList, css, disabled, href, name, placeholder, src, type_, value)
import Html.Styled.Events as Events
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark)


headerHeight =
    h_20


sidebarWidth =
    w_80


appShell :
    { navigation :
        { items : List (Html msg)
        , expanded : Bool
        , onToggleExpanded : msg
        }
    , main : List (Html msg)
    }
    -> Html msg
appShell element =
    div
        [ css
            [ lg [ flex_row ]
            , flex
            , flex_col
            , flex_grow
            ]
        ]
        [ div
            [ css
                [ lg
                    [ border_r_2
                    , h_auto
                    , sidebarWidth
                    ]
                , flex_shrink_0
                , headerHeight
                ]
            ]
            []
        , div
            [ classList
                [ ( "expanded", element.navigation.expanded ) ]
            , css
                [ lg
                    [ border_r_2
                    , inset_y_0
                    , left_0
                    , sidebarWidth
                    ]
                , dark
                    [ bg_darkness_above
                    , border_gray_200
                    ]
                , Css.Global.withClass "expanded"
                    [ bottom_0
                    ]
                , bg_gray_600
                , border_gray_500
                , fixed
                , flex
                , flex_col
                , inset_x_0
                , top_0
                ]
            ]
            [ appHeader
                { menuExpanded = element.navigation.expanded
                , onToggle = element.navigation.onToggleExpanded
                }
            , nav
                [ classList
                    [ ( "expanded", element.navigation.expanded ) ]
                , css
                    [ lg [ flex ]
                    , Css.Global.withClass "expanded"
                        [ flex ]
                    , flex_col
                    , hidden
                    ]
                ]
                element.navigation.items
            , footer
                [ css
                    [ lg [ flex ]
                    , hidden
                    , px_6
                    , mt_auto
                    ]
                ]
                appFooter
            ]
        , main_
            [ css
                [ container
                , flex
                , flex_col
                , flex_grow
                , mx_auto
                ]
            ]
            element.main
        , footer
            [ css
                [ lg [ hidden ]
                , dark [ bg_darkness_above ]
                , bg_gray_600
                , flex
                , px_6
                ]
            ]
            appFooter
        ]


heading : String -> Html msg
heading headingText =
    h1
        [ css
            [ md
                [ px_16
                , py_8
                , text_4xl
                ]
            , font_display
            , px_8
            , py_5
            , text_2xl
            ]
        ]
        [ text headingText ]


appHeader : { menuExpanded : Bool, onToggle : msg } -> Html msg
appHeader element =
    header
        [ css
            [ container
            , mx_auto
            , px_5
            ]
        ]
        [ div
            [ css
                [ flex
                , flex_row
                , headerHeight
                , items_center
                ]
            ]
            [ View.Common.logo
                { styles = []
                , imageStyles = [ h_8 ]
                }
            , button
                [ Events.onClick element.onToggle
                , css
                    [ lg [ hidden ]
                    , dark [ text_gray_400 ]
                    , ml_auto
                    , rounded
                    , text_gray_300
                    ]
                ]
                [ (if element.menuExpanded then
                    FeatherIcons.x

                   else
                    FeatherIcons.menu
                  )
                    |> FeatherIcons.withSize 32
                    |> FeatherIcons.toHtml []
                    |> fromUnstyled
                ]
            ]
        ]


appFooter : List (Html msg)
appFooter =
    [ div
        [ css
            [ flex
            , flex_row
            , items_center
            , py_6
            , space_x_8
            ]
        ]
        [ img
            [ src "images/badge-solid-faded.svg"
            , css [ h_8 ]
            ]
            []
        , div
            [ css
                [ md
                    [ flex_row
                    , space_y_0
                    , space_x_8
                    , flex_grow_0
                    ]
                , flex
                , flex_col
                , flex_grow
                , items_start
                , space_y_2
                ]
            ]
            [ footerLink { styles = [], text = "Discord", url = "https://discord.gg/daDMAjE" }
            ]
        , div
            [ css
                [ md
                    [ flex_row
                    , space_y_0
                    , space_x_8
                    , flex_grow_0
                    ]
                , flex
                , flex_col
                , flex_grow
                , items_start
                , space_y_2
                ]
            ]
            [ footerLink { styles = [], text = "Forum", url = "https://talk.fission.codes/" }

            -- TODO Should we even have Terms of Service or Privacy Policy in the Dashboard at all?
            -- , footerLink [] { text = "Terms of Service", url = "#" }
            -- , footerLink [] { text = "Privacy Policy", url = "#" }
            ]
        ]
    ]


footerLink : { styles : List Css.Style, text : String, url : String } -> Html msg
footerLink element =
    a
        [ css
            [ Css.batch element.styles
            , dark [ text_gray_400 ]
            , rounded
            , text_gray_200
            , underline
            ]
        , href element.url
        ]
        [ text element.text ]


spacer : Html msg
spacer =
    hr
        [ css
            [ dark [ bg_gray_100 ]
            , bg_purple_tint
            , border_0
            , h_px
            , mx_5
            ]
        ]
        []
