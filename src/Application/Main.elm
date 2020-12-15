module Main exposing (main)

import Browser
import Browser.Navigation
import Css.Classes as C
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as Events
import Radix exposing (..)
import Url exposing (Url)
import View



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
        { username = UsernameIs "matheus23" }
        Cmd.none



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UsernameEdit ->
            case model.username of
                UsernameIs username ->
                    ( { model | username = UsernameEditing username }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        UsernameSave ->
            case model.username of
                UsernameEditing username ->
                    ( { model | username = UsernameIs username }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        UsernameUpdate text ->
            case model.username of
                UsernameEditing username ->
                    ( { model | username = UsernameEditing text }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        _ ->
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
        View.appShell
            { header = View.appHeader
            , main =
                [ View.settingSection
                    [ View.sectionTitle [] "Username"
                    , View.sectionParagraph
                        (View.infoText
                            [ Html.text "Your username is unique among all fission users." ]
                            :: (case model.username of
                                    UsernameIs username ->
                                        [ View.editableInput
                                            { content = View.settingText [ Html.text username ]
                                            , button =
                                                View.uppercaseButton
                                                    [ Events.onClick UsernameEdit
                                                    ]
                                                    "Update"
                                            }
                                        ]

                                    UsernameEditing username ->
                                        List.concat
                                            [ [ View.editableInput
                                                    { content =
                                                        View.settingInput
                                                            { value = username
                                                            , placeholder = "my_account_name"
                                                            , onInput = UsernameUpdate
                                                            }
                                                    , button =
                                                        View.uppercaseButton
                                                            [ Events.onClick UsernameSave
                                                            ]
                                                            "Save"
                                                    }
                                              ]
                                            , when (username == "matheus23")
                                                [ View.warning [ Html.text "Sorry, this username was already taken." ] ]
                                            ]
                               )
                        )
                    ]
                , View.spacer
                , View.sectionEmail
                , View.spacer
                , View.sectionManageAccount
                ]
            , footer = View.appFooter
            }
    }


when : Bool -> List a -> List a
when predicate list =
    if predicate then
        list

    else
        []
