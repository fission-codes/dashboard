module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Dashboard
import Html.Styled as Html
import Json.Decode as Json
import Ports
import Radix exposing (..)
import Url exposing (Url)
import View.AuthFlow
import View.Common
import Webnative
import Webnative.Types
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


permissions : Webnative.Permissions
permissions =
    { app = Just appPermissions, fs = Nothing }


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
    , Cmd.none
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
                        Webnative.Types.NotAuthorised _ ->
                            ( { model | state = SigninScreen }
                            , Cmd.none
                            )

                        Webnative.Types.AuthCancelled _ ->
                            ( { model | state = SigninScreen }
                            , Cmd.none
                            )

                        Webnative.Types.AuthSucceeded { username } ->
                            ( { model | state = Authenticated (Dashboard.init username) }
                            , Cmd.none
                            )

                        Webnative.Types.Continuation { username } ->
                            ( { model | state = Authenticated (Dashboard.init username) }
                            , Cmd.none
                            )

                Err _ ->
                    ( model, Cmd.none )

        GotWebnativeResponse _ ->
            ( model, Cmd.none )

        GotWebnativeError error ->
            case error of
                "INSECURE_CONTEXT" ->
                    ( { model | state = ErrorScreen InsecureContext }
                    , Cmd.none
                    )

                "UNSUPPORTED_BROWSER" ->
                    ( { model | state = ErrorScreen UnsupportedBrowser }
                    , Cmd.none
                    )

                _ ->
                    ( { model | state = ErrorScreen (UnknownError error) }
                    , Cmd.none
                    )

        RedirectToLobby ->
            ( model
            , Webnative.redirectToLobby Webnative.CurrentUrl permissions
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
        [ Ports.webnativeResponse GotWebnativeResponse
        , Ports.webnativeInitialized (Json.decodeValue Webnative.Types.decoderState >> InitializedWebnative)
        , Ports.webnativeError GotWebnativeError
        , case model.state of
            Authenticated dashboard ->
                Dashboard.subscriptions dashboard

            _ ->
                Sub.none
        ]



-- 🌄


view : Model -> Browser.Document Msg
view model =
    case model.state of
        Authenticated dashboard ->
            Dashboard.view dashboard

        SigninScreen ->
            { title = "Fission Dashboard"
            , body =
                [ View.AuthFlow.signinScreen
                    { onSignIn = RedirectToLobby }
                    |> Html.toUnstyled
                ]
            }

        LoadingScreen ->
            { title = "Fission Dashboard"
            , body =
                [ View.AuthFlow.loadingScreen
                    { message = "Trying to authenticate..." }
                    |> Html.toUnstyled
                ]
            }

        ErrorScreen error ->
            { title = "Fission Dashboard"
            , body =
                [ View.AuthFlow.errorScreen
                    { message =
                        case error of
                            InsecureContext ->
                                [ Html.text "Something went wrong. "
                                , Html.br [] []
                                , Html.text "This webpage runs in a context not deemed secure enough by your browser to run cryptographic stuff. "
                                , Html.text "That means the website loaded with \"http\" instead of \"https\" or something similar. "
                                , Html.br [] []
                                , Html.text "If you don't know what's up, feel free to "
                                , View.Common.underlinedLink
                                    { location = "https://fission.codes/support" }
                                    [ Html.text "contact us" ]
                                , Html.text "."
                                ]

                            UnsupportedBrowser ->
                                [ Html.text "Something went wrong. "
                                , Html.br [] []
                                , Html.text "The browser you are using doesn't seem to support the Web APIs we need. "
                                , Html.text "Make sure your browser is up-to-date. "
                                , Html.br [] []
                                , Html.text "This can also happen when you're trying to use fission in private browsing windows. "
                                , Html.br [] []
                                , Html.text "If you've got any questions, please "
                                , View.Common.underlinedLink
                                    { location = "https://fission.codes/support" }
                                    [ Html.text "contact us" ]
                                , Html.text "."
                                ]

                            UnknownError errorCode ->
                                [ Html.text "Something went wrong."
                                , Html.br [] []
                                , Html.text "Unfortunately, we couldn't figure out what it was. "
                                , Html.text "The error code is \""
                                , Html.text errorCode
                                , Html.text "\"."
                                , Html.br [] []
                                , Html.text "Please contact "
                                , View.Common.underlinedLink
                                    { location = "https://fission.codes/support" }
                                    [ Html.text "our support" ]
                                , Html.text " and tell us about this issue."
                                ]
                    }
                    |> Html.toUnstyled
                ]
            }
