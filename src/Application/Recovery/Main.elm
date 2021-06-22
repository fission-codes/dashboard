module Recovery.Main exposing (main, parseBackup)

import Browser
import Browser.Navigation as Navigation
import Dict
import File
import Html.Styled as Html exposing (Html)
import Http
import Json.Decode as Json
import Json.Encode as E
import Recovery.Ports as Ports
import Recovery.Radix exposing (..)
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
                            , Http.request
                                { method = "POST"
                                , headers = []
                                , url = model.endpoints.api ++ "/user/email/recover/" ++ backup.username
                                , body = Http.emptyBody
                                , expect = Http.expectWhatever RecoveryEmailSent
                                , timeout = Just 10000
                                , tracker = Nothing
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
                        , usernameMightExist = True
                        , usernameValid = True
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
            case model.recoveryState of
                ScreenRegainAccess state ->
                    ( { model
                        | recoveryState =
                            ScreenRegainAccess
                                { state
                                    | username = username
                                    , usernameMightExist = True
                                    , usernameValid = True
                                }
                      }
                    , if username |> String.trim |> String.isEmpty then
                        Cmd.none

                      else
                        Ports.usernameExists (String.trim username)
                    )

                _ ->
                    ( model, Cmd.none )

        RegainUsernameExists { username, exists, valid } ->
            case model.recoveryState of
                ScreenRegainAccess state ->
                    if state.username == username then
                        ( { model
                            | recoveryState =
                                ScreenRegainAccess
                                    { state
                                        | username = username
                                        , usernameMightExist = exists
                                        , usernameValid = valid
                                    }
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        RegainClickedSendEmail ->
            updateScreenRegainAccess model
                (\state ->
                    ( { state | sentEmail = RemoteData.Loading }
                    , -- TODO
                      Cmd.none
                    )
                )

        RegainEmailSent result ->
            -- TODO
            ( model, Cmd.none )

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
                        viewScreenWaitingForEmail

                    else
                        viewScreenRecoverAccount state

                ScreenRegainAccess state ->
                    viewScreenRegainAccess state
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
                            , disabled = False
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


viewScreenWaitingForEmail : List (Html Msg)
viewScreenWaitingForEmail =
    [ View.Dashboard.heading [ Html.text "Recover your Account" ]
    , View.Common.sectionSpacer
    , View.Dashboard.section []
        [ View.Recovery.steps
            [ View.Recovery.step 1 False "upload your secure backup file"
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
            , username = state.username
            , onInputUsername = RegainUsernameInput
            , errors =
                if not state.usernameValid then
                    [ View.Common.warning [ Html.text "That's not a valid fission username." ] ]

                else if state.usernameMightExist then
                    []

                else
                    [ View.Common.warning [ Html.text "Couldn't find an account with this username." ] ]
            }
        , View.Dashboard.sectionGroup []
            [ View.Recovery.buttonGoBack
                { onGoBack = RegainClickedGoBack
                , disabled = not (RemoteData.isNotAsked state.sentEmail)
                }
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
