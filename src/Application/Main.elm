module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Dashboard
import Json.Decode as Json
import Ports
import Radix exposing (..)
import Url exposing (Url)
import View.AuthFlow
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


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
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



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.state, msg ) of
        ( Authenticated dashboardModel, DashboardMsg dashboardMsg ) ->
            let
                ( newModel, cmds ) =
                    Dashboard.update dashboardMsg dashboardModel
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
                            ( { model | state = Authenticated (Dashboard.init username) }
                            , Cmd.none
                            )

                        Webnative.Continuation { username } ->
                            ( { model | state = Authenticated (Dashboard.init username) }
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

        UrlRequested request ->
            ( model
            , case request of
                Browser.Internal _ ->
                    Cmd.none

                Browser.External url ->
                    Navigation.load url
            )

        -----------------------------------------
        -- Message/Model desync
        -----------------------------------------
        DashboardMsg _ ->
            ( model, Cmd.none )



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.wnfsResponse GotWnfsResponse
        , Ports.webnativeInitialized (Json.decodeValue Webnative.decoderState >> InitializedWebnative)
        , case model.state of
            Authenticated dashboard ->
                Dashboard.subscriptions dashboard

            _ ->
                Sub.none
        ]



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        case model.state of
            Authenticated dashboard ->
                Dashboard.view dashboard

            SigninScreen ->
                [ View.AuthFlow.signinScreen
                    { onSignIn = RedirectToLobby }
                ]

            LoadingScreen ->
                [ View.AuthFlow.loadingScreen
                    { message = "Trying to authenticate..." }
                ]
    }
