module View.AppList exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Attributes
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, class, css, href, placeholder, type_, value)
import Html.Styled.Events as Events
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, infoTextStyle, px)
import View.Dashboard


sectionNewApp : Html msg
sectionNewApp =
    let
        uploadAnticipationStyle =
            [ dark
                [ border_darkmode_purple
                , text_darkmode_purple
                ]
            , text_purple
            , border_purple
            ]
    in
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] "Create a new App"
        , View.Dashboard.sectionParagraph [ infoTextStyle ]
            [ text "Upload a folder with HTML, CSS and javascript files:"
            , label
                [ css
                    [ Css.minHeight (px 120)
                    , Css.hover uploadAnticipationStyle
                    , Css.pseudoClass "focus-within" uploadAnticipationStyle
                    , Css.Global.withClass "drop-active" uploadAnticipationStyle
                    , dark
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
            ]
        , View.Dashboard.sectionParagraph [ infoTextStyle ]
            [ span []
                [ -- TODO: Add back when the generator is published and can create apps
                  --   text "Don’t know how to get started? Start with the "
                  -- , View.Common.underlinedLink []
                  --     { location = "https://generator.fission.codes" }
                  --     [ text "app generator" ]
                  -- , text "!"
                  -- , br [] []
                  -- , br [] []
                  -- ,
                  text "Are you comfortable with a terminal? Use the "
                , View.Common.underlinedLink []
                    { location = "https://guide.fission.codes/developers/installation#installing-the-fission-cli" }
                    [ text "fission command line interface" ]
                , text "!"
                ]
            ]
        ]


sectionAppList : Html msg -> Html msg
sectionAppList appList =
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] "Published Apps"
        , appList
        ]


appListLoading : List (Html msg) -> Html msg
appListLoading content =
    View.Dashboard.sectionParagraph
        [ infoTextStyle
        , Css.minHeight (px 120)
        ]
        [ span
            [ css
                [ m_auto
                , flex
                , flex_col
                , space_y_3
                ]
            ]
            content
        ]


appListLoadingIndicator : Html msg
appListLoadingIndicator =
    View.Common.loadingAnimation
        View.Common.Small
        [ css [ mx_auto ] ]


appListLoadingText : List (Html msg) -> Html msg
appListLoadingText =
    span
        [ css
            [ text_center
            , mx_auto
            ]
        ]


appListMargin : { outerAsPadding : Css.Style, innerAsPadding : Css.Style, innerAsMargin : Css.Style }
appListMargin =
    -- Invariant: inner + outer == View.Dashboard.sectionParagraphSpacings
    { outerAsPadding =
        Css.batch
            [ lg [ px_8 ]
            , px_3
            ]
    , innerAsPadding = px_2
    , innerAsMargin = mx_2
    }


appListLoaded : List (Html msg) -> Html msg
appListLoaded appItems =
    ul
        [ css
            [ appListMargin.outerAsPadding
            , mt_2
            , space_y_2
            ]
        ]
        (List.intersperse (View.Common.spacer [ appListMargin.innerAsMargin ])
            appItems
        )


appListItem : { name : String, url : String, link : Route } -> Html msg
appListItem { name, url, link } =
    li []
        [ a
            [ href (Route.toUrl link)
            , css
                [ rounded_lg
                , block
                , py_2
                , appListMargin.innerAsPadding
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
