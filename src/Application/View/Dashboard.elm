module View.Dashboard exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (classList, css, href, src)
import Html.Styled.Events as Events
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark)


headerHeight : Css.Style
headerHeight =
    h_20


sidebarWidth : Css.Style
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
                , z_10
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


heading : List (Html msg) -> Html msg
heading headingItems =
    h1
        [ css
            [ md
                [ px_16
                , py_8
                , text_4xl
                ]
            , flex
            , flex_row
            , flex_wrap
            , font_display
            , items_center
            , px_10
            , py_5
            , text_2xl
            ]
        ]
        headingItems


headingSubLevel : { link : Route, label : String } -> Html msg
headingSubLevel { link, label } =
    a
        [ href (Route.toUrl link)
        , css
            [ md [ text_2xl ]
            , text_lg
            ]
        ]
        [ text label ]


headingSeparator : Html msg
headingSeparator =
    FeatherIcons.chevronRight
        |> FeatherIcons.withSize 32
        |> FeatherIcons.toHtml []
        |> fromUnstyled
        |> List.singleton
        |> span
            [ css
                [ md [ mx_5 ]
                , text_gray_400
                , mx_2
                ]
            ]


headingSubItem : String -> Html msg
headingSubItem label =
    span
        [ css
            [ md [ text_2xl ]
            , text_lg
            ]
        ]
        [ text label ]


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


section : List Css.Style -> List (Html msg) -> Html msg
section styles content =
    Html.Styled.section
        [ css
            [ Css.batch styles
            , my_8
            , max_w_3xl
            ]
        ]
        content


sectionTitle : List Css.Style -> List (Html msg) -> Html msg
sectionTitle styles content =
    h2
        [ css
            [ Css.batch styles
            , dark [ text_gray_600 ]
            , lg [ pl_10 ]
            , font_body
            , pl_5
            , text_gray_300
            , text_lg
            ]
        ]
        content


sectionParagraph : List Css.Style -> List (Html msg) -> Html msg
sectionParagraph styles content =
    p
        [ css
            [ Css.batch styles
            , sectionParagraphSpacings
            , flex
            , flex_col
            , space_y_5
            ]
        ]
        content


sectionParagraphSpacings : Css.Style
sectionParagraphSpacings =
    Css.batch
        [ lg [ px_10 ]
        , mt_5
        , px_5
        ]


sectionLoading : List (Html msg) -> Html msg
sectionLoading content =
    sectionParagraph
        [ View.Common.infoTextStyle
        , min_h_120px
        ]
        [ span
            [ css
                [ flex
                , flex_col
                , items_center
                , m_auto
                , space_y_3
                ]
            ]
            content
        ]


sectionLoadingIndicator : Html msg
sectionLoadingIndicator =
    View.Common.loadingAnimation View.Common.Small [ mx_auto ]


iconError : Html msg
iconError =
    FeatherIcons.alertTriangle
        |> FeatherIcons.withSize 24
        |> FeatherIcons.toHtml []
        |> fromUnstyled
        |> List.singleton
        |> span
            [ css
                [ dark [ text_darkmode_red ]
                , text_red
                , inline
                ]
            ]


iconSuccess : Html msg
iconSuccess =
    FeatherIcons.check
        |> FeatherIcons.withSize 24
        |> FeatherIcons.toHtml []
        |> fromUnstyled
        |> List.singleton
        |> span
            [ css
                [ dark [ text_darkmode_purple ]
                , text_purple
                , inline
                ]
            ]


sectionLoadingText : List (Html msg) -> Html msg
sectionLoadingText =
    span
        [ css
            [ text_center
            , mx_auto
            ]
        ]
