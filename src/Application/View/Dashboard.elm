module View.Dashboard exposing (..)

import Common
import Css.Classes exposing (..)
import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (checked, height, href, placeholder, src, style, type_, value, width)
import Html.Events as Events
import View.Common


appShell :
    { main : List (Html msg)
    }
    -> List (Html msg)
appShell content =
    [ div
        [ flex
        , flex_col
        , flex_grow
        ]
        [ div
            [ flex
            , flex_shrink_0
            , bg_gray_600
            , sticky
            , inset_x_0
            , top_0

            --
            , dark__bg_darkness_above
            ]
            appHeader
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

            --
            , dark__bg_darkness_above
            ]
            appFooter
        ]
    ]


appHeader : List (Html msg)
appHeader =
    [ header
        [ container
        , px_5
        , mx_auto
        ]
        [ div
            [ h_20
            , flex
            , flex_row
            , items_center
            ]
            [ View.Common.logo
                { attributes = []
                , fissionAttributes = [ h_8 ]
                }

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

                --
                , dark__text_gray_400
                ]
                [ text "Fission Internet Software" ]
            , div
                [ flex_grow
                , flex
                , flex_col
                , items_start
                , space_y_2

                --
                , md__flex_row
                , md__space_y_0
                , md__space_x_8
                , md__flex_grow_0
                ]
                [ footerLink [] { text = "Discord", url = "https://discord.gg/daDMAjE" }
                , footerLink [] { text = "Forum", url = "https://talk.fission.codes/" }
                ]

            -- TODO
            -- , div
            --     [ flex_grow
            --     , flex
            --     , flex_col
            --     , items_start
            --     , space_y_2
            --     --
            --     , md__flex_row
            --     , md__space_y_0
            --     , md__space_x_8
            --     , md__flex_grow_0
            --     ]
            --     [ footerLink [] { text = "Terms of Service", url = "#" }
            --     , footerLink [] { text = "Privacy Policy", url = "#" }
            --     ]
            ]
        ]
    ]


footerLink : List (Attribute msg) -> { text : String, url : String } -> Html msg
footerLink attributes element =
    a
        (List.append attributes
            [ text_gray_200
            , underline
            , rounded
            , fission_focus_ring

            --
            , dark__text_gray_400

            --
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
    span
        [ font_display
        , text_gray_200

        --
        , dark__text_gray_400
        ]
        content


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

              --
              , dark__text_gray_500
              ]
            , Common.when (not element.inErrorState)
                [ focus__border_purple
                , dark__focus__border_darkmode_purple
                ]
            , Common.when element.inErrorState
                [ border_red
                , dark__border_darkmode_red
                ]
            ]
        )
        []


infoTextAttributes : List (Attribute msg)
infoTextAttributes =
    [ text_sm
    , text_gray_200

    --
    , dark__text_gray_400
    ]


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


sectionEmail :
    { verificationStatus : List (Html msg)
    }
    -> Html msg
sectionEmail element =
    settingSection
        [ sectionTitle [] "Email"
        , sectionParagraph
            [ responsiveGroup
                [ span
                    (md__w_1over3 :: infoTextAttributes)
                    [ text "Did something go wrong while sending you a verification email on signup?"
                    , br [] []
                    , text "Click this button to request another one:"
                    ]
                , span
                    [ flex
                    , flex_row
                    , items_center
                    , space_x_2
                    ]
                    element.verificationStatus
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
        (List.append
            [ flex
            , flex_row
            , items_center
            , space_x_2
            ]
            (case status of
                Verified ->
                    [ text_purple
                    , dark__text_darkmode_purple
                    ]

                NotVerified ->
                    [ text_red
                    , dark__text_darkmode_red
                    ]
            )
        )
        [ (case status of
            Verified ->
                FeatherIcons.check

            NotVerified ->
                FeatherIcons.alertTriangle
          )
            |> FeatherIcons.withSize 20
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

        --
        , dark__text_darkmode_red
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
        (List.append attributes
            [ text_gray_300
            , font_body
            , text_lg
            , ml_5

            --
            , dark__text_gray_600
            ]
        )
        [ text title ]


spacer : Html msg
spacer =
    hr
        [ h_px
        , bg_purple_tint
        , border_0
        , mx_5

        --
        , dark__bg_gray_100
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
    , rounded
    , fission_focus_ring
    , flex
    , flex_row
    , items_center

    --
    , active__bg_purple_tint
    , active__bg_opacity_30
    , disabled__text_gray_300
    , disabled__bg_opacity_30
    , disabled__bg_gray_500

    --
    , dark__text_darkmode_purple
    , dark__disabled__text_gray_500
    ]


menuButton : List (Attribute msg) -> Html msg
menuButton attributes =
    button
        (List.append attributes
            [ ml_auto
            , text_gray_300
            , rounded
            , fission_focus_ring

            --
            , dark__text_gray_400
            ]
        )
        [ FeatherIcons.menu
            |> FeatherIcons.withSize 32
            |> FeatherIcons.toHtml []
        ]


workInProgressBanner : Html msg
workInProgressBanner =
    let
        infoIcon =
            FeatherIcons.info
                |> FeatherIcons.withSize 24
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> span
                    [ text_purple
                    , flex_shrink_0

                    --
                    , dark__text_gray_800
                    ]
    in
    div [ p_5 ]
        [ div
            [ p_3
            , rounded_lg
            , flex
            , flex_row
            , items_center
            , space_x_3
            , bg_purple_tint

            --
            , dark__bg_darkmode_purple
            , dark__text_gray_800
            ]
            [ infoIcon
            , span [ text_sm ]
                [ text "Looking empty? This dashboard app is work in progress! Are you interested in planned features or discussing them? Then please take a look at "
                , View.Common.underlinedLink
                    { location = "#" }
                    [ text "this forum post" ]
                , text "."
                ]
            ]
        ]
