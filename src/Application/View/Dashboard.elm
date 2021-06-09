module View.Dashboard exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (classList, css, href, src, target)
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


appShellWithNavigation :
    { navigation :
        { items : List (Html msg)
        , expanded : Bool
        , onToggleExpanded : msg
        , onLogout : msg
        }
    , main : List (Html msg)
    }
    -> Html msg
appShellWithNavigation element =
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
                { styles = [ container, mx_auto ]
                , subtitle = "Dashboard"
                , content =
                    [ hamburgerMenu
                        { menuExpanded = element.navigation.expanded
                        , onToggle = element.navigation.onToggleExpanded
                        }
                    ]
                }
            , nav
                [ classList
                    [ ( "expanded", element.navigation.expanded ) ]
                , css
                    [ lg [ flex ]
                    , Css.Global.withClass "expanded" [ flex ]
                    , flex_col
                    , hidden
                    ]
                ]
                element.navigation.items
            , div
                [ classList
                    [ ( "expanded", element.navigation.expanded ) ]
                , css
                    [ lg [ flex ]
                    , Css.Global.withClass "expanded" [ flex ]
                    , mt_auto
                    , px_8
                    , py_6
                    , flex_col
                    , items_start
                    , hidden
                    ]
                ]
                [ button
                    [ Events.onClick element.navigation.onLogout
                    , css
                        [ Css.hover
                            [ dark [ text_darkmode_purple ]
                            , text_purple
                            ]
                        , dark [ text_gray_400 ]
                        , flex
                        , flex_row
                        , items_center
                        , text_gray_300
                        ]
                    ]
                    [ View.Common.icon
                        { icon = FeatherIcons.logOut
                        , size = View.Common.Small
                        , tag = span []
                        }
                    , span [ css [ ml_2 ] ] [ text "Logout" ]
                    ]
                ]
            , footer
                [ css
                    [ lg [ flex ]
                    , hidden
                    , px_6
                    ]
                ]
                appFooterSidebar
            ]
        , main_
            [ css
                [ flex
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
            [ appFooterMobile [] ]
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
            , max_w_3xl
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
    View.Common.icon
        { icon = FeatherIcons.chevronRight
        , size = View.Common.Big
        , tag =
            span
                [ css
                    [ md [ mx_5 ]
                    , text_gray_400
                    , mx_2
                    ]
                ]
        }


headingSubItem : String -> Html msg
headingSubItem label =
    span
        [ css
            [ md [ text_2xl ]
            , text_lg
            ]
        ]
        [ text label ]


hamburgerMenu : { menuExpanded : Bool, onToggle : msg } -> Html msg
hamburgerMenu element =
    View.Common.icon
        { icon =
            if element.menuExpanded then
                FeatherIcons.x

            else
                FeatherIcons.menu
        , size = View.Common.Big
        , tag =
            button
                [ Events.onClick element.onToggle
                , css
                    [ lg [ hidden ]
                    , dark [ text_gray_400 ]
                    , ml_auto
                    , rounded
                    , text_gray_300
                    ]
                ]
        }


appHeader : { styles : List Css.Style, subtitle : String, content : List (Html msg) } -> Html msg
appHeader element =
    header
        [ css
            [ Css.batch element.styles
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
            (List.append
                [ View.Common.logo
                    { styles = []
                    , subtitle = element.subtitle
                    , imageStyles = [ h_8 ]
                    }
                ]
                element.content
            )
        ]


appFooterMobile : List Css.Style -> Html msg
appFooterMobile styles =
    div
        [ css
            [ Css.batch styles
            , flex
            , flex_row
            , items_center
            , py_6
            , space_x_8
            , overflow_y_hidden
            ]
        ]
        [ img
            [ src "/images/badge-solid-faded.svg"
            , css [ h_8 ]
            ]
            []
        , footerLink { styles = [], text = "Discord", url = "https://fission.codes/discord" }
        , footerLink { styles = [], text = "Guide", url = "https://guide.fission.codes/accounts-and-dashboard/dashboard" }
        , footerLink { styles = [], text = "Forum", url = "https://talk.fission.codes/" }
        , footerLink { styles = [], text = "Support", url = "https://fission.codes/support" }
        ]


appFooterSidebar : List (Html msg)
appFooterSidebar =
    let
        linkContainer content =
            div
                [ css
                    [ flex
                    , flex_col
                    , flex_grow
                    , items_start
                    , space_y_2
                    ]
                ]
                content
    in
    [ div
        [ css
            [ flex
            , flex_row
            , items_center
            , py_6
            , space_x_8
            , overflow_y_hidden
            ]
        ]
        [ img
            [ src "/images/badge-solid-faded.svg"
            , css [ h_8 ]
            ]
            []
        , linkContainer
            [ footerLink { styles = [], text = "Discord", url = "https://fission.codes/discord" }
            , footerLink { styles = [], text = "Guide", url = "https://guide.fission.codes/accounts-and-dashboard/dashboard" }
            ]
        , linkContainer
            [ footerLink { styles = [], text = "Forum", url = "https://talk.fission.codes/" }
            , footerLink { styles = [], text = "Support", url = "https://fission.codes/support" }
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
        , target "_blank"
        ]
        [ text element.text ]


section : List Css.Style -> List (Html msg) -> Html msg
section styles content =
    Html.Styled.section
        [ css
            [ Css.batch styles
            , my_8
            , max_w_3xl
            , space_y_5
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


sectionParagraph : List (Html msg) -> Html msg
sectionParagraph content =
    p
        [ css
            [ View.Common.infoTextStyle
            , sectionGroupSpacings
            ]
        ]
        content


sectionGroup : List Css.Style -> List (Html msg) -> Html msg
sectionGroup styles content =
    div
        [ css
            [ Css.batch styles
            , sectionGroupSpacings
            , flex
            , flex_col
            , space_y_5
            ]
        ]
        content


sectionGroupSpacings : Css.Style
sectionGroupSpacings =
    Css.batch
        [ lg [ px_10 ]
        , px_5
        ]


sectionLoading : List (Html msg) -> Html msg
sectionLoading content =
    sectionGroup
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
    View.Common.icon
        { icon = FeatherIcons.alertTriangle
        , size = View.Common.Normal
        , tag =
            span
                [ css
                    [ dark [ text_darkmode_red ]
                    , text_red
                    , inline
                    ]
                ]
        }


iconSuccess : Html msg
iconSuccess =
    View.Common.icon
        { icon = FeatherIcons.check
        , size = View.Common.Normal
        , tag =
            span
                [ css
                    [ dark [ text_darkmode_purple ]
                    , text_purple
                    , inline
                    ]
                ]
        }


sectionLoadingText : List (Html msg) -> Html msg
sectionLoadingText =
    span
        [ css
            [ text_center
            , mx_auto
            ]
        ]
