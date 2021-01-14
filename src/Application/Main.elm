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
import View.AuthFlow
import View.Dashboard
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
    Wnfs.AppData appPermissions


appPermissions : Webnative.AppPermissions
appPermissions =
    { creator = "Fission"
    , name = "Dashboard"
    }



-- 🌳


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init _ _ navKey =
    ( { navKey = navKey
      , state = LoadingScreen
      }
    , -- Workaround for the port not existing in compiled output
      case Err "" of
        Err _ ->
            Cmd.none

        Ok n ->
            Ports.wnfsRequest (never n)
    )


initDashboard : String -> DashboardModel
initDashboard username =
    { username = SettingIs username
    , email = SettingIs "my-email@me.com"
    , productUpdates = False
    , emailVerified = False
    }



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.state, msg ) of
        ( Authenticated dashboardModel, DashboardMsg dashboardMsg ) ->
            let
                ( newModel, cmds ) =
                    updateDashboard dashboardMsg dashboardModel
            in
            ( { model | state = Authenticated newModel }
            , cmds
            )

        _ ->
            updateOther msg model


updateOther : Msg -> Model -> ( Model, Cmd Msg )
updateOther msg model =
    case msg of
        -----------------------------------------
        -- Webnative
        -----------------------------------------
        InitializedWebnative result ->
            case result of
                Ok webnativeState ->
                    case webnativeState of
                        Webnative.NotAuthorised _ ->
                            ( { model | state = SigninScreen }
                            , Cmd.none
                            )

                        Webnative.AuthCancelled _ ->
                            ( { model | state = SigninScreen }
                            , Cmd.none
                            )

                        Webnative.AuthSucceeded { username } ->
                            ( { model | state = Authenticated (initDashboard username) }
                            , Cmd.none
                            )

                        Webnative.Continuation { username } ->
                            ( { model | state = Authenticated (initDashboard username) }
                            , Cmd.none
                            )

                Err _ ->
                    ( model, Cmd.none )

        GotWnfsResponse response ->
            case Wnfs.decodeResponse (\_ -> Err "No tags to parse") response of
                Ok ( n, _ ) ->
                    never n

                _ ->
                    -- TODO: Error handling
                    ( model, Cmd.none )

        RedirectToLobby ->
            ( model
            , Webnative.redirectToLobby Webnative.CurrentUrl
                (Just
                    { app = Nothing
                    , fs = Nothing
                    }
                )
                |> Ports.webnativeRequest
            )

        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged _ ->
            ( model, Cmd.none )

        UrlRequested _ ->
            ( model, Cmd.none )

        -----------------------------------------
        -- Message/Model desync
        -----------------------------------------
        DashboardMsg _ ->
            ( model, Cmd.none )


updateDashboard : DashboardMsg -> DashboardModel -> ( DashboardModel, Cmd Msg )
updateDashboard msg model =
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
        case model.state of
            Authenticated dashboard ->
                View.Dashboard.appShell
                    { header = View.Dashboard.appHeader
                    , main =
                        List.intersperse View.Dashboard.spacer
                            [ View.Dashboard.dashboardHeading "Your Account"
                            , View.Dashboard.sectionUsername
                                { username = viewUsername dashboard
                                }
                            , View.Dashboard.sectionEmail
                                { email = viewEmail dashboard
                                , productUpdates = dashboard.productUpdates
                                , onCheckProductUpdates = ProductUpdatesCheck >> DashboardMsg
                                , verificationStatus = viewVerificationStatus dashboard
                                }
                            , View.Dashboard.sectionManageAccount
                            ]
                    , footer = View.Dashboard.appFooter
                    }

            SigninScreen ->
                [ View.AuthFlow.signinScreen
                    { onSignIn = RedirectToLobby }
                ]

            LoadingScreen ->
                [ View.AuthFlow.loadingScreen
                    { message = "Trying to authorize..." }
                ]
    }


viewUsername : DashboardModel -> List (Html Msg)
viewUsername model =
    case model.username of
        SettingIs username ->
            [ View.Dashboard.settingViewing
                { value = username
                , onClickUpdate = DashboardMsg (Username SettingEdit)
                }
            ]

        SettingEditing username ->
            List.concat
                [ [ View.Dashboard.settingEditing
                        { value = username
                        , onInput = DashboardMsg << Username << SettingUpdate
                        , placeholder = "Your account name"
                        , inErrorState = username == "matheus23"
                        , onSave = DashboardMsg (Username SettingSave)
                        }
                  ]
                , Common.when (username == "matheus23")
                    [ View.Dashboard.warning [ Html.text "Sorry, this username was already taken." ] ]
                ]


viewEmail : DashboardModel -> List (Html Msg)
viewEmail model =
    case model.email of
        SettingIs email ->
            [ View.Dashboard.settingViewing
                { value = email
                , onClickUpdate = DashboardMsg (Email SettingEdit)
                }
            ]

        SettingEditing email ->
            List.concat
                [ [ View.Dashboard.settingEditing
                        { value = email
                        , onInput = DashboardMsg << Email << SettingUpdate
                        , placeholder = "my-email@example.com"
                        , inErrorState = not (String.contains "@" email)
                        , onSave = DashboardMsg (Email SettingSave)
                        }
                  ]

                -- TODO improve email verification
                , Common.when (not (String.contains "@" email))
                    [ View.Dashboard.warning
                        [ Html.text "This doesn’t seem to be an email address."
                        , Html.br [] []
                        , Html.text "Is there a typo?"
                        ]
                    ]
                , [ Html.span View.Dashboard.infoTextAttributes
                        [ Html.text "You’ll have to verify your email address again, once changed." ]
                  ]
                ]


viewVerificationStatus : DashboardModel -> List (Html Msg)
viewVerificationStatus model =
    if model.emailVerified then
        [ View.Dashboard.verificationStatus View.Dashboard.Verified ]

    else
        [ View.Dashboard.verificationStatus View.Dashboard.NotVerified
        , Html.button
            (Events.onClick (DashboardMsg EmailResendVerification)
                :: View.Dashboard.uppercaseButtonAttributes
            )
            [ Html.text "Resend Verification Email" ]
        ]
