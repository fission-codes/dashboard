module View.AuthFlow exposing (..)

import Css
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Svg exposing (svg)
import Svg.Attributes as SvgA
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark)


signinScreen : { onSignIn : msg } -> Html msg
signinScreen { onSignIn } =
    splashscreenShell
        { styles = []
        , content =
            [ main_
                [ css
                    [ flex
                    , flex_col
                    , items_center
                    , mt_8
                    , space_y_8
                    ]
                ]
                [ p
                    [ css
                        [ dark [ text_gray_400 ]
                        , max_w_sm
                        , px_5
                        , font_body
                        , text_base
                        , text_center
                        , text_gray_300
                        ]
                    ]
                    [ text "The Fission Dashboard lets you manage your Fission account and apps." ]
                , signinButton []
                    { onClick = onSignIn }
                ]
            ]
        }


loadingScreen : { message : String } -> Html msg
loadingScreen { message } =
    splashscreenShell
        { styles = []
        , content =
            [ View.Common.loadingAnimation View.Common.Normal [ css [ mt_16 ] ]
            , p
                [ css
                    [ dark [ text_gray_500 ]
                    , max_w_xs
                    , font_display
                    , italic
                    , text_gray_400
                    , text_base
                    , mt_8
                    ]
                ]
                [ text message ]
            ]
        }


errorScreen : { message : List (Html msg) } -> Html msg
errorScreen { message } =
    splashscreenShell
        { styles = []
        , content =
            [ span
                [ css
                    [ dark [ text_darkmode_red ]
                    , block
                    , mt_16
                    , text_red
                    ]
                ]
                [ FeatherIcons.alertTriangle
                    |> FeatherIcons.withSize 32
                    |> FeatherIcons.toHtml []
                    |> fromUnstyled
                ]
            , p
                [ css
                    [ dark [ text_gray_500 ]
                    , max_w_xs
                    , font_display
                    , italic
                    , text_gray_400
                    , text_base
                    , text_center
                    , mt_8
                    ]
                ]
                message
            ]
        }


splashscreenShell : { styles : List Css.Style, content : List (Html msg) } -> Html msg
splashscreenShell { styles, content } =
    div
        [ css
            [ Css.batch styles
            , flex
            , flex_col
            , flex_grow
            , h_full
            , items_center
            , mx_auto
            , overflow_hidden

            --
            , Css.marginTop (Css.vh 35)
            ]
        ]
        (View.Common.logo
            { styles = []
            , imageStyles =
                [ sm [ max_w_xs ]
                , max_w_xxs
                ]
            }
            :: content
        )


{-| This is basically copied together from the drive codebase.

Should maybe become a component common to both drive and the dashboard at some point.

-}
signinButton : List Css.Style -> { onClick : msg } -> Html msg
signinButton styles { onClick } =
    button
        [ css
            [ Css.batch styles

            --
            , antialiased
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
            , Css.focus [ shadow_outline ]
            ]
        , Events.onClick onClick
        ]
        [ div
            [ css
                [ flex
                , items_center
                , pt_px
                ]
            ]
            [ span
                [ css
                    [ mr_2
                    , opacity_50
                    , text_white
                    , w_4
                    ]
                ]
                [ fromUnstyled
                    (svg
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
                    )
                ]
            , text "Sign in with Fission"
            ]
        ]