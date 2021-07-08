module Main exposing (main)

import Authenticated
import Browser
import Browser.Navigation as Navigation
import Html.Styled as Html
import Json.Decode as Json
import Json.Encode as E
import Ports
import Radix exposing (..)
import Route
import Url exposing (Url)
import View.AuthFlow
import View.Common
import Webnative.Types



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


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    case Json.decodeValue Webnative.Types.decoderPermissions flags.permissionsBaseline of
        Ok permissionsBaseline ->
            ( { navKey = navKey
              , url = url
              , permissionsBaseline = permissionsBaseline
              , state = LoadingScreen
              }
            , Cmd.none
            )

        Err error ->
            ( { navKey = navKey
              , url = url
              , permissionsBaseline =
                    { app = Nothing
                    , fs = Nothing
                    , platform = Nothing
                    }
              , state = ErrorScreen (UnknownError "Initialisation error. See the console for more details.")
              }
            , Ports.log [ E.string "Error decoding flags", E.string (Json.errorToString error) ]
            )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.state, msg ) of
        ( Authenticated authenticatedModel, AuthenticatedMsg authenticatedMsg ) ->
            let
                ( newModel, cmds ) =
                    Authenticated.update model.navKey authenticatedMsg authenticatedModel
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
                    let
                        onAuthenticated username maybePermissions =
                            case maybePermissions of
                                Just permissions ->
                                    Authenticated.init model.url
                                        { username = username
                                        , permissions = permissions
                                        }
                                        |> Tuple.mapFirst
                                            (\state -> { model | state = Authenticated state })

                                Nothing ->
                                    ( { model | state = SigninScreen }
                                    , Ports.log [ E.string "No permissions after webnative initialisation" ]
                                    )
                    in
                    case webnativeState of
                        Webnative.Types.NotAuthorised _ ->
                            ( { model | state = SigninScreen }
                            , Cmd.none
                            )

                        Webnative.Types.AuthCancelled _ ->
                            ( { model | state = SigninScreen }
                            , Cmd.none
                            )

                        Webnative.Types.AuthSucceeded { username, permissions } ->
                            onAuthenticated username permissions

                        Webnative.Types.Continuation { username, permissions } ->
                            onAuthenticated username permissions

                Err error ->
                    ( model
                    , Ports.log
                        [ E.string "Error trying to parse the returned state from webnative.initialise:"
                        , E.string (Json.errorToString error)
                        ]
                    )

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

        RedirectToLobby permissions ->
            ( model
            , Ports.redirectToLobby { permissions = permissions }
            )

        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged url ->
            onUrlChange url model

        UrlChangedFromOutside str ->
            case Url.fromString str of
                Just url ->
                    ( { model | url = url }
                    , Cmd.none
                    )

                Nothing ->
                    ( model
                    , Ports.log [ E.string "Couldn't parse url:", E.string str ]
                    )

        UrlRequested request ->
            case request of
                Browser.Internal url ->
                    if Route.isRecovery url then
                        ( model
                        , Navigation.load (Url.toString url)
                        )

                    else
                        onUrlChange url model
                            |> Tuple.mapSecond
                                (\commands ->
                                    Cmd.batch
                                        [ Navigation.pushUrl model.navKey (Url.toString url)
                                        , commands
                                        ]
                                )

                Browser.External url ->
                    ( model
                    , Navigation.load url
                    )

        -----------------------------------------
        -- Errors
        -----------------------------------------
        LogError messages ->
            ( model, Ports.log messages )

        -----------------------------------------
        -- Message/Model desync
        -----------------------------------------
        AuthenticatedMsg _ ->
            ( model, Cmd.none )


onUrlChange : Url -> Model -> ( Model, Cmd Msg )
onUrlChange url model =
    case model.state of
        Authenticated authenticatedModel ->
            case Route.fromUrl url of
                Just route ->
                    if Authenticated.isProcessingSomething authenticatedModel then
                        ( model, Cmd.none )

                    else
                        let
                            ( newState, commands ) =
                                Authenticated.onRouteChange route authenticatedModel
                        in
                        ( { model
                            | url = url
                            , state = Authenticated newState
                          }
                        , commands
                        )

                _ ->
                    ( { model | url = url }, Cmd.none )

        _ ->
            ( { model | url = url }, Cmd.none )



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.webnativeInitialized (Json.decodeValue Webnative.Types.decoderState >> InitializedWebnative)
        , Ports.webnativeError GotWebnativeError
        , Ports.urlChanged UrlChangedFromOutside
        , case model.state of
            Authenticated dashboard ->
                Authenticated.subscriptions dashboard

            _ ->
                Sub.none
        ]



-- 🌄


view : Model -> Browser.Document Msg
view model =
    case model.state of
        Authenticated dashboard ->
            Authenticated.view dashboard

        SigninScreen ->
            { title = "Fission Dashboard"
            , body =
                [ View.AuthFlow.signinScreen
                    -- We're not signed in, so we request the baseline of permissions
                    { onSignIn = RedirectToLobby model.permissionsBaseline }
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
                                , View.Common.underlinedLink []
                                    { location = "https://fission.codes/support"
                                    , external = False
                                    }
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
                                , View.Common.underlinedLink []
                                    { location = "https://fission.codes/support"
                                    , external = False
                                    }
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
                                , View.Common.underlinedLink []
                                    { location = "https://fission.codes/support"
                                    , external = False
                                    }
                                    [ Html.text "our support" ]
                                , Html.text " and tell us about this issue."
                                ]
                    }
                    |> Html.toUnstyled
                ]
            }
