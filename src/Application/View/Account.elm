module View.Account exposing (..)

import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, classList, css, placeholder, type_, value)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, infoTextStyle)
import View.Dashboard


settingText : List (Html msg) -> Html msg
settingText content =
    span
        [ css
            [ dark [ text_gray_400 ]
            , font_display
            , text_gray_200
            ]
        ]
        content


sectionUsername : { username : List (Html msg) } -> Html msg
sectionUsername element =
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ text "Username" ]
        , View.Dashboard.sectionParagraph []
            [ responsiveGroup
                [ span
                    [ css
                        [ md [ w_1over2 ]
                        , infoTextStyle
                        ]
                    ]
                    [ text "Your username is unique among all fission users." ]
                , div
                    [ css
                        [ flex
                        , flex_col
                        , space_y_5
                        ]
                    ]
                    element.username
                ]
            ]
        ]


sectionEmail :
    { verificationStatus : List (Html msg)
    }
    -> Html msg
sectionEmail element =
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ text "Email" ]
        , View.Dashboard.sectionParagraph []
            [ responsiveGroup
                [ span
                    [ css
                        [ md [ w_1over2 ]
                        , infoTextStyle
                        ]
                    ]
                    [ text "Did something go wrong while sending you a verification email on signup?"
                    , br [] []
                    , text "Click this button to request another one:"
                    ]
                , span
                    [ css
                        [ flex
                        , flex_row
                        , items_center
                        , space_x_2
                        ]
                    ]
                    element.verificationStatus
                ]
            ]
        ]


responsiveGroup : List (Html msg) -> Html msg
responsiveGroup content =
    div
        [ css
            [ md
                [ flex_row
                , space_y_0
                , space_x_5
                ]
            , flex
            , flex_col
            , space_y_2
            ]
        ]
        content


groupHeading : List (Html msg) -> Html msg
groupHeading content =
    span
        [ css
            [ md
                [ inline
                , w_1over2
                ]
            , hidden
            , infoTextStyle
            ]
        ]
        content


type VerificationStatus
    = NotVerified
    | Verified


verificationStatus : VerificationStatus -> Html msg
verificationStatus status =
    span
        [ css
            [ flex
            , flex_row
            , items_center
            , space_x_2
            , Css.Global.withClass "verified"
                [ dark [ text_darkmode_purple ]
                , text_purple
                ]
            , Css.Global.withClass "not-verified"
                [ dark [ text_darkmode_red ]
                , text_red
                ]
            ]
        , case status of
            Verified ->
                class "verified"

            NotVerified ->
                class "not-verified"
        ]
        [ (case status of
            Verified ->
                FeatherIcons.check

            NotVerified ->
                FeatherIcons.alertTriangle
          )
            |> FeatherIcons.withSize 20
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span []
        , span [ css [ font_display ] ]
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
        [ css
            [ dark [ text_darkmode_red ]
            , flex
            , flex_row
            , items_center
            , space_x_2
            , text_red
            , text_sm
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


workInProgressBanner : Html msg
workInProgressBanner =
    let
        infoIcon =
            FeatherIcons.info
                |> FeatherIcons.withSize 24
                |> FeatherIcons.toHtml []
                |> fromUnstyled
                |> List.singleton
                |> span
                    [ css
                        [ dark [ text_gray_800 ]
                        , flex_shrink_0
                        , text_purple
                        ]
                    ]
    in
    div [ css [ p_5 ] ]
        [ div
            [ css
                [ dark
                    [ bg_darkmode_purple
                    , text_gray_800
                    ]
                , bg_purple_tint
                , flex
                , flex_row
                , items_center
                , p_3
                , rounded_lg
                , space_x_3
                ]
            ]
            [ infoIcon
            , span [ css [ text_sm ] ]
                [ text "Looking empty? This dashboard app is work in progress! Are you interested in planned features or discussing them? Then please take a look at "
                , View.Common.underlinedLink []
                    { location = "https://talk.fission.codes/t/plans-for-the-account-dashboard/1586" }
                    [ Html.Styled.text "this forum post" ]
                , text "."
                ]
            ]
        ]
