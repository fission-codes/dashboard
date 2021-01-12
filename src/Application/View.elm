module View exposing (..)

import Common
import Css.Classes exposing (..)
import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (checked, height, href, placeholder, src, style, type_, value, width)
import Html.Events as Events
import Svg exposing (Svg, svg)
import Svg.Attributes as SvgA


appShell :
    { header : List (Html msg)
    , main : List (Html msg)
    , footer : List (Html msg)
    }
    -> List (Html msg)
appShell content =
    [ div
        [ flex
        , bg_gray_600
        , sticky
        , inset_x_0
        , top_0
        ]
        content.header
    , main_
        [ mx_auto
        , container
        , flex
        , flex_col
        , flex_grow
        ]
        content.main
    , footer
        [ flex
        , bg_gray_600
        ]
        content.footer
    ]


appHeader : List (Html msg)
appHeader =
    [ header
        [ container
        , px_5
        , mx_auto
        ]
        [ div
            [ border_b
            , border_gray_500
            , h_20
            , flex
            , flex_row
            , items_center
            ]
            [ logo
                { attributes = []
                , fissionAttributes = [ h_8 ]
                }

            -- reintroduce, once there are more than 1 page
            -- , menuButton []
            ]
        ]
    ]


appFooter : List (Html msg)
appFooter =
    [ footer
        [ mx_auto
        , container
        , px_6
        ]
        [ div
            [ flex
            , flex_row
            , border_t
            , border_gray_500
            , py_6
            , space_x_8
            , items_center
            ]
            [ img
                [ src "images/badge-solid-faded.svg"
                , h_8
                ]
                []
            , span
                [ text_gray_200
                , mr_auto
                , flex_grow
                , hidden

                --
                , md__inline
                ]
                [ text "Fission Internet Software" ]
            , div
                [ flex_grow
                , flex
                , flex_col
                , items_start
                , text_gray_200
                , underline
                , space_y_2

                --
                , md__flex_row
                , md__space_y_0
                , md__space_x_8
                , md__flex_grow_0
                ]
                [ footerLink [] { text = "Discord", url = "#" }
                , footerLink [] { text = "Forum", url = "#" }
                ]
            , div
                [ flex_grow
                , flex
                , flex_col
                , items_start
                , text_gray_200
                , underline
                , space_y_2

                --
                , md__flex_row
                , md__space_y_0
                , md__space_x_8
                , md__flex_grow_0
                ]
                [ footerLink [] { text = "Terms of Service", url = "#" }
                , footerLink [] { text = "Privacy Policy", url = "#" }
                ]
            ]
        ]
    ]


footerLink : List (Attribute msg) -> { text : String, url : String } -> Html msg
footerLink attributes element =
    a
        (List.append attributes
            [ text_gray_200
            , underline
            , href element.url
            ]
        )
        [ text element.text ]


dashboardHeading : String -> Html msg
dashboardHeading headingText =
    h1
        [ font_display
        , px_8
        , py_5
        , text_2xl

        --
        , md__px_16
        , md__py_8
        , md__text_4xl
        ]
        [ text headingText ]


settingSection : List (Html msg) -> Html msg
settingSection content =
    section [ my_8 ] content


settingText : List (Html msg) -> Html msg
settingText content =
    span [ font_display, text_gray_200 ] content


settingInput :
    { placeholder : String
    , value : String
    , onInput : String -> msg
    , inErrorState : Bool
    }
    -> Html msg
settingInput element =
    input
        (List.concat
            [ [ type_ "text"
              , placeholder element.placeholder
              , value element.value
              , Events.onInput element.onInput

              --
              , flex_grow
              , flex_shrink
              , min_w_0
              , max_w_xs
              , text_base
              , font_display
              , text_gray_200
              , placeholder_gray_400
              , px_3
              , py_1
              , border
              , border_gray_500
              , bg_gray_900
              , rounded
              ]
            , Common.when (not element.inErrorState)
                [ focus__border_purple ]
            , Common.when element.inErrorState
                [ border_red ]
            ]
        )
        []


infoTextAttributes : List (Attribute msg)
infoTextAttributes =
    [ text_sm, text_gray_200 ]


sectionUsername : { username : List (Html msg) } -> Html msg
sectionUsername element =
    settingSection
        [ sectionTitle [] "Username"
        , sectionParagraph
            [ responsiveGroup
                [ span
                    (md__w_1over3 :: infoTextAttributes)
                    [ text "Your username is unique among all fission users." ]
                , div [ flex, flex_col, space_y_5 ] element.username
                ]
            ]
        ]


settingViewing : { value : String, onClickUpdate : msg } -> Html msg
settingViewing element =
    span
        [ flex
        , flex_row
        , items_center
        , space_x_2
        ]
        [ settingText [ Html.text element.value ]
        , button
            (Events.onClick element.onClickUpdate
                :: uppercaseButtonAttributes
            )
            [ text "Update" ]
        ]


settingEditing :
    { value : String
    , onInput : String -> msg
    , placeholder : String
    , inErrorState : Bool
    , onSave : msg
    }
    -> Html msg
settingEditing element =
    form
        [ flex
        , flex_row
        , items_center
        , space_x_2
        , Events.onSubmit element.onSave
        ]
        [ settingInput
            { value = element.value
            , onInput = element.onInput
            , placeholder = element.placeholder
            , inErrorState = element.inErrorState
            }
        , input
            (type_ "submit"
                :: value "Save"
                :: uppercaseButtonAttributes
            )
            []
        ]


sectionEmail :
    { email : List (Html msg)
    , productUpdates : Bool
    , onCheckProductUpdates : Bool -> msg
    , verificationStatus : List (Html msg)
    }
    -> Html msg
sectionEmail element =
    settingSection
        [ sectionTitle [] "Email"
        , sectionParagraph
            [ responsiveGroup
                [ groupHeading [ text "Your email" ]
                , div
                    [ flex
                    , flex_col
                    , space_y_2
                    ]
                    element.email
                ]
            , responsiveGroup
                [ groupHeading []
                , span
                    [ flex
                    , flex_row
                    , items_center
                    , space_x_2
                    ]
                    element.verificationStatus
                ]
            , let
                checkboxInfo =
                    [ text "Check to subscribe to occasional product updates. "
                    , a
                        [ href "https://5d04d668.sibforms.com/serve/MUIEAD0fi3_BJE-4eieeuK6_0_XZaOPiu1_nfh56jvP1pV9uWy9OLxWLrHtjC148osZF2vcRb0XAymSdzFxhVD7XgvvODjbrp5ClBvQLmY70hyvU1JKu7ucoOP5KFJVRcfNgYN-3qvVppxg72KGyYZlWAJr2IkO7Ae9CIhnjpufaP7npZGPrBFzpmyEaKKLGYyqu0dnQIobGLAMM"

                        --
                        , underline
                        , text_decoration_purple
                        , text_decoration_3over2
                        ]
                        [ text "Manage all your subscriptions here" ]
                    ]
              in
              responsiveGroup
                [ groupHeading checkboxInfo
                , label
                    [ flex
                    , flex_row
                    , space_x_2
                    , items_center
                    , self_start
                    ]
                    [ input
                        [ type_ "checkbox"
                        , checked element.productUpdates
                        , Events.onCheck element.onCheckProductUpdates
                        ]
                        []
                    , span
                        [ font_display
                        , text_gray_200
                        , select_none
                        ]
                        [ text "Product Updates" ]
                    ]
                , span (md__hidden :: infoTextAttributes)
                    checkboxInfo
                ]
            ]
        ]


sectionManageAccount : Html msg
sectionManageAccount =
    settingSection
        [ sectionTitle [] "Manage Account"
        , sectionParagraph
            [ responsiveGroup
                [ span
                    (md__w_1over3 :: infoTextAttributes)
                    [ text "Permanently delete your account and all associated data. "
                    , a [] [ text "Read more" ]
                    ]
                , form
                    [ flex
                    , flex_row
                    , space_x_3
                    ]
                    [ input
                        [ type_ "text"
                        , placeholder "Your account name"

                        --
                        , flex_grow
                        , flex_shrink
                        , min_w_0
                        , max_w_xs
                        , text_base
                        , font_display
                        , text_gray_200
                        , placeholder_gray_400
                        , px_3
                        , py_1
                        , border
                        , border_gray_500
                        , bg_gray_900
                        , rounded

                        --
                        , focus__border_purple
                        ]
                        []
                    , input
                        [ type_ "submit"
                        , value "Delete Account"

                        --
                        , rounded
                        , bg_red
                        , text_white
                        , font_body
                        , text_base
                        , px_3
                        , py_1
                        ]
                        []
                    ]
                ]
            ]
        ]


responsiveGroup : List (Html msg) -> Html msg
responsiveGroup content =
    div
        [ flex
        , flex_col
        , space_y_2

        --
        , md__flex_row
        , md__space_y_0
        , md__space_x_5
        ]
        content


groupHeading : List (Html msg) -> Html msg
groupHeading content =
    span
        (hidden
            --
            :: md__inline
            :: md__w_1over3
            :: infoTextAttributes
        )
        content


type VerificationStatus
    = NotVerified
    | Verified


verificationStatus : VerificationStatus -> Html msg
verificationStatus status =
    span
        [ case status of
            Verified ->
                text_purple

            NotVerified ->
                text_red
        , flex
        , flex_row
        , items_center
        , space_x_2
        ]
        [ (case status of
            Verified ->
                FeatherIcons.check

            NotVerified ->
                FeatherIcons.alertTriangle
          )
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml []
            |> List.singleton
            |> span []
        , span [ font_display ]
            [ case status of
                Verified ->
                    text "Verified"

                NotVerified ->
                    text "Not Verified"
            ]
        ]


warning : List (Html msg) -> Html msg
warning content =
    span
        [ flex
        , flex_row
        , items_center
        , text_red
        , text_sm
        , space_x_2
        ]
        [ FeatherIcons.alertTriangle
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml []
            |> List.singleton
            |> span []
        , span
            [ font_display ]
            content
        ]


sectionParagraph : List (Html msg) -> Html msg
sectionParagraph content =
    p
        [ pl_10
        , pr_5
        , mt_5
        , flex
        , flex_col
        , space_y_5
        ]
        content


sectionTitle : List (Attribute msg) -> String -> Html msg
sectionTitle attributes title =
    h2
        [ text_gray_300
        , font_body
        , text_lg
        , ml_5
        ]
        [ text title ]


spacer : Html msg
spacer =
    hr
        [ h_px
        , bg_purple_tint
        , border_0
        , mx_5
        ]
        []


uppercaseButtonAttributes : List (Attribute msg)
uppercaseButtonAttributes =
    [ uppercase
    , text_purple
    , font_display
    , text_xs
    , tracking_widest
    , p_2
    ]


logo :
    { attributes : List (Attribute msg)
    , fissionAttributes : List (Attribute msg)
    }
    -> Html msg
logo { attributes, fissionAttributes } =
    span
        (List.append attributes
            [ flex
            , flex_row
            , items_start
            , space_x_2
            ]
        )
        [ img
            (src "images/logo-dark-textonly.svg"
                :: fissionAttributes
            )
            []
        , span
            [ bg_purple
            , uppercase
            , text_white
            , font_display
            , tracking_widest
            , rounded
            , p_1
            , text_xs
            ]
            [ text "Dashboard" ]
        ]


menuButton : List (Attribute msg) -> Html msg
menuButton attributes =
    button
        (List.append attributes
            [ ml_auto
            , text_gray_300
            ]
        )
        [ FeatherIcons.menu
            |> FeatherIcons.withSize 32
            |> FeatherIcons.toHtml []
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
        (logo
            { attributes = [ style "margin-top" "35vh" ]
            , fissionAttributes =
                [ max_w_xxs
                , sm__max_w_xs
                ]
            }
            :: content
        )


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
            ]
            [ text message ]
        ]


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
