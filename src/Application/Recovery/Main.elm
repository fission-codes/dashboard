module Recovery.Main exposing (main, parseBackup)

import Browser
import Browser.Navigation as Navigation
import Dict
import File
import Html.Styled as Html
import Json.Decode as Json
import Json.Encode as E
import Recovery.Ports as Ports
import Recovery.Radix exposing (..)
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
init _ url navKey =
    ( { navKey = navKey
      , url = url
      , username = ""
      , backup = ""
      , recoveryState = InitialScreen Nothing
      }
    , Cmd.none
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SelectedBackup files ->
            case files of
                [ file ] ->
                    ( model
                    , Task.perform UploadedBackup (File.toString file)
                    )

                _ ->
                    ( model
                    , Ports.log [ E.string "Unexpected amount of files uploaded. Expected 1 but got ", E.int (List.length files) ]
                    )

        UploadedBackup content ->
            case parseBackup content of
                Ok backup ->
                    ( model, Ports.verifyBackup backup )

                Err error ->
                    ( { model | recoveryState = InitialScreen (Just (Err error)) }
                    , Cmd.none
                    )

        VerifyBackupFailed error ->
            ( { model | recoveryState = InitialScreen (Just (Err error)) }
            , Cmd.none
            )

        VerifyBackupSucceeded backup ->
            ( { model | recoveryState = InitialScreen (Just (Ok backup)) }
            , Cmd.none
            )

        ClickedSendEmail ->
            ( { model | recoveryState = WaitingForEmail }
              -- TODO
            , Cmd.none
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



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.recoveryState of
        InitialScreen _ ->
            Sub.batch
                [ Ports.verifyBackupFailed VerifyBackupFailed
                , Ports.verifyBackupSucceeded VerifyBackupSucceeded
                ]

        WaitingForEmail ->
            Sub.none



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Dashboard - Account Recovery"
    , body =
        [ View.Recovery.appShell
            (case model.recoveryState of
                InitialScreen result ->
                    let
                        error =
                            case result of
                                Just (Err verifyError) ->
                                    [ View.Common.warning
                                        [ Html.text verifyError.message
                                        , Html.br [] []
                                        , View.Recovery.contactSupportMessage verifyError.contactSupport
                                        ]
                                    ]

                                _ ->
                                    []

                        uploadSection =
                            case result of
                                Just (Ok backup) ->
                                    [ View.Recovery.importedBackupCheckmark
                                    , View.Recovery.welcomeBackMessage backup.username
                                    , View.Recovery.buttonSendEmail
                                        { onClickSendEmail = ClickedSendEmail }
                                    ]

                                _ ->
                                    List.concat
                                        [ [ View.Recovery.backupUpload
                                                { onUpload =
                                                    Json.at [ "target", "files" ] (Json.list File.decoder)
                                                        |> Json.map SelectedBackup
                                                }
                                          ]
                                        , error
                                        , [ View.Recovery.iHaveNoBackupButton
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

                WaitingForEmail ->
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
                            , Html.text "This email will only be valid for 24 hours."
                            , Html.br [] []
                            , Html.br [] []
                            , Html.text "You can go to your inbox and close this site."
                            ]
                        ]
                    ]
            )
            |> Html.toUnstyled
        ]
    }



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
