module Recovery.Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Html.Styled as Html
import Json.Encode as E
import Ports
import Recovery.Radix exposing (..)
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
      , url = url
      , username = ""
      , backup = ""
      , recoveryState = EnterUsername
      }
    , Cmd.none
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
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

        -----------------------------------------
        -- URL
        -----------------------------------------
        UsernameInput username ->
            ( { model | username = username }
            , Cmd.none
            )

        BackupInput backup ->
            ( { model | backup = backup }
            , Cmd.none
            )

        StartRecoveryClicked ->
            if String.trim model.backup /= "" && String.trim model.username /= "" then
                ( { model
                    | username = String.trim model.username
                    , backup = String.trim model.backup
                    , recoveryState = Loading
                  }
                  -- TODO
                , Cmd.none
                )

            else
                -- TODO
                ( model, Cmd.none )



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Dashboard - Account Recovery"
    , body =
        [ (case model.recoveryState of
            _ ->
                View.Recovery.appShell
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
                        , View.Dashboard.sectionGroup []
                            [ View.Recovery.backupUpload
                            , View.Recovery.iHaveNoBackupButton
                            ]
                        ]
                    ]
          )
            |> Html.toUnstyled
        ]
    }
