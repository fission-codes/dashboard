module View.Common exposing (..)

import Common
import Css
import Css.Global
import Css.Media
import FeatherIcons
import Html.Attributes
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (classList, css, disabled, href, placeholder, src, target, type_, value)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)


logo :
    { styles : List Css.Style
    , imageStyles : List Css.Style
    }
    -> Html msg
logo { styles, imageStyles } =
    span
        [ css
            [ Css.batch styles
            , flex
            , flex_row
            , items_start
            , space_x_2
            ]
        ]
        [ img
            [ src "images/logo-dark-textonly.svg"
            , css
                [ Css.batch imageStyles
                , dark [ hidden ]
                ]
            ]
            []
        , img
            [ src "images/logo-light-textonly.svg"
            , css
                [ Css.batch imageStyles
                , dark [ block ]
                , hidden
                ]
            ]
            []
        , span
            [ css
                [ dark [ bg_darkmode_purple ]
                , bg_purple
                , font_display
                , p_1
                , rounded
                , text_white
                , text_xs
                , tracking_widest
                , uppercase
                ]
            ]
            [ text "Dashboard" ]
        ]


type LoadingAnimationType
    = Normal
    | Small


loadingAnimation : LoadingAnimationType -> List Css.Style -> Html msg
loadingAnimation typ styles =
    FeatherIcons.loader
        |> FeatherIcons.withSize
            (case typ of
                Normal ->
                    24

                Small ->
                    16
            )
        |> FeatherIcons.toHtml []
        |> fromUnstyled
        |> List.singleton
        |> span
            [ css
                [ dark [ text_gray_500 ]
                , animate_spin
                , block
                , text_gray_300
                , Css.batch styles
                ]
            ]


underlinedLink : List Css.Style -> { location : String } -> List (Html msg) -> Html msg
underlinedLink styles { location } =
    a
        [ href location
        , css
            [ Css.batch styles
            , dark [ decoration_color_gray_800 ]
            , underline
            , decoration_color_purple
            , decoration_thickness_1_dot_5
            ]
        ]


linkMarkedExternal : List Css.Style -> { link : String } -> Html msg
linkMarkedExternal styles { link } =
    a
        [ href link
        , target "_blank"
        , css
            [ Css.batch styles
            , Css.hover
                [ dark [ decoration_color_darkmode_purple ]
                , underline
                , decoration_color_purple
                , decoration_thickness_1_dot_5
                ]
            , dark [ text_darkmode_purple ]
            , text_purple
            ]
        ]
        [ text link
        , FeatherIcons.externalLink
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml [ Html.Attributes.style "display" "inline" ]
            |> fromUnstyled
            |> List.singleton
            |> span [ css [ ml_1 ] ]
        ]


dark : List Css.Style -> Css.Style
dark styles =
    Css.Media.withMediaQuery
        [ "(prefers-color-scheme: dark)" ]
        styles


uppercaseButtonStyle : Css.Style
uppercaseButtonStyle =
    Css.batch
        [ dark
            [ Css.disabled
                [ text_gray_500
                , bg_gray_300
                ]
            , bg_gray_200
            , bg_opacity_30
            , Css.active [ bg_opacity_10 ]
            , text_darkmode_purple
            ]
        , Css.active
            [ bg_purple_tint
            , bg_opacity_30
            ]
        , Css.disabled
            [ text_gray_300
            , bg_opacity_30
            , bg_gray_500
            ]
        , sm [ py_2 ]
        , bg_purple_tint
        , bg_opacity_10
        , font_display
        , px_3
        , py_2
        , rounded
        , text_purple
        , text_xs
        , tracking_widest
        , uppercase
        ]


dangerButtonStyle : Css.Style
dangerButtonStyle =
    Css.batch
        [ dark [ bg_darkmode_red ]
        , sm [ py_1 ]
        , font_body
        , text_gray_900
        , text_base
        , bg_red
        , rounded
        , px_3
        , py_2
        ]


button :
    { isLoading : Bool
    , disabled : Bool
    , label : String
    , onClick : Maybe msg
    , style : Css.Style
    , spinnerStyle : List Css.Style
    }
    -> Html msg
button element =
    Html.button
        [ case element.onClick of
            Just message ->
                Events.onClick message

            Nothing ->
                type_ "submit"
        , disabled (element.isLoading || element.disabled)
        , css
            [ element.style
            , flex
            , flex_row
            , flex_shrink_0
            , items_center
            ]
        ]
        (List.concat
            [ [ span [ css [ text_center, mx_auto ] ] [ text element.label ] ]
            , Common.when element.isLoading
                [ loadingAnimation Small
                    [ Css.batch element.spinnerStyle
                    , ml_3
                    ]
                ]
            ]
        )


basicInputStyle : Css.Style
basicInputStyle =
    Css.batch
        [ Css.focus
            [ dark [ border_gray_200 ]
            , border_purple
            ]
        , dark
            [ text_gray_500
            , bg_gray_100
            , border_gray_200
            ]
        , sm [ py_1 ]
        , bg_gray_900
        , border
        , border_gray_500
        , flex_grow
        , flex_shrink
        , font_display
        , min_w_0
        , placeholder_gray_400
        , px_3
        , py_2
        , rounded
        , text_base
        , text_center
        , text_gray_200

        --
        , Css.Global.withClass "error"
            [ dark
                [ border_darkmode_red
                , ring_darkmode_red
                ]
            , border_red
            , ring_red
            ]
        , Css.disabled
            [ dark
                [ bg_gray_200
                , border_gray_200
                , ring_gray_200
                ]
            , bg_gray_600
            , border_gray_600
            , text_gray_400
            ]
        ]


input :
    { placeholder : String
    , value : String
    , onInput : String -> msg
    , inErrorState : Bool
    , disabled : Bool
    , style : Css.Style
    }
    -> Html msg
input element =
    Html.input
        [ type_ "text"
        , placeholder element.placeholder
        , value element.value
        , Events.onInput element.onInput
        , disabled element.disabled

        --
        , css
            [ element.style
            ]
        , classList
            [ ( "error", element.inErrorState ) ]
        ]
        []


px : Float -> Css.Rem
px n =
    Css.rem (n / 16)


infoTextStyle : Css.Style
infoTextStyle =
    Css.batch
        [ dark [ text_gray_400 ]
        , text_sm
        , text_gray_200
        ]


monoInfoText : List (Html msg) -> Html msg
monoInfoText =
    span [ css [ font_mono, text_xs ] ]


sectionSpacer : Html msg
sectionSpacer =
    spacer [ mx_5 ]


spacer : List Css.Style -> Html msg
spacer styles =
    hr
        [ css
            [ Css.batch styles
            , dark [ bg_gray_200 ]
            , bg_purple_tint
            , border_0
            , h_px
            ]
        ]
        []


warning : List (Html msg) -> Html msg
warning content =
    span
        [ css
            [ dark
                [ text_darkmode_red
                ]
            , flex
            , flex_row
            , items_center
            , text_red
            , text_sm
            , space_x_2
            ]
        ]
        [ FeatherIcons.alertTriangle
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span []
        , span
            [ css [ font_display ] ]
            content
        ]
