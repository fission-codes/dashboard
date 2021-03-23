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
init _ url navKey =
    ( { navKey = navKey
      , url = url
      , state = LoadingScreen
      }
    , Cmd.none
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
                        onAuthenticated username =
                            Authenticated.init model.url username
                                |> Tuple.mapFirst
                                    (\state -> { model | state = Authenticated state })
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

                        Webnative.Types.AuthSucceeded { username } ->
                            onAuthenticated username

                        Webnative.Types.Continuation { username } ->
                            onAuthenticated username

                Err error ->
                    ( model
                    , Ports.log
                        [ E.string "Error trying to parse the returned state from webnative.initialise:"
                        , E.string (Json.errorToString error)
                        ]
                    )

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
            , Ports.webnativeRedirectToLobby ()
            )

        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged url ->
            onUrlChange url model

        UrlRequested request ->
            case request of
                Browser.Internal url ->
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
        -- Message/Model desync
        -----------------------------------------
        AuthenticatedMsg _ ->
            ( model, Cmd.none )


onUrlChange : Url -> Model -> ( Model, Cmd Msg )
onUrlChange url model =
    let
        ( newState, commands ) =
            case model.state of
                Authenticated authenticatedModel ->
                    case Route.fromUrl url of
                        Just route ->
                            Authenticated.onRouteChange route authenticatedModel
                                |> Tuple.mapFirst Authenticated

                        _ ->
                            ( model.state, Cmd.none )

                _ ->
                    ( model.state, Cmd.none )
    in
    ( { model
        | url = url
        , state = newState
      }
    , commands
    )



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.webnativeResponse GotWebnativeResponse
        , Ports.webnativeInitialized (Json.decodeValue Webnative.Types.decoderState >> InitializedWebnative)
        , Ports.webnativeError GotWebnativeError
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
                                , View.Common.underlinedLink []
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
                                , View.Common.underlinedLink []
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
                                , View.Common.underlinedLink []
                                    { location = "https://fission.codes/support" }
                                    [ Html.text "our support" ]
                                , Html.text " and tell us about this issue."
                                ]
                    }
                    |> Html.toUnstyled
                ]
            }
