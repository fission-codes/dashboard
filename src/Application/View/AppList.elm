module View.AppList exposing (..)

import Css
import Css.Global
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, class, css, href, placeholder, src, tabindex, target, title, type_, value)
import Html.Styled.Events as Events
import Json.Decode as Json
import Route exposing (Route)
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, infoTextStyle, px)
import View.Dashboard
import View.UploadDropzone


uploadDropzone :
    { onPublishStart : msg
    , onPublishEnd : msg
    , onPublishFail : msg
    , onPublishAction : String -> msg
    , onPublishProgress : { progress : Int, total : Int, info : String } -> msg
    , appName : Maybe String
    , dashedBorder : Bool
    }
    -> List (Html msg)
    -> Html msg
uploadDropzone element content =
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
    View.UploadDropzone.view
        [ css
            [ dark [ text_gray_300 ]
            , flex
            , text_gray_300
            , mt_4
            , min_h_120px
            ]
        , if element.dashedBorder then
            css
                [ Css.hover uploadAnticipationStyle
                , Css.pseudoClass "focus-within" uploadAnticipationStyle
                , Css.Global.withClass "dropping" uploadAnticipationStyle
                , dark [ border_gray_200 ]
                , border_2
                , border_dashed
                , border_gray_400
                , cursor_pointer
                , rounded_lg
                ]

          else
            css []
        ]
        { onPublishStart = element.onPublishStart
        , onPublishEnd = element.onPublishEnd
        , onPublishFail = element.onPublishFail
        , onPublishAction = element.onPublishAction
        , onPublishProgress = element.onPublishProgress
        , appName = element.appName |> Maybe.withDefault ""
        }
        content


clickableDropzone : Html msg
clickableDropzone =
    label
        [ css
            [ flex
            , flex_grow
            , items_center
            , cursor_pointer
            ]
        ]
        [ span [ css [ mx_auto ] ]
            [ text "drop files and folders or click to choose" ]
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


dropzoneLoading : List (Html msg) -> Html msg
dropzoneLoading content =
    span
        [ css
            [ flex
            , flex_col
            , flex_grow
            , items_center
            , m_auto
            , px_5
            , space_y_3
            ]
        ]
        content


dropzoneProgressIndicator : { progress : Int, total : Int } -> Html msg
dropzoneProgressIndicator element =
    progress
        [ value (String.fromInt element.progress)
        , Html.Styled.Attributes.max (String.fromInt element.total)
        , css
            [ appearance_none
            , w_full
            , Css.height (px 4)
            , Css.pseudoElement "-webkit-progress-bar"
                [ dark [ bg_darkness_above ]
                , bg_gray_600
                ]
            , Css.pseudoElement "-webkit-progress-value"
                [ dark [ bg_darkmode_purple ]
                , bg_purple
                ]
            , Css.pseudoElement "-moz-progress-bar"
                [ dark [ bg_darkmode_purple ]
                , bg_purple
                ]
            ]
        ]
        []


previewIframe : { url : String } -> Html msg
previewIframe { url } =
    let
        previewWidth =
            1440

        previewHeight =
            900
    in
    div
        [ css
            [ Css.width (px (previewWidth / 4))
            , Css.height (px (previewHeight / 4))
            , relative
            , shadow
            , overflow_hidden
            , inline_block
            ]
        ]
        [ a
            [ title ("Live preview of " ++ url)
            , href url
            , target "_blank"
            , css
                [ absolute
                , transform
                , scale_25
                , origin_top_left
                , bg_white
                ]
            ]
            [ iframe
                [ src url
                , attribute "frameborder" "0"
                , attribute "focusable" "false"
                , tabindex -1
                , css
                    [ Css.width (px previewWidth)
                    , Css.height (px previewHeight)
                    , pointer_events_none
                    ]
                ]
                []
            ]
        ]


sectionAppList : Html msg -> Html msg
sectionAppList appList =
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ text "Published Apps" ]
        , appList
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
            , View.Common.linkMarkedExternal []
                { link = url }
            ]
        ]
