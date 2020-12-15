module View exposing (..)

import Css.Classes exposing (..)
import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (checked, height, href, placeholder, src, type_, value, width)
import Html.Events as Events


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
            [ logo []

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
            , div
                [ flex_grow
                , flex
                , flex_col
                , items_start
                , text_gray_200
                , underline
                , space_y_2
                ]
                [ a [] [ text "Discord" ]
                , a [] [ text "Forum" ]
                ]
            , div
                [ flex_grow
                , flex
                , flex_col
                , items_start
                , text_gray_200
                , underline
                , space_y_2
                ]
                [ a [] [ text "Terms of Service" ]
                , a [] [ text "Privacy Policy" ]
                ]
            ]
        ]
    ]


settingSection : List (Html msg) -> Html msg
settingSection content =
    section [ my_8 ] content


settingText : List (Html msg) -> Html msg
settingText content =
    span [ font_display, text_gray_200 ] content


settingInput : { value : String, placeholder : String, onInput : String -> msg } -> Html msg
settingInput element =
    input
        [ type_ "text"
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
        []


infoText : List (Html msg) -> Html msg
infoText content =
    span [ text_sm, text_gray_200 ] content


sectionUsername : { username : List (Html msg) } -> Html msg
sectionUsername element =
    settingSection
        [ sectionTitle [] "Username"
        , sectionParagraph
            (List.concat
                [ [ infoText
                        [ text "Your username is unique among all fission users." ]
                  ]
                , element.username
                ]
            )
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


settingEditing : { value : String, onInput : String -> msg, onSave : msg } -> Html msg
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
            , placeholder = "my_account_name"
            , onInput = element.onInput
            }
        , input
            (type_ "submit"
                :: value "Save"
                :: uppercaseButtonAttributes
            )
            []
        ]


sectionEmail : { email : List (Html msg), productUpdates : Bool, onCheckProductUpdates : Bool -> msg } -> Html msg
sectionEmail element =
    settingSection
        [ sectionTitle [] "Email"
        , sectionParagraph
            [ div
                [ flex
                , flex_col
                , space_y_2
                ]
                (List.concat
                    [ element.email
                    , [ span
                            [ flex
                            , flex_row
                            , items_center
                            , space_x_2
                            ]
                            [ verificationStatus NotVerified
                            , button uppercaseButtonAttributes
                                [ text "Resend Verification Email" ]
                            ]
                      ]
                    ]
                )
            , div
                [ flex
                , flex_col
                , space_y_2
                ]
                [ label
                    [ flex
                    , flex_row
                    , space_x_2
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
                , infoText
                    [ text "Check to recieve pretty fun emails" ]
                ]
            ]
        ]


sectionManageAccount : Html msg
sectionManageAccount =
    settingSection
        [ sectionTitle [] "Manage Account"
        , sectionParagraph
            [ span [ text_sm, text_gray_200 ]
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


logo : List (Attribute msg) -> Html msg
logo attributes =
    span
        (List.append attributes
            [ flex
            , flex_row
            , items_start
            , space_x_2
            ]
        )
        [ img
            [ src "images/logo-dark-textonly.svg"
            , h_8
            ]
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
