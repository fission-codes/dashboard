module View.Common exposing (..)

import Common
import Css
import Css.Media
import FeatherIcons
import Html.Attributes
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, disabled, href, src)
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


loadingAnimation : LoadingAnimationType -> List (Attribute msg) -> Html msg
loadingAnimation typ attributes =
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
            (css
                [ dark [ text_gray_500 ]
                , animate_spin
                , block
                , text_gray_300
                ]
                :: attributes
            )


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
        , css
            [ Css.batch styles
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
        , flex
        , flex_row
        , font_display
        , items_center
        , p_2
        , rounded
        , text_purple
        , text_xs
        , tracking_widest
        , uppercase
        ]


uppercaseButton : { isLoading : Bool, label : String, onClick : msg } -> Html msg
uppercaseButton { isLoading, label, onClick } =
    button
        [ Events.onClick onClick
        , disabled isLoading
        , css [ uppercaseButtonStyle ]
        ]
        (List.concat
            [ [ text label ]
            , Common.when isLoading
                [ loadingAnimation Small [ css [ ml_3 ] ] ]
            ]
        )


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
