module Main exposing (main)

import Browser
import Browser.Navigation
import Css.Classes as C
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Radix exposing (..)
import Url exposing (Url)



-- ⛩


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }



-- 🌳


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init _ _ _ =
    Tuple.pair
        {}
        Cmd.none



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model
    , Cmd.none
    )



-- 📰


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        appShell
            { header =
                [ Html.header
                    [ C.container
                    , C.px_5
                    , C.mx_auto
                    ]
                    [ Html.div
                        [ C.border_b
                        , C.border_gray_500
                        , C.h_20
                        , C.flex
                        , C.flex_row
                        , C.items_center
                        ]
                        [ logo []
                        , menuButton []
                        ]
                    ]
                ]
            , main =
                [ section
                    [ sectionTitle [] "Username"
                    , sectionParagraph
                        [ Html.span
                            [ C.ml_5
                            , C.text_sm
                            , C.text_gray_200
                            ]
                            [ Html.text "Your username is unique among all fission users." ]
                        , Html.span
                            [ C.ml_5
                            , C.flex
                            , C.flex_row
                            , C.items_center
                            , C.space_x_2
                            ]
                            [ Html.span
                                [ C.font_display
                                , C.text_gray_200
                                ]
                                [ Html.text "matheus23" ]
                            , uppercaseButton [] "Update"
                            ]
                        ]
                    ]
                , spacer
                , section
                    [ sectionTitle [] "Email"
                    , sectionParagraph
                        [ Html.div
                            [ C.ml_5
                            , C.flex
                            , C.flex_col
                            , C.space_y_2
                            ]
                            [ Html.span
                                [ C.flex
                                , C.flex_row
                                , C.items_center
                                , C.space_x_2
                                ]
                                [ Html.span
                                    [ C.font_display
                                    , C.text_gray_200
                                    ]
                                    [ Html.text "my-email@me.com" ]
                                , uppercaseButton [] "Update"
                                ]
                            , Html.span
                                [ C.flex
                                , C.flex_row
                                , C.items_center
                                , C.space_x_2
                                ]
                                [ verificationStatus NotVerified
                                , uppercaseButton [] "Resend Verification Email"
                                ]
                            ]
                        , Html.div
                            [ C.ml_5
                            , C.flex
                            , C.flex_col
                            , C.space_y_2
                            ]
                            [ Html.label
                                [ C.flex
                                , C.flex_row
                                , C.space_x_2
                                ]
                                [ Html.input
                                    [ A.type_ "checkbox"
                                    , A.checked True
                                    ]
                                    []
                                , Html.span
                                    [ C.font_display
                                    , C.text_gray_200
                                    , C.select_none
                                    ]
                                    [ Html.text "Product Updates" ]
                                ]
                            , Html.span
                                [ C.text_sm
                                , C.text_gray_200
                                ]
                                [ Html.text "Check to recieve pretty fun emails" ]
                            ]
                        ]
                    ]
                , spacer
                ]
            , footer =
                [ Html.footer
                    [ C.mx_auto
                    , C.container
                    , C.px_6
                    ]
                    [ Html.div
                        [ C.flex
                        , C.flex_row
                        , C.border_t
                        , C.border_gray_500
                        , C.py_6
                        , C.space_x_8
                        , C.items_center
                        ]
                        [ Html.img
                            [ A.src "images/badge-solid-faded.svg"
                            , C.h_8
                            ]
                            []
                        , Html.div
                            [ C.flex_grow
                            , C.flex
                            , C.flex_col
                            , C.items_start
                            , C.text_gray_200
                            , C.underline
                            , C.space_y_2
                            ]
                            [ Html.a [] [ Html.text "Discord" ]
                            , Html.a [] [ Html.text "Forum" ]
                            ]
                        , Html.div
                            [ C.flex_grow
                            , C.flex
                            , C.flex_col
                            , C.items_start
                            , C.text_gray_200
                            , C.underline
                            , C.space_y_2
                            ]
                            [ Html.a [] [ Html.text "Terms of Service" ]
                            , Html.a [] [ Html.text "Privacy Policy" ]
                            ]
                        ]
                    ]
                ]
            }
    }


appShell :
    { header : List (Html msg)
    , main : List (Html msg)
    , footer : List (Html msg)
    }
    -> List (Html msg)
appShell content =
    [ Html.div
        [ C.flex
        , C.bg_gray_600
        , C.sticky
        , C.inset_x_0
        , C.top_0
        ]
        content.header
    , Html.main_
        [ C.mx_auto
        , C.container
        , C.flex
        , C.flex_col
        , C.flex_grow
        ]
        content.main
    , Html.footer
        [ C.flex
        , C.bg_gray_600
        ]
        content.footer
    ]


type VerificationStatus
    = NotVerified
    | Verified


verificationStatus : VerificationStatus -> Html msg
verificationStatus status =
    Html.span
        [ case status of
            Verified ->
                C.text_purple

            NotVerified ->
                C.text_red
        , C.flex
        , C.flex_row
        , C.items_center
        , C.space_x_2
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
            |> Html.span []
        , Html.span [ C.font_display ]
            [ case status of
                Verified ->
                    Html.text "Verified"

                NotVerified ->
                    Html.text "Not Verified"
            ]
        ]


section : List (Html msg) -> Html msg
section content =
    Html.section [ C.my_8 ]
        content


sectionParagraph : List (Html msg) -> Html msg
sectionParagraph content =
    Html.p
        [ C.ml_5
        , C.mt_5
        , C.flex
        , C.flex_col
        , C.space_y_5
        ]
        content


sectionTitle : List (Html.Attribute msg) -> String -> Html msg
sectionTitle attributes title =
    Html.h2
        [ C.text_gray_300
        , C.font_body
        , C.text_lg
        , C.ml_5
        ]
        [ Html.text title ]


spacer : Html msg
spacer =
    Html.hr
        [ C.h_px
        , C.bg_purple_tint
        , C.border_0
        , C.mx_5
        ]
        []


uppercaseButton : List (Html.Attribute msg) -> String -> Html msg
uppercaseButton attributes buttonText =
    Html.button
        [ C.uppercase
        , C.text_purple
        , C.font_display
        , C.text_xs
        , C.tracking_widest
        , C.p_2
        ]
        [ Html.text buttonText ]


logo : List (Html.Attribute msg) -> Html msg
logo attributes =
    Html.span
        (List.append attributes
            [ C.flex
            , C.flex_row
            , C.items_start
            , C.space_x_2
            ]
        )
        [ Html.img
            [ A.src "images/logo-dark-textonly.svg"
            , C.h_8
            ]
            []
        , Html.span
            [ C.bg_purple
            , C.uppercase
            , C.text_white
            , C.font_display
            , C.tracking_widest
            , C.rounded
            , C.p_1
            , C.text_xs
            ]
            [ Html.text "Dashboard" ]
        ]


menuButton : List (Html.Attribute msg) -> Html msg
menuButton attributes =
    Html.button
        (List.append attributes
            [ C.ml_auto
            , C.text_gray_300
            ]
        )
        [ FeatherIcons.menu
            |> FeatherIcons.withSize 32
            |> FeatherIcons.toHtml []
        ]
