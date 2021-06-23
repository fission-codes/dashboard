module Recovery.Main exposing (main, parseBackup)

import Browser
import Browser.Navigation as Navigation
import Dict
import File
import Html.Styled as Html exposing (Html)
import Http
import Json.Decode as Json
import Json.Encode as E
import Recovery.Api as Api
import Recovery.Ports as Ports
import Recovery.Radix exposing (..)
import Recovery.Route as Route
import RemoteData
import Task
import Url exposing (Url)
import View.Common
import View.Dashboard
import View.Recovery



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
    ( { navKey = navKey
      , endpoints = flags.endpoints
      , url = url
      , recoveryState =
            case Route.parseChallenge url of
                Just challenge ->
                    case flags.savedRecovery.username of
                        Just username ->
                            ScreenVerifiedEmail

                        Nothing ->
                            ScreenWrongBrowser

                Nothing ->
                    ScreenRecoverAccount
                        { backupUpload = RemoteData.NotAsked
                        , sentEmail = RemoteData.NotAsked
                        }
      }
    , Cmd.none
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecoverySelectedBackup files ->
            updateScreenRecoverAccount model
                (\state ->
                    case files of
                        [ file ] ->
                            ( { state | backupUpload = RemoteData.Loading }
                            , Task.perform RecoveryUploadedBackup (File.toString file)
                            )

                        _ ->
                            ( state
                            , Ports.log [ E.string "Unexpected amount of files uploaded. Expected 1 but got ", E.int (List.length files) ]
                            )
                )

        RecoveryUploadedBackup content ->
            case parseBackup content of
                Ok backup ->
                    ( model, Ports.verifyBackup backup )

                Err error ->
                    ( { model
                        | recoveryState =
                            ScreenRecoverAccount
                                { backupUpload = RemoteData.Failure error
                                , sentEmail = RemoteData.NotAsked
                                }
                      }
                    , Cmd.none
                    )

        RecoveryVerifyBackupFailed error ->
            ( { model
                | recoveryState =
                    ScreenRecoverAccount
                        { backupUpload = RemoteData.Failure error
                        , sentEmail = RemoteData.NotAsked
                        }
              }
            , Cmd.none
            )

        RecoveryVerifyBackupSucceeded backup ->
            ( { model
                | recoveryState =
                    ScreenRecoverAccount
                        { backupUpload = RemoteData.Success backup
                        , sentEmail = RemoteData.NotAsked
                        }
              }
            , Cmd.none
            )

        RecoveryClickedSendEmail ->
            updateScreenRecoverAccount model
                (\state ->
                    case state.backupUpload of
                        RemoteData.Success backup ->
                            ( { state | sentEmail = RemoteData.Loading }
                            , Api.sendRecoveryEmail
                                { endpoints = model.endpoints
                                , username = backup.username
                                , onResult = RecoveryEmailSent
                                }
                            )

                        _ ->
                            ( state, Cmd.none )
                )

        RecoveryEmailSent result ->
            updateScreenRecoverAccount model
                (\state ->
                    ( { state
                        | sentEmail = RemoteData.fromResult result
                      }
                    , case state.backupUpload of
                        RemoteData.Success backup ->
                            Cmd.batch
                                [ Ports.saveUsername backup.username
                                , Ports.saveBackup backup.key
                                ]

                        _ ->
                            Cmd.none
                    )
                )

        RegainClickedIHaveNoBackup ->
            ( { model
                | recoveryState =
                    ScreenRegainAccess
                        { username = ""
                        , usernameValidation = RemoteData.NotAsked
                        , sentEmail = RemoteData.NotAsked
                        }
              }
            , Cmd.none
            )

        RegainClickedGoBack ->
            ( { model
                | recoveryState =
                    ScreenRecoverAccount
                        { backupUpload = RemoteData.NotAsked
                        , sentEmail = RemoteData.NotAsked
                        }
              }
            , Cmd.none
            )

        RegainUsernameInput username ->
            updateScreenRegainAccess model
                (\state ->
                    ( { state
                        | username = username
                        , usernameValidation = RemoteData.Loading
                        , sentEmail = RemoteData.NotAsked
                      }
                    , if username |> String.trim |> String.isEmpty then
                        Cmd.none

                      else
                        Ports.usernameExists (String.trim username)
                    )
                )

        RegainUsernameExists { username, exists, valid } ->
            updateScreenRegainAccess model
                (\state ->
                    if state.username == username then
                        ( { state
                            | username = username
                            , usernameValidation =
                                if not valid then
                                    RemoteData.Failure UsernameInvalid

                                else if not exists then
                                    RemoteData.Failure UsernameNotFound

                                else
                                    RemoteData.Success username
                            , sentEmail =
                                -- If validation was kicked off before we knew about the username being valid,
                                -- and it turns out it wasn't, we'll reset the button to be clickable again.
                                if RemoteData.isLoading state.sentEmail && (not valid || not exists) then
                                    RemoteData.NotAsked

                                else
                                    state.sentEmail
                          }
                        , -- The validation might have been kicked off after the user pressed
                          -- "Send Email". If so, we have to do that once the username was
                          -- verified.
                          if RemoteData.isLoading state.sentEmail && valid && exists then
                            Api.sendRecoveryEmail
                                { endpoints = model.endpoints
                                , username = username
                                , onResult = RegainEmailSent
                                }

                          else
                            Cmd.none
                        )

                    else
                        ( state, Cmd.none )
                )

        RegainClickedSendEmail ->
            updateScreenRegainAccess model
                (\state ->
                    ( { state | sentEmail = RemoteData.Loading }
                    , -- We validate the username before we send an API request.
                      -- If it turns out we haven't done that yet, we do that and
                      -- will send an API request later once it's verified
                      case getValidUsername state of
                        Just username ->
                            Api.sendRecoveryEmail
                                { endpoints = model.endpoints
                                , username = username
                                , onResult = RegainEmailSent
                                }

                        Nothing ->
                            Ports.usernameExists state.username
                    )
                )

        RegainEmailSent result ->
            updateScreenRegainAccess model
                (\state ->
                    ( { state | sentEmail = RemoteData.fromResult result }
                    , Cmd.none
                    )
                )

        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

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
                    ( { model | url = url }
                    , Navigation.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Navigation.load url
                    )


updateScreenRecoverAccount : Model -> (StateRecoverAccount -> ( StateRecoverAccount, Cmd Msg )) -> ( Model, Cmd Msg )
updateScreenRecoverAccount model updateState =
    case model.recoveryState of
        ScreenRecoverAccount state ->
            let
                ( updatedState, cmds ) =
                    updateState state
            in
            ( { model | recoveryState = ScreenRecoverAccount updatedState }
            , cmds
            )

        _ ->
            ( model, Cmd.none )


updateScreenRegainAccess : Model -> (StateRegainAccess -> ( StateRegainAccess, Cmd Msg )) -> ( Model, Cmd Msg )
updateScreenRegainAccess model updateState =
    case model.recoveryState of
        ScreenRegainAccess state ->
            let
                ( updatedState, cmds ) =
                    updateState state
            in
            ( { model | recoveryState = ScreenRegainAccess updatedState }
            , cmds
            )

        _ ->
            ( model, Cmd.none )


getValidUsername : StateRegainAccess -> Maybe String
getValidUsername state =
    case state.usernameValidation of
        RemoteData.Success validUsername ->
            if validUsername == state.username then
                Just validUsername

            else
                Nothing

        _ ->
            Nothing



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.recoveryState of
        ScreenRecoverAccount _ ->
            Sub.batch
                [ Ports.verifyBackupFailed RecoveryVerifyBackupFailed
                , Ports.verifyBackupSucceeded RecoveryVerifyBackupSucceeded
                ]

        ScreenRegainAccess _ ->
            Ports.usernameExistsResponse RegainUsernameExists

        ScreenVerifiedEmail ->
            Sub.none

        ScreenWrongBrowser ->
            Sub.none



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Dashboard - Account Recovery"
    , body =
        [ View.Recovery.appShell
            (case model.recoveryState of
                ScreenRecoverAccount state ->
                    if
                        RemoteData.isSuccess state.backupUpload
                            && RemoteData.isSuccess state.sentEmail
                    then
                        viewScreenWaitingForEmail FlowRecoverAccount

                    else
                        viewScreenRecoverAccount state

                ScreenRegainAccess state ->
                    if RemoteData.isSuccess state.sentEmail then
                        viewScreenWaitingForEmail FlowRegainAccess

                    else
                        viewScreenRegainAccess state

                ScreenVerifiedEmail ->
                    viewScreenVerifiedEmail

                ScreenWrongBrowser ->
                    viewScreenWrongBrowser
            )
            |> Html.toUnstyled
        ]
    }


viewScreenRecoverAccount : StateRecoverAccount -> List (Html Msg)
viewScreenRecoverAccount state =
    let
        error =
            case state.backupUpload of
                RemoteData.Failure verifyError ->
                    [ View.Common.warning
                        [ Html.text verifyError.message
                        , Html.br [] []
                        , View.Recovery.contactSupportMessage verifyError.contactSupport
                        ]
                    ]

                _ ->
                    []

        uploadSection =
            case state.backupUpload of
                RemoteData.Success backup ->
                    List.append
                        [ View.Recovery.importedBackupCheckmark
                        , View.Recovery.welcomeBackMessage backup.username
                        , View.Recovery.buttonSendEmail
                            { isLoading = RemoteData.isLoading state.sentEmail
                            , disabled = RemoteData.isLoading state.sentEmail
                            , onClick = Just RecoveryClickedSendEmail
                            }
                        ]
                        (if RemoteData.isFailure state.sentEmail then
                            [ View.Common.warning
                                [ Html.text "Something went wrong when trying to send an email."
                                , Html.br [] []
                                , View.Recovery.contactSupportMessage True
                                ]
                            ]

                         else
                            []
                        )

                _ ->
                    List.concat
                        [ [ View.Recovery.backupUpload
                                { onUpload =
                                    Json.at [ "target", "files" ] (Json.list File.decoder)
                                        |> Json.map RecoverySelectedBackup
                                , isLoading = RemoteData.isLoading state.backupUpload
                                }
                          ]
                        , error
                        , [ View.Recovery.iHaveNoBackupButton
                                { onClick = RegainClickedIHaveNoBackup }
                          ]
                        ]
    in
    [ View.Dashboard.heading [ Html.text "Recover your Account" ]
    , View.Common.sectionSpacer
    , View.Dashboard.section []
        [ View.Recovery.steps
            [ View.Recovery.step 1 True "upload your secure backup file"
            , View.Recovery.step 2 False "verify your e-mail address"
            , View.Recovery.step 3 False "re-link your fission account"
            ]
        , View.Dashboard.sectionParagraph
            [ Html.text "If you’ve lost access to all your linked devices, you can recover your account here."
            ]
        , View.Dashboard.sectionGroup [] uploadSection
        ]
    ]


type Flow
    = FlowRecoverAccount
    | FlowRegainAccess


viewScreenWaitingForEmail : Flow -> List (Html Msg)
viewScreenWaitingForEmail flow =
    let
        heading =
            case flow of
                FlowRegainAccess ->
                    "Regain Your Account"

                FlowRecoverAccount ->
                    "Recover your Account"

        firstStep =
            case flow of
                FlowRegainAccess ->
                    "enter your username"

                FlowRecoverAccount ->
                    "upload your secure backup file"
    in
    [ View.Dashboard.heading [ Html.text heading ]
    , View.Common.sectionSpacer
    , View.Dashboard.section []
        [ View.Recovery.steps
            [ View.Recovery.step 1 False firstStep
            , View.Recovery.step 2 True "verify your e-mail address"
            , View.Recovery.step 3 False "re-link your fission account"
            ]
        , View.Dashboard.sectionParagraph
            [ Html.text "We’ve sent you an e-mail with further instructions for account recovery."
            , Html.br [] []
            , Html.br [] []
            , Html.text "That email will only be valid for one hour."
            , Html.br [] []
            , Html.br [] []
            , Html.text "You can go to your inbox and close this site."
            ]
        ]
    ]


viewScreenRegainAccess : StateRegainAccess -> List (Html Msg)
viewScreenRegainAccess state =
    [ View.Dashboard.heading [ Html.text "Regain Account Access" ]
    , View.Common.sectionSpacer
    , View.Dashboard.section []
        [ View.Recovery.steps
            [ View.Recovery.step 1 True "enter your username"
            , View.Recovery.step 2 False "verify your e-mail address"
            , View.Recovery.step 3 False "re-link your fission account"
            ]
        , View.Dashboard.sectionParagraph
            [ Html.text "Your private files are stored encrypted. Not even fission can read them."
            , Html.br [] []
            , Html.br [] []
            , Html.text "If you’ve lost your secure backup, we can’t recover your private files."
            , Html.br [] []
            , Html.br [] []
            , Html.text "However, we can restore access to your username and public files, if you can verify your e-mail address."
            , Html.br [] []
            , Html.br [] []
            , Html.text "Don’t worry, if you eventually find your backup, you’ll still be able to recover your private files."
            ]
        , View.Recovery.inputsRegainAccount
            { onSubmit = RegainClickedSendEmail
            , isLoading = RemoteData.isLoading state.sentEmail
            , disabled = RemoteData.isFailure state.usernameValidation || RemoteData.isLoading state.sentEmail
            , username = state.username
            , onInputUsername = RegainUsernameInput
            , errors =
                case state.usernameValidation of
                    RemoteData.Failure UsernameInvalid ->
                        [ View.Common.warning [ Html.text "That's not a valid fission username." ] ]

                    RemoteData.Failure UsernameNotFound ->
                        [ View.Common.warning [ Html.text "Couldn't find an account with this username." ] ]

                    _ ->
                        case state.sentEmail of
                            RemoteData.Failure httpError ->
                                case httpError of
                                    Http.BadStatus 422 ->
                                        [ View.Common.warning [ Html.text "Couldn't find an account with this username." ] ]

                                    _ ->
                                        [ View.Common.warning [ Html.text "Something went wrong when trying to send an email." ]
                                        , Html.br [] []
                                        , View.Recovery.contactSupportMessage True
                                        ]

                            _ ->
                                []
            }
        , View.Dashboard.sectionGroup []
            [ View.Recovery.buttonGoBack
                { onGoBack = RegainClickedGoBack
                , disabled = not (RemoteData.isNotAsked state.sentEmail)
                }
            ]
        ]
    ]


viewScreenVerifiedEmail : List (Html Msg)
viewScreenVerifiedEmail =
    [ View.Dashboard.heading [ Html.text "Recover your Account" ]
    , View.Common.sectionSpacer
    , View.Dashboard.section []
        [ View.Recovery.steps
            [ View.Recovery.step 1 False "upload your secure backup file"
            , View.Recovery.step 2 True "verify your e-mail address"
            , View.Recovery.step 3 False "re-link your fission account"
            ]
        , View.Dashboard.sectionParagraph
            [ Html.text "Hello <username>,"
            , Html.br [] []
            , Html.br [] []
            , Html.text "You’ve triggered a request to recover your account. We now know it was truly you."
            , Html.br [] []
            , Html.br [] []
            , Html.text "Any devices that might be linked to your fission account right now will need to be re-linked."
            , Html.br [] []
            , Html.text "Any apps you’re still signed in with need to be signed out and in again."
            , Html.br [] []
            , Html.br [] []
            , Html.text "<button>"
            ]
        ]
    ]


viewScreenWrongBrowser : List (Html Msg)
viewScreenWrongBrowser =
    [ View.Dashboard.heading [ Html.text "Recover your Account" ]
    , View.Common.sectionSpacer
    , View.Dashboard.section []
        [ View.Recovery.steps
            [ View.Recovery.step 1 False "upload your secure backup file"
            , View.Recovery.step 2 True "verify your e-mail address"
            , View.Recovery.step 3 False "re-link your fission account"
            ]
        , View.Dashboard.sectionParagraph
            [ View.Common.warning [ Html.text "We couldn’t find a backup in this browser." ] ]
        , View.Dashboard.sectionParagraph
            [ Html.text "Did you start the recovery process in another browser?"
            , Html.text "If you can’t remember having started a recovery process, then please just delete the e-mail you received."
            ]
        ]
    ]



--


parseBackup : String -> Result VerifyBackupError SecureBackup
parseBackup content =
    let
        keyValues =
            content
                |> String.split "\n"
                |> List.filter (not << String.startsWith "#")
                |> List.concatMap
                    (\line ->
                        case String.split ":" line of
                            [ key, value ] ->
                                [ ( String.trim key
                                  , String.trim value
                                  )
                                ]

                            _ ->
                                []
                    )
                |> Dict.fromList
    in
    Maybe.map2 SecureBackup
        (Dict.get "username" keyValues)
        (Dict.get "key" keyValues)
        |> Result.fromMaybe
            { message = "Couldn’t validate the backup."
            , contactSupport = True
            }
