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
        { username = SettingIs "matheus23"
        , email = SettingIs "my-email@me.com"
        }
        Cmd.none



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Username settingMsg ->
            ( { model
                | username =
                    updateSetting
                        settingMsg
                        model.username
              }
            , Cmd.none
            )

        Email settingMsg ->
            ( { model
                | email =
                    updateSetting
                        settingMsg
                        model.email
              }
            , Cmd.none
            )

        _ ->
            ( model
            , Cmd.none
            )


updateSetting : SettingMsg -> SettingModel -> SettingModel
updateSetting msg model =
    case ( model, msg ) of
        ( SettingIs value, SettingEdit ) ->
            SettingEditing value

        ( SettingEditing value, SettingSave ) ->
            SettingIs value

        ( SettingEditing _, SettingUpdate value ) ->
            SettingEditing value

        _ ->
            model



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
                [ View.sectionUsername
                    { username =
                        case model.username of
                            SettingIs username ->
                                [ View.usernameSettingViewing
                                    { username = username
                                    , onClickUpdate = Username SettingEdit
                                    }
                                ]

                            SettingEditing username ->
                                List.concat
                                    [ [ View.usernameSettingEditing
                                            { username = username
                                            , onInput = Username << SettingUpdate
                                            , onClickSave = Username SettingSave
                                            }
                                      ]
                                    , when (username == "matheus23")
                                        [ View.warning [ Html.text "Sorry, this username was already taken." ] ]
                                    ]
                    }
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
