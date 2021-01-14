module View.AuthFlow exposing (..)

import Common
import Css.Classes exposing (..)
import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (checked, height, href, placeholder, src, style, type_, value, width)
import Html.Events as Events
import Svg exposing (Svg, svg)
import Svg.Attributes as SvgA
import View.Common


signinScreen : { onSignIn : msg } -> Html msg
signinScreen { onSignIn } =
    splashscreenShell
        [ space_y_8 ]
        [ p
            [ max_w_sm
            , px_5
            , font_body
            , text_base
            , text_center
            , text_gray_300
            , dark__text_gray_400
            ]
            [ text "The Fission Dashboard lets you manage your Fission account and apps." ]
        , signinButton []
            { onClick = onSignIn }
        ]


loadingScreen : { message : String } -> Html msg
loadingScreen { message } =
    splashscreenShell
        []
        [ span
            [ mt_16 ]
            [ loadingAnimation [] ]
        , p
            [ max_w_xs
            , font_display
            , italic
            , text_gray_400
            , text_base
            , mt_8

            --
            , dark__text_gray_500
            ]
            [ text message ]
        ]


splashscreenShell : List (Attribute msg) -> List (Html msg) -> Html msg
splashscreenShell attributes content =
    div
        (List.append attributes
            [ mx_auto
            , h_full
            , flex_grow
            , flex
            , flex_col
            , items_center
            , overflow_hidden
            ]
        )
        (View.Common.logo
            { attributes = [ style "margin-top" "35vh" ]
            , fissionAttributes =
                [ max_w_xxs
                , sm__max_w_xs
                ]
            }
            :: content
        )


loadingAnimation : List (Attribute msg) -> Html msg
loadingAnimation attributes =
    FeatherIcons.loader
        |> FeatherIcons.withSize 24
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> span
            (List.append attributes
                [ animate_spin
                , block
                , text_gray_300

                --
                , dark__text_gray_500
                ]
            )


{-| This is basically copied together from the drive codebase.

Should maybe become a component common to both drive and the dashboard at some point.

-}
signinButton : List (Attribute msg) -> { onClick : msg } -> Html msg
signinButton attributes { onClick } =
    button
        (List.append attributes
            [ antialiased
            , appearance_none
            , bg_purple
            , font_semibold
            , inline_block
            , leading_normal
            , mt_8
            , mx_auto
            , px_5
            , py_3
            , relative
            , rounded
            , text_sm
            , text_white
            , tracking_wider
            , transition_colors
            , uppercase

            --
            , duration_500
            , ease_out

            --
            , focus__shadow_outline

            --
            , Events.onClick onClick
            ]
        )
        [ Html.div
            [ flex
            , items_center
            , pt_px
            ]
            [ Html.span
                [ mr_2
                , opacity_50
                , text_white
                , w_4
                ]
                [ svg
                    [ SvgA.height "100%"
                    , SvgA.width "100%"
                    , SvgA.viewBox "0 0 98 94"
                    ]
                    [ Svg.path
                        [ SvgA.d "M30 76a12 12 0 110 11H18a18 18 0 010-37h26l-4-6H18a18 18 0 010-37c6 0 11 2 15 7l3 5 10 14h33a8 8 0 000-15H68a12 12 0 110-11h11a18 18 0 010 37H53l4 6h22a18 18 0 11-14 30l-3-4-10-15H18a8 8 0 000 15h12zm41-6l2 4 6 2a8 8 0 000-15H65l6 9zM27 25l-3-5-6-2a8 8 0 000 15h15l-6-8z"

                        --
                        , SvgA.fill "currentColor"

                        --
                        , SvgA.fillRule "nonzero"
                        ]
                        []
                    ]
                ]
            , Html.text "Sign in with Fission"
            ]
        ]
