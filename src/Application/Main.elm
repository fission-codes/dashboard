module Main exposing (main)

import Browser
import Browser.Navigation
import Common
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Json
import Ports
import Radix exposing (..)
import Url exposing (Url)
import View
import Webnative
import Webnative.Types as Webnative
import Wnfs



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


base : Wnfs.Base
base =
    Wnfs.AppData
        { creator = "Fission"
        , name = "Dashboard"
        }



-- 🌳


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init _ _ _ =
    Tuple.pair
        { username = SettingIs "matheus23"
        , email = SettingIs "my-email@me.com"
        , productUpdates = False
        , emailVerified = False
        }
        Cmd.none



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -----------------------------------------
        -- App
        -----------------------------------------
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

        EmailResendVerification ->
            ( { model | emailVerified = True }
            , Cmd.none
            )

        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged _ ->
            ( model, Cmd.none )

        UrlRequested _ ->
            ( model, Cmd.none )

        -----------------------------------------
        -- Webnative
        -----------------------------------------
        InitializedWebnative result ->
            case result of
                Ok webnativeState ->
                    case webnativeState of
                        _ ->
                            ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GotWnfsResponse response ->
            case Wnfs.decodeResponse (\_ -> Err "No tags to pars") response of
                Ok ( n, _ ) ->
                    never n

                _ ->
                    -- TODO: Error handling
                    ( model, Cmd.none )


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
    Sub.batch
        [ Ports.wnfsResponse GotWnfsResponse
        , Ports.webnativeInitialized (Json.decodeValue Webnative.decoderState >> InitializedWebnative)
        ]



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        View.appShell
            { header = View.appHeader
            , main =
                List.intersperse View.spacer
                    [ View.dashboardHeading "Your Account"
                    , View.sectionUsername
                        { username = viewUsername model
                        }
                    , View.sectionEmail
                        { email = viewEmail model
                        , productUpdates = model.productUpdates
                        , onCheckProductUpdates = ProductUpdatesCheck
                        , verificationStatus = viewVerificationStatus model
                        }
                    , View.sectionManageAccount
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
                        , placeholder = "Your account name"
                        , inErrorState = username == "matheus23"
                        , onSave = Username SettingSave
                        }
                  ]
                , Common.when (username == "matheus23")
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
                        , placeholder = "my-email@example.com"
                        , inErrorState = not (String.contains "@" email)
                        , onSave = Email SettingSave
                        }
                  ]

                -- TODO improve email verification
                , Common.when (not (String.contains "@" email))
                    [ View.warning
                        [ Html.text "This doesn’t seem to be an email address."
                        , Html.br [] []
                        , Html.text "Is there a typo?"
                        ]
                    ]
                , [ Html.span View.infoTextAttributes
                        [ Html.text "You’ll have to verify your email address again, once changed." ]
                  ]
                ]


viewVerificationStatus : Model -> List (Html Msg)
viewVerificationStatus model =
    if model.emailVerified then
        [ View.verificationStatus View.Verified ]

    else
        [ View.verificationStatus View.NotVerified
        , Html.button
            (Events.onClick EmailResendVerification
                :: View.uppercaseButtonAttributes
            )
            [ Html.text "Resend Verification Email" ]
        ]
