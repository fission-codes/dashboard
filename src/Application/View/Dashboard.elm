module View.Dashboard exposing (..)

import Common
import Css
import Css.Global
import FeatherIcons
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (checked, class, classList, css, disabled, href, name, placeholder, src, type_, value)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)
import View.Common exposing (dark, fissionFocusRing)


appShell :
    { navigation :
        { items : List (Html msg)
        , expanded : Bool
        , onToggleExpanded : msg
        }
    , main : List (Html msg)
    }
    -> Html msg
appShell element =
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
                    , border_gray_500
                    , left_0
                    , inset_y_0
                    , w_80
                    ]
                , dark [ bg_darkness_above ]
                , bg_gray_600
                , flex
                , flex_col
                , flex_shrink_0
                , inset_x_0
                , sticky
                , top_0
                ]
            ]
            [ appHeader
                { menuExpanded = element.navigation.expanded
                , onToggle = element.navigation.onToggleExpanded
                }
            , nav
                [ classList
                    [ ( "expanded", element.navigation.expanded ) ]
                , css
                    [ lg [ flex ]
                    , Css.Global.withClass "expanded"
                        [ flex ]
                    , flex_col
                    , hidden
                    ]
                ]
                element.navigation.items
            , footer
                [ css
                    [ lg [ flex ]
                    , hidden
                    , px_6
                    , mt_auto
                    ]
                ]
                appFooter
            ]
        , main_
            [ css
                [ container
                , flex
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
            appFooter
        ]


navigationHeader : String -> Html msg
navigationHeader label =
    h4
        [ css
            [ dark [ text_gray_400 ]
            , pt_4
            , px_3
            , pb_2
            , font_display
            , text_xs
            , tracking_wider
            , uppercase
            , text_gray_300
            ]
        ]
        [ text label ]


navigationItem : List Css.Style -> { active : Bool, icon : FeatherIcons.Icon, label : String } -> Html msg
navigationItem styles { active, icon, label } =
    button
        [ classList
            [ ( "active", active ) ]
        , css
            [ Css.batch styles
            , Css.Global.withClass "active"
                [ dark
                    [ bg_gray_200
                    , border_darkmode_purple
                    ]
                , bg_purple_tint
                , border_purple
                ]
            , lg
                [ h_10 ]
            , bg_transparent
            , border_l_2
            , border_transparent
            , fissionFocusRing
            , flex
            , flex_grow
            , flex_row
            , h_14
            , items_center
            ]
        ]
        [ icon
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span
                [ classList
                    [ ( "active", active ) ]
                , css
                    [ Css.Global.withClass "active"
                        [ dark [ text_gray_600 ]
                        , text_purple
                        ]
                    , dark [ text_gray_400 ]

                    --
                    , flex_shrink_0
                    , pl_5
                    , pr_3
                    , text_gray_300
                    ]
                ]
        , span
            [ classList
                [ ( "active", active ) ]
            , css
                [ Css.Global.withClass "active"
                    [ dark [ text_gray_800 ]
                    , text_purple
                    ]
                , dark [ text_gray_400 ]
                , flex_grow
                , text_left
                , font_body
                , py_2
                , text_base
                , text_gray_300
                ]
            ]
            [ text label ]
        , FeatherIcons.chevronRight
            |> FeatherIcons.withSize 16
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span
                [ classList
                    [ ( "active", active ) ]
                , css
                    [ Css.Global.withClass "active"
                        [ dark [ text_gray_600 ]
                        , block
                        , text_purple
                        ]
                    , flex_shrink_0
                    , hidden
                    , ml_auto
                    , pr_2
                    ]
                ]
        ]


appHeader : { menuExpanded : Bool, onToggle : msg } -> Html msg
appHeader element =
    header
        [ css
            [ container
            , mx_auto
            , px_5
            ]
        ]
        [ div
            [ css
                [ flex
                , flex_row
                , h_20
                , items_center
                ]
            ]
            [ View.Common.logo
                { styles = []
                , imageStyles = [ h_8 ]
                }
            , button
                [ Events.onClick element.onToggle
                , css
                    [ lg [ hidden ]
                    , dark [ text_gray_400 ]
                    , fissionFocusRing
                    , ml_auto
                    , rounded
                    , text_gray_300
                    ]
                ]
                [ (if element.menuExpanded then
                    FeatherIcons.x

                   else
                    FeatherIcons.menu
                  )
                    |> FeatherIcons.withSize 32
                    |> FeatherIcons.toHtml []
                    |> fromUnstyled
                ]
            ]
        ]


appFooter : List (Html msg)
appFooter =
    [ div
        [ css
            [ flex
            , flex_row
            , items_center
            , py_6
            , space_x_8
            ]
        ]
        [ img
            [ src "images/badge-solid-faded.svg"
            , css [ h_8 ]
            ]
            []
        , div
            [ css
                [ md
                    [ flex_row
                    , space_y_0
                    , space_x_8
                    , flex_grow_0
                    ]
                , flex
                , flex_col
                , flex_grow
                , items_start
                , space_y_2
                ]
            ]
            [ footerLink { styles = [], text = "Discord", url = "https://discord.gg/daDMAjE" }
            ]
        , div
            [ css
                [ md
                    [ flex_row
                    , space_y_0
                    , space_x_8
                    , flex_grow_0
                    ]
                , flex
                , flex_col
                , flex_grow
                , items_start
                , space_y_2
                ]
            ]
            [ footerLink { styles = [], text = "Forum", url = "https://talk.fission.codes/" }

            -- TODO Should we even have Terms of Service or Privacy Policy in the Dashboard at all?
            -- , footerLink [] { text = "Terms of Service", url = "#" }
            -- , footerLink [] { text = "Privacy Policy", url = "#" }
            ]
        ]
    ]


footerLink : { styles : List Css.Style, text : String, url : String } -> Html msg
footerLink element =
    a
        [ css
            [ Css.batch element.styles
            , dark [ text_gray_400 ]
            , fissionFocusRing
            , rounded
            , text_gray_200
            , underline
            ]
        , href element.url
        ]
        [ text element.text ]


dashboardHeading : String -> Html msg
dashboardHeading headingText =
    h1
        [ css
            [ md
                [ px_16
                , py_8
                , text_4xl
                ]
            , font_display
            , px_8
            , py_5
            , text_2xl
            ]
        ]
        [ text headingText ]


settingSection : List (Html msg) -> Html msg
settingSection content =
    section [ css [ my_8 ] ] content


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
              , css
                    [ dark [ text_gray_500 ]
                    , bg_gray_900
                    , border
                    , border_gray_500
                    , flex_grow
                    , flex_shrink
                    , font_display
                    , max_w_xs
                    , min_w_0
                    , placeholder_gray_400
                    , px_3
                    , py_1
                    , rounded
                    , text_base
                    , text_gray_200

                    --
                    , Css.Global.withClass "error"
                        [ dark [ border_darkmode_red ]
                        , border_red
                        ]
                    , Css.focus
                        [ dark [ border_darkmode_purple ]
                        , border_purple
                        ]
                    ]
              ]
            , Common.when element.inErrorState
                [ class "error" ]
            ]
        )
        []


infoTextStyle : Css.Style
infoTextStyle =
    Css.batch
        [ dark [ text_gray_400 ]
        , text_sm
        , text_gray_200
        ]


sectionUsername : { username : List (Html msg) } -> Html msg
sectionUsername element =
    settingSection
        [ sectionTitle [] "Username"
        , sectionParagraph
            [ responsiveGroup
                [ span
                    [ css
                        [ md [ w_1over3 ]
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
    settingSection
        [ sectionTitle [] "Email"
        , sectionParagraph
            [ responsiveGroup
                [ span
                    [ css
                        [ md [ w_1over3 ]
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
                , w_1over3
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


sectionParagraph : List (Html msg) -> Html msg
sectionParagraph content =
    p
        [ css
            [ flex
            , flex_col
            , mt_5
            , pl_10
            , pr_5
            , space_y_5
            ]
        ]
        content


sectionTitle : List Css.Style -> String -> Html msg
sectionTitle styles title =
    h2
        [ css
            [ Css.batch styles
            , dark [ text_gray_600 ]
            , font_body
            , ml_5
            , text_gray_300
            , text_lg
            ]
        ]
        [ text title ]


spacer : Html msg
spacer =
    hr
        [ css
            [ dark [ bg_gray_100 ]
            , bg_purple_tint
            , border_0
            , h_px
            , mx_5
            ]
        ]
        []


uppercaseButtonStyle : Css.Style
uppercaseButtonStyle =
    Css.batch
        [ dark [ text_darkmode_purple ]
        , fissionFocusRing
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

        --
        , Css.active
            [ bg_purple_tint
            , bg_opacity_30
            ]
        , Css.disabled
            [ dark [ text_gray_500 ]
            , text_gray_300
            , bg_opacity_30
            , bg_gray_500
            ]
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
                [ View.Common.loadingAnimation View.Common.Small [ css [ ml_3 ] ] ]
            ]
        )


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
                , View.Common.underlinedLink
                    { location = "https://talk.fission.codes/t/plans-for-the-account-dashboard/1586" }
                    [ Html.Styled.text "this forum post" ]
                , text "."
                ]
            ]
        ]
