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
        , productUpdates = False
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

        ProductUpdatesCheck checked ->
            ( { model | productUpdates = checked }
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
                List.intersperse View.spacer
                    [ View.sectionUsername
                        { username = viewUsername model
                        }
                    , View.sectionEmail
                        { email = viewEmail model
                        , productUpdates = model.productUpdates
                        , onCheckProductUpdates = ProductUpdatesCheck
                        }

                    -- , View.sectionManageAccount
                    ]
            , footer = View.appFooter
            }
    }


viewUsername : Model -> List (Html Msg)
viewUsername model =
    case model.username of
        SettingIs username ->
            [ View.settingViewing
                { value = username
                , onClickUpdate = Username SettingEdit
                }
            ]

        SettingEditing username ->
            List.concat
                [ [ View.settingEditing
                        { value = username
                        , onInput = Username << SettingUpdate
                        , onSave = Username SettingSave
                        }
                  ]
                , when (username == "matheus23")
                    [ View.warning [ Html.text "Sorry, this username was already taken." ] ]
                ]


viewEmail : Model -> List (Html Msg)
viewEmail model =
    case model.email of
        SettingIs email ->
            [ View.settingViewing
                { value = email
                , onClickUpdate = Email SettingEdit
                }
            ]

        SettingEditing email ->
            List.concat
                [ [ View.settingEditing
                        { value = email
                        , onInput = Email << SettingUpdate
                        , onSave = Email SettingSave
                        }
                  ]

                -- TODO improve email verification
                , when (not (String.contains "@" email))
                    [ View.warning
                        [ Html.text "This doesn’t seem to be an email address."
                        , Html.br [] []
                        , Html.text "Is there a typo?"
                        ]
                    ]
                , [ View.infoText
                        [ Html.text "You’ll have to verify your email address again, once changed." ]
                  ]
                ]


when : Bool -> List a -> List a
when predicate list =
    if predicate then
        list

    else
        []
