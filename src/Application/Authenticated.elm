module Authenticated exposing (..)

import Browser
import Browser.Navigation as Navigation
import Common
import Data.App as App
import Data.Validation
import Dict
import FeatherIcons
import Html.Styled as Html exposing (Html)
import Json.Decode as Json
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Ports
import Radix exposing (..)
import Route exposing (Route)
import Tailwind.Utilities
import Url exposing (Url)
import View.Account
import View.AppList
import View.Backup
import View.Common
import View.Dashboard
import View.Navigation
import Webnative.Types


init : Url -> { username : String, permissions : Webnative.Types.Permissions } -> ( AuthenticatedModel, Cmd Msg )
init url { username, permissions } =
    let
        route =
            Route.fromUrl url
                |> Maybe.withDefault Route.Index
    in
    ( { username = username
      , permissions = permissions
      , resendingVerificationEmail = False
      , navigationExpanded = False
      , route = route

      -- Backup
      , backupState = BackupWaiting

      -- App List
      , appList = Nothing
      , appListUploadState = DropzoneWaiting

      -- Individual App Pages
      , appPageModels = Dict.empty
      }
    , commandsByRoute route
    )


onRouteChange : Route -> AuthenticatedModel -> ( AuthenticatedModel, Cmd Msg )
onRouteChange route model =
    ( { model
        | route = route
        , navigationExpanded = False
        , backupState = BackupWaiting
      }
    , commandsByRoute route
    )


commandsByRoute : Route -> Cmd Msg
commandsByRoute route =
    case route of
        Route.DeveloperAppList _ ->
            Ports.webnativeAppIndexFetch ()

        _ ->
            Cmd.none


isProcessingSomething : AuthenticatedModel -> Bool
isProcessingSomething model =
    List.any ((==) True)
        [ case getAppPageModel model of
            Just pageModel ->
                List.any ((==) True)
                    [ pageModel.deletionState == AppDeletionInProgress
                    , pageModel.renamingState == AppRenameInProgress
                    ]

            Nothing ->
                False
        , case model.appListUploadState of
            DropzoneProgress _ ->
                True

            _ ->
                False
        , model.resendingVerificationEmail
        ]


getAppPageModel : AuthenticatedModel -> Maybe AppPageModel
getAppPageModel model =
    case model.route of
        Route.DeveloperAppList (Route.DeveloperAppListApp app) ->
            model.appPageModels
                |> Dict.get (App.toString app)

        _ ->
            Nothing


update : Navigation.Key -> AuthenticatedMsg -> AuthenticatedModel -> ( AuthenticatedModel, Cmd Msg )
update navKey msg model =
    case msg of
        Logout ->
            ( model
            , Ports.logout ()
            )

        -- Mobile Navigation
        ToggleNavigationExpanded ->
            ( { model | navigationExpanded = not model.navigationExpanded }
            , Cmd.none
            )

        -- Account
        EmailResendVerification ->
            ( { model | resendingVerificationEmail = True }
            , Ports.webnativeResendVerificationEmail {}
            )

        VerificationEmailSent ->
            ( { model | resendingVerificationEmail = False }
            , Cmd.none
            )

        -- Backup
        BackupAskForPermission ->
            ( model
            , Ports.redirectToLobby
                { permissions =
                    { app = Nothing
                    , platform = Nothing
                    , fs =
                        Just
                            { public = []
                            , private = [ Webnative.Types.Directory [] ]
                            }
                    }
                }
            )

        BackupStart ->
            case model.backupState of
                BackupWaiting ->
                    ( { model | backupState = BackupFetchingKey }
                    , Ports.fetchReadKey ()
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        BackupCancel ->
            ( { model | backupState = BackupWaiting }
            , Cmd.none
            )

        BackupReceivedKey { key, createdAt } ->
            case model.backupState of
                BackupFetchingKey ->
                    ( { model | backupState = BackupFetchedKey { key = key, visible = False, createdAt = createdAt } }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        BackupFetchKeyError _ ->
            case model.backupState of
                BackupFetchingKey ->
                    ( { model | backupState = BackupError }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )

        -- App list
        FetchedAppList value ->
            case Json.decodeValue appsIndexDecoder value of
                Ok appNames ->
                    ( { model | appList = Just appNames }
                    , Cmd.none
                    )

                Err error ->
                    ( model
                    , Ports.log
                        [ E.string "Error trying to parse the result of apps.index()"
                        , E.string (Json.errorToString error)
                        ]
                    )

        DropzonePublishStart ->
            ( { model | appListUploadState = DropzoneAction "" }
            , Cmd.none
            )

        DropzonePublishEnd determinedAppName ->
            ( { model | appListUploadState = DropzoneSucceeded determinedAppName }
            , Ports.webnativeAppIndexFetch ()
            )

        DropzoneSuccessDismiss ->
            ( { model | appListUploadState = DropzoneWaiting }
            , Cmd.none
            )

        DropzoneSuccessGoToApp determinedAppName ->
            ( { model | appListUploadState = DropzoneWaiting }
            , Navigation.pushUrl navKey
                (Route.toUrl
                    (Route.DeveloperAppList
                        (Route.DeveloperAppListApp
                            determinedAppName
                        )
                    )
                )
            )

        DropzonePublishFail ->
            ( { model | appListUploadState = DropzoneFailed }
            , Cmd.none
            )

        DropzonePublishAction info ->
            ( { model | appListUploadState = DropzoneAction info }
            , Cmd.none
            )

        DropzonePublishProgress info ->
            ( { model | appListUploadState = DropzoneProgress info }
            , Cmd.none
            )

        AppPageMsg app appPageMsg ->
            let
                key =
                    App.toString app

                pageModel =
                    model.appPageModels
                        |> Dict.get key
                        |> Maybe.withDefault initAppPage

                ( newPageModel, commands ) =
                    updateAppPage app pageModel appPageMsg
            in
            ( { model
                | appPageModels =
                    model.appPageModels
                        |> Dict.insert key newPageModel
              }
            , commands
            )


initAppPage : AppPageModel
initAppPage =
    { repeatAppNameInput = ""
    , deletionState = AppDeletionWaiting
    , renamingState = AppRenamingWaiting
    , renameAppInput = ""
    }


updateAppPage : App.Name -> AppPageModel -> AppPageMsg -> ( AppPageModel, Cmd Msg )
updateAppPage app model msg =
    case msg of
        AppPageRepeatAppNameInput value ->
            case model.deletionState of
                AppDeletionInProgress ->
                    ( model, Cmd.none )

                _ ->
                    ( { model
                        | repeatAppNameInput = value
                        , deletionState = AppDeletionWaiting
                      }
                    , Cmd.none
                    )

        AppPageDeleteAppClicked ->
            if
                List.any ((==) model.repeatAppNameInput)
                    [ App.nameOnly app
                    , App.toString app
                    , App.toUrl app
                    ]
            then
                ( { model | deletionState = AppDeletionInProgress }
                , Ports.appDelete app
                )

            else
                ( { model | deletionState = AppDeletionNotConfirmed }
                , Cmd.none
                )

        AppPageDeleteAppSucceeded ->
            ( { model
                | deletionState = AppDeletionWaiting
                , repeatAppNameInput = ""
              }
            , Navigation.load
                (Route.toUrl
                    (Route.DeveloperAppList
                        Route.DeveloperAppListIndex
                    )
                )
            )

        AppPageDeleteAppFailed message ->
            ( { model | deletionState = AppDeletionFailed message }
            , Cmd.none
            )

        AppPageRenameAppInput value ->
            ( { model
                | renameAppInput = value
                , renamingState = AppRenamingWaiting
              }
            , Cmd.none
            )

        AppPageRenameAppClicked ->
            let
                trimmed =
                    String.trim model.renameAppInput
            in
            if Data.Validation.isValid trimmed then
                ( { model | renamingState = AppRenameInProgress }
                , Ports.appRename
                    { from = app
                    , to = App.rename trimmed app
                    }
                )

            else
                ( { model | renamingState = AppRenamingInvalidName }
                , Cmd.none
                )

        AppPageRenameAppFailed _ ->
            ( { model | renamingState = AppRenamingFailed "Something went wrong when trying to rename. Maybe the app name is already taken? Please try to reload the website." }
            , Cmd.none
            )

        AppPageRenameAppSucceeded renamedApp ->
            ( { model
                | renamingState = AppRenamingWaiting
                , renameAppInput = ""
              }
            , Navigation.load
                (Route.toUrl
                    (Route.DeveloperAppList
                        (Route.DeveloperAppListApp
                            renamedApp
                        )
                    )
                )
            )


view : AuthenticatedModel -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        View.Dashboard.appShellWithNavigation
            { navigation =
                { expanded = model.navigationExpanded
                , onToggleExpanded = AuthenticatedMsg ToggleNavigationExpanded
                , items = navigationItems |> List.map (viewNavItem model)
                , onLogout = AuthenticatedMsg Logout
                }
            , main =
                case model.route of
                    Route.Index ->
                        viewAccount model

                    Route.Backup ->
                        viewBackup model

                    Route.DeveloperAppList Route.DeveloperAppListIndex ->
                        viewAppList model

                    Route.DeveloperAppList (Route.DeveloperAppListApp app) ->
                        viewAppListApp model app
            }
            |> Html.toUnstyled
            |> List.singleton
    }


type alias NavItem =
    { route : Route, name : String, icon : FeatherIcons.Icon }


navigationItems : List NavItem
navigationItems =
    [ { route = Route.Index
      , name = "Account"
      , icon = FeatherIcons.user
      }
    , { route = Route.Backup
      , name = "Secure Backup"
      , icon = FeatherIcons.key
      }
    , { route = Route.DeveloperAppList Route.DeveloperAppListIndex
      , name = "Apps"
      , icon = FeatherIcons.code
      }
    ]


viewNavItem : AuthenticatedModel -> NavItem -> Html Msg
viewNavItem model { route, icon, name } =
    View.Navigation.item []
        { active = Route.isSameFirstLevel route model.route
        , icon = icon
        , label = name
        , link = route
        }


viewAccount : AuthenticatedModel -> List (Html Msg)
viewAccount model =
    List.intersperse View.Common.sectionSpacer
        [ View.Dashboard.heading [ Html.text "Your Account" ]
        , View.Account.sectionUsername
            { username = [ View.Account.settingText [ Html.text model.username ] ]
            }
        , View.Account.sectionEmail
            { verificationStatus =
                [ View.Common.button
                    { label = "Resend Verification Email"
                    , onClick = Just (AuthenticatedMsg EmailResendVerification)
                    , isLoading = model.resendingVerificationEmail
                    , disabled = False
                    , style = View.Common.uppercaseButtonStyle
                    , spinnerStyle = []
                    }
                ]
            }
        ]


viewBackup : AuthenticatedModel -> List (Html Msg)
viewBackup model =
    let
        hasPrivateFilesystemPermissions permissions =
            case permissions.fs of
                Just { private } ->
                    private
                        |> List.any
                            (\path ->
                                case path of
                                    Webnative.Types.Directory [] ->
                                        True

                                    _ ->
                                        False
                            )

                _ ->
                    False
    in
    [ View.Dashboard.heading
        (List.append [ Html.span [] [ Html.text "Secure Backup" ] ]
            (case model.backupState of
                BackupWaiting ->
                    []

                _ ->
                    [ View.Backup.buttonBackupCancel (AuthenticatedMsg BackupCancel) ]
            )
        )
    , View.Common.sectionSpacer
    , View.Dashboard.section []
        (if hasPrivateFilesystemPermissions model.permissions then
            viewBackupPermissioned model

         else
            viewBackupInfoWith model
                [ View.Dashboard.sectionParagraph
                    [ Html.text "The dashboard will need access permissions to your private files to create a secure backup." ]
                , View.Backup.buttonGroup
                    [ View.Backup.buttonAskForPermission (AuthenticatedMsg BackupAskForPermission)
                    ]
                ]
        )
    ]


viewBackupInfoWith : AuthenticatedModel -> List (Html Msg) -> List (Html Msg)
viewBackupInfoWith model content =
    List.append
        [ View.Dashboard.sectionParagraph
            [ Html.text "Fission accounts don't need passwords, because we use the encryption built into your web browser to link devices."
            , Html.br [] []
            , Html.br [] []
            , Html.text "In case you lose access to all the devices you have linked to Fission, you need to store this secure backup in a safe place."
            ]
        , View.Backup.loggedInAs model.username
        ]
        content


viewBackupPermissioned : AuthenticatedModel -> List (Html Msg)
viewBackupPermissioned model =
    case model.backupState of
        BackupWaiting ->
            viewBackupInfoWith model
                [ View.Backup.buttonGroup
                    [ View.Backup.buttonSecureBackup (AuthenticatedMsg BackupStart) ]
                ]

        BackupFetchingKey ->
            viewBackupInfoWith model
                [ View.Backup.buttonGroup
                    [ View.Backup.buttonSecureBackup (AuthenticatedMsg BackupStart) ]
                ]

        BackupFetchedKey backup ->
            viewBackupShowingKey model backup

        BackupError ->
            viewBackupInfoWith model
                [ View.Backup.buttonGroup
                    [ View.Backup.buttonSecureBackup (AuthenticatedMsg BackupStart) ]
                , View.Common.warning
                    [ Html.text "Something went wrong while trying to create a backup. Please reload the page and try again or contact "
                    , View.Common.underlinedLink []
                        { location = "https://fission.codes/support"
                        , external = False
                        }
                        [ Html.text "our support" ]
                    , Html.text "."
                    ]
                ]


backupKeyInputFieldId : String
backupKeyInputFieldId =
    "backup-key"


viewBackupShowingKey : AuthenticatedModel -> { key : String, visible : Bool, createdAt : String } -> List (Html Msg)
viewBackupShowingKey model backup =
    [ View.Dashboard.sectionParagraph
        [ Html.text "This is your secure backup."
        , Html.br [] []
        , Html.br [] []
        , Html.text "Store it somewhere safe. "
        , Html.strong [] [ Html.text "Anyone with this backup will have read access to your private files" ]
        , Html.text " and "
        , Html.strong [] [ Html.text "losing it will mean you won’t be able to recover your private files" ]
        , Html.text " in case you lose all your linked devices. You can create a backup at any point when logged in."
        , Html.br [] []
        , Html.br [] []
        , Html.text "The fission team will never ask you to share your backup."
        ]
    , View.Dashboard.sectionGroup []
        [ View.Backup.buttonDownload
            { filename = "FissionSecureBackup-" ++ model.username ++ ".txt"
            , file =
                backupFile
                    { username = model.username
                    , key = backup.key
                    , createdAt = backup.createdAt
                    }
            }
        ]
    ]


backupFile :
    { username : String
    , key : String
    , createdAt : String
    }
    -> String
backupFile { username, key, createdAt } =
    [ "# MMMMMMMMMMMMMMMMMMMMMMMMWXkoccdxxookXWMM"
    , "# MWXOxolodkXWMMMMMMMMMMMWk;..cONWW0l',oXM"
    , "# Xd;.......,oKWMMMMMMMMWx'..oXMMMMMNd..:K"
    , "# c...........;0MMMMMMMWk,..lXMMMMMMMXl..l"
    , "# .............oNMMMMMW0;..cKMMMMMMMMWd..:"
    , "# '............'cxOXNKkc..;0MMMMMMMMW0:..o"
    , "# d'...............';;'...ckO000Okxoc'..:K"
    , "# WOl,.....'cdo:,.....................,oKM"
    , "# MMWX0Okk0XWMMWX0kl.....,''.....',:lxKWMM"
    , "# MMMMMMMMMMMMMMMMWd...'xXXKK000KXXWMMMMMM"
    , "# MMMWNKOxddddddxkd,...lXMMMMMMMMMMMMMMMMM"
    , "# MNOl;'...............,coxOXNXkdlllox0WMM"
    , "# Kc....';;::::;,...........,;,.......'c0W"
    , "# :..:x0XNNWWWWXo...cddo:,..............,O"
    , "# ..cKMMMMMMMMWO,..:KMMMWXOc.............o"
    , "# .lNMMMMMMMM0:..;OWMMMMMM0;............d"
    , "# ,.,OWMMMMMMKc..'kWMMMMMMMWk,..........lX"
    , "# k,.;OWMMMWKc..,kWMMMMMMMMMWKo;'....,lkNM"
    , "# WKd;;oOKOd,.'cOWMMMMMMMMMMMMMNK0OO0XWMMM"
    , "# MMWXklcc:;:o0NMMMMMMMMMMMMMMMMMMMMMMMMMM"
    , "# "
    , "# This is your secure backup. (It’s a yaml text file)"
    , "# "
    , "# Created for " ++ username ++ " on " ++ createdAt
    , "# "
    , "# Store this somewhere safe."
    , "# "
    , "# Anyone with this backup will have read access to your private files."
    , "# Losing it means you won’t be able to recover your account"
    , "# in case you lose access to all your linked devices."
    , "# "
    , "# The fission team will never ask you to share this file."
    , "# "
    , "# To use this file, go to https://dashboard.fission.codes/recover/"
    , "# For more information, read https://guide.fission.codes/"
    , "# If you need help, contact us at support@fission.codes"
    , "username: " ++ username
    , "key: " ++ key
    ]
        |> String.join "\n"


viewAppList : AuthenticatedModel -> List (Html Msg)
viewAppList model =
    List.intersperse View.Common.sectionSpacer
        [ View.Dashboard.heading [ Html.text "App Management" ]
        , View.Dashboard.section []
            [ View.Dashboard.sectionTitle [] [ Html.text "Create a new App" ]
            , View.Dashboard.sectionGroup [ View.Common.infoTextStyle ]
                [ Html.text "Upload a folder with HTML, CSS and javascript files:"
                , viewUploadDropzone Nothing model.appListUploadState
                ]
            , View.Dashboard.sectionParagraph
                [ Html.span []
                    [ -- TODO: Add back when the generator is published and can create apps
                      --   Html.text "Don’t know how to get started? Start with the "
                      -- , View.Common.underlinedLink []
                      --     { location = "https://generator.fission.codes" }
                      --     [ Html.text "app generator" ]
                      -- , Html.text "!"
                      -- , Html.br [] []
                      -- , Html.br [] []
                      -- ,
                      Html.text "Are you comfortable with a terminal? Use the "
                    , View.Common.underlinedLink []
                        { location = "https://guide.fission.codes/developers/installation#installing-the-fission-cli"
                        , external = True
                        }
                        [ Html.text "fission command line interface" ]
                    , Html.text "!"
                    ]
                ]
            ]
        , case model.appList of
            Just [] ->
                View.AppList.sectionAppList
                    (View.Dashboard.sectionLoading
                        [ View.Dashboard.sectionLoadingText
                            [ Html.text "No Apps published, yet. Become a developer by uploading your first app using the section above." ]
                        ]
                    )

            Just loadedList ->
                loadedList
                    |> List.map
                        (\app ->
                            View.AppList.appListItem
                                { name = App.nameOnly app
                                , url = App.toUrl app
                                , link = Route.DeveloperAppList (Route.DeveloperAppListApp app)
                                }
                        )
                    |> View.AppList.appListLoaded
                    |> View.AppList.sectionAppList

            Nothing ->
                View.AppList.sectionAppList
                    (View.Dashboard.sectionLoading
                        [ View.Dashboard.sectionLoadingIndicator
                        , View.Dashboard.sectionLoadingText
                            [ Html.text "Loading List" ]
                        ]
                    )
        ]


viewUploadDropzone : Maybe App.Name -> UploadDropzoneState -> Html Msg
viewUploadDropzone appName state =
    let
        viewDropzone dashedBorder =
            View.AppList.uploadDropzone
                { onPublishStart = AuthenticatedMsg DropzonePublishStart
                , onPublishEnd = AuthenticatedMsg << DropzonePublishEnd
                , onPublishFail = AuthenticatedMsg DropzonePublishFail
                , onPublishAction = AuthenticatedMsg << DropzonePublishAction
                , onPublishProgress = AuthenticatedMsg << DropzonePublishProgress
                , appName = appName
                , dashedBorder = dashedBorder
                }
    in
    case state of
        DropzoneWaiting ->
            viewDropzone True
                [ View.AppList.clickableDropzone ]

        DropzoneAction action ->
            viewDropzone False
                [ View.AppList.dropzoneLoading
                    [ View.Dashboard.sectionLoadingIndicator
                    , View.Dashboard.sectionLoadingText
                        [ Html.text action ]
                    ]
                ]

        DropzoneProgress progress ->
            viewDropzone False
                [ View.AppList.dropzoneLoading
                    [ View.Dashboard.sectionLoadingIndicator
                    , View.AppList.dropzoneProgressIndicator
                        { progress = progress.progress
                        , total = progress.total
                        }
                    , View.Dashboard.sectionLoadingText
                        [ Html.text progress.info ]
                    ]
                ]

        DropzoneSucceeded determinedAppName ->
            viewDropzone False
                [ View.AppList.dropzoneLoading
                    [ View.Dashboard.iconSuccess
                    , View.Dashboard.sectionLoadingText
                        [ Html.text "Success! "
                        , View.Common.underlinedLink []
                            { location = App.toUrl determinedAppName
                            , external = True
                            }
                            [ Html.text (App.toString determinedAppName) ]
                        , Html.text " is now live! 🚀"
                        ]
                    , case appName of
                        Nothing ->
                            View.Common.button
                                { label = "To the App Page"
                                , onClick = Just (AuthenticatedMsg (DropzoneSuccessGoToApp determinedAppName))
                                , isLoading = False
                                , disabled = False
                                , style = View.Common.uppercaseButtonStyle
                                , spinnerStyle = []
                                }

                        Just _ ->
                            View.Common.button
                                { label = "Dismiss"
                                , onClick = Just (AuthenticatedMsg DropzoneSuccessDismiss)
                                , isLoading = False
                                , disabled = False
                                , style = View.Common.uppercaseButtonStyle
                                , spinnerStyle = []
                                }
                    ]
                ]

        DropzoneFailed ->
            viewDropzone False
                [ View.AppList.dropzoneLoading
                    [ View.Dashboard.iconError
                    , View.Dashboard.sectionLoadingText
                        [ Html.text "Oops! Something went wrong... Reload and try again."
                        , Html.br [] []
                        , Html.text "If you're advanced, you can check the developer console for errors and "
                        , View.Common.underlinedLink []
                            { location = "https://github.com/fission-suite/dashboard/issues"
                            , external = False
                            }
                            [ Html.text "file an issue" ]
                        , Html.text "."
                        ]
                    ]
                ]


viewAppListApp : AuthenticatedModel -> App.Name -> List (Html Msg)
viewAppListApp model appName =
    List.intersperse
        View.Common.sectionSpacer
        (List.concat
            [ [ View.Dashboard.heading
                    [ View.Dashboard.headingSubLevel
                        { link = Route.DeveloperAppList Route.DeveloperAppListIndex
                        , label = "Developed Apps"
                        }
                    , View.Dashboard.headingSeparator
                    , View.Dashboard.headingSubItem (App.toString appName)
                    ]
              ]
            , case model.appList of
                Nothing ->
                    [ viewAppListAppLoading ]

                Just appList ->
                    case List.find ((==) appName) appList of
                        Just app ->
                            viewAppListAppLoaded
                                model
                                (getAppPageModel model |> Maybe.withDefault initAppPage)
                                app

                        Nothing ->
                            [ viewAppListAppNotFound appName ]
            ]
        )


viewAppListAppLoading : Html Msg
viewAppListAppLoading =
    View.Dashboard.section []
        [ View.Dashboard.sectionLoading
            [ View.Dashboard.sectionLoadingIndicator
            , View.Dashboard.sectionLoadingText
                [ Html.text "Loading app information" ]
            ]
        ]


viewAppListAppNotFound : App.Name -> Html Msg
viewAppListAppNotFound appName =
    View.Dashboard.section []
        [ View.Dashboard.sectionLoading
            [ View.Dashboard.iconError
            , View.Dashboard.sectionLoadingText
                [ Html.text "Could not find an app "
                , Html.text (App.toString appName)
                ]
            ]
        ]


viewAppListAppLoaded : AuthenticatedModel -> AppPageModel -> App.Name -> List (Html Msg)
viewAppListAppLoaded model pageModel app =
    [ View.Dashboard.section []
        [ View.Dashboard.sectionTitle []
            [ Html.text "Preview of "
            , View.Common.linkMarkedExternal [] { link = App.toUrl app }
            ]
        , View.Dashboard.sectionGroup []
            [ View.AppList.previewIframe { url = App.toUrl app }
            ]
        ]
    , View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ Html.text "Update your App" ]
        , View.Dashboard.sectionGroup [ View.Common.infoTextStyle ]
            [ Html.text "Upload a folder with HTML, CSS and javascript files:"
            , viewUploadDropzone (Just app) model.appListUploadState
            ]
        ]
    , viewAppRenamingSection pageModel app
    , viewAppDeletionSection pageModel app
    ]


viewAppRenamingSection : AppPageModel -> App.Name -> Html Msg
viewAppRenamingSection pageModel app =
    let
        renaming =
            case pageModel.renamingState of
                AppRenamingWaiting ->
                    { loading = False
                    , error = Nothing
                    }

                AppRenamingInvalidName ->
                    { loading = False
                    , error = Just "This is not a valid subdomain name. Make sure to only use alphanumeric, lowercase characters. You can split words with dashes or underscores."
                    }

                AppRenameInProgress ->
                    { loading = True
                    , error = Nothing
                    }

                AppRenamingFailed error ->
                    { loading = False
                    , error = Just error
                    }
    in
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ Html.text "Rename your App" ]
        , View.Dashboard.sectionGroup [ View.Common.infoTextStyle ]
            (List.concat
                [ [ Html.span [] [ Html.text "Auto-generated subdomains are often pretty cool, but sometimes you just like to put a chosen name on your project! It’s first come, first serve." ]
                  , View.AppList.inputRow
                        { onSubmit = AuthenticatedMsg (AppPageMsg app AppPageRenameAppClicked)
                        , input =
                            [ View.Common.input
                                { placeholder = "your-subdomain"
                                , value = pageModel.renameAppInput
                                , onInput = AuthenticatedMsg << AppPageMsg app << AppPageRenameAppInput
                                , inErrorState = Maybe.isJust renaming.error
                                , disabled = renaming.loading
                                , style = View.Common.basicInputStyle
                                }
                            , View.AppList.appNameRest ".fission.app"
                            ]
                        , button =
                            View.Common.button
                                { isLoading = renaming.loading
                                , disabled = Maybe.isJust renaming.error
                                , onClick = Nothing
                                , label = "Rename App"
                                , style = View.Common.uppercaseButtonStyle
                                , spinnerStyle = []
                                }
                        }
                  ]
                , case renaming.error of
                    Just error ->
                        [ View.Common.warning [ Html.text error ] ]

                    _ ->
                        []
                ]
            )
        ]


viewAppDeletionSection : AppPageModel -> App.Name -> Html Msg
viewAppDeletionSection pageModel app =
    let
        deletion =
            case pageModel.deletionState of
                AppDeletionWaiting ->
                    { loading = False
                    , failed = False
                    , unconfirmed = False
                    , error = Nothing
                    }

                AppDeletionInProgress ->
                    { loading = True
                    , failed = False
                    , unconfirmed = False
                    , error = Nothing
                    }

                AppDeletionFailed error ->
                    { loading = False
                    , failed = True
                    , unconfirmed = False
                    , error = Just error
                    }

                AppDeletionNotConfirmed ->
                    { loading = False
                    , failed = True
                    , unconfirmed = True
                    , error = Nothing
                    }
    in
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ Html.text "Delete your App" ]
        , View.Dashboard.sectionGroup [ View.Common.infoTextStyle ]
            (List.concat
                [ [ Html.span []
                        [ Html.text "This will make the app unaccessible at "
                        , View.Common.linkMarkedExternal [] { link = App.toUrl app }
                        , Html.text ". The app’s data will still exist in your local filesystem under "
                        , View.Common.monoInfoText [ Html.text ("public/Apps/" ++ App.nameOnly app ++ "/Published") ]
                        , Html.text "."
                        ]
                  , View.AppList.inputRow
                        { onSubmit = AuthenticatedMsg (AppPageMsg app AppPageDeleteAppClicked)
                        , input =
                            [ View.Common.input
                                { placeholder = "please type " ++ App.nameOnly app ++ " to confirm"
                                , value = pageModel.repeatAppNameInput
                                , onInput = AuthenticatedMsg << AppPageMsg app << AppPageRepeatAppNameInput
                                , inErrorState = deletion.failed
                                , disabled = deletion.loading
                                , style = View.Common.basicInputStyle
                                }
                            ]
                        , button =
                            View.Common.button
                                { isLoading = deletion.loading
                                , onClick = Nothing
                                , label = "Delete App"
                                , disabled = False
                                , style = View.Common.dangerButtonStyle
                                , spinnerStyle = [ Tailwind.Utilities.text_gray_500 ]
                                }
                        }
                  ]
                , Common.when deletion.unconfirmed
                    [ View.Common.warning
                        [ Html.text "Please confirm your deletion by typing in the correct app name." ]
                    ]
                , case deletion.error of
                    Just error ->
                        [ View.Common.warning
                            [ Html.text "There was an issue when trying to delete the app: "
                            , Html.text error
                            ]
                        ]

                    _ ->
                        []
                ]
            )
        ]


subscriptions : AuthenticatedModel -> Sub Msg
subscriptions model =
    Sub.batch
        [ if model.resendingVerificationEmail then
            Ports.webnativeVerificationEmailSent
                (\_ -> AuthenticatedMsg VerificationEmailSent)

          else
            Sub.none
        , case model.backupState of
            BackupFetchingKey ->
                Sub.batch
                    [ Ports.fetchedReadKey (AuthenticatedMsg << BackupReceivedKey)
                    , Ports.fetchReadKeyError (AuthenticatedMsg << BackupFetchKeyError)
                    ]

            _ ->
                Sub.none
        , Ports.webnativeAppIndexFetched (AuthenticatedMsg << FetchedAppList)
        , case getAppPageModel model of
            Just pageModel ->
                appPageSubscriptions pageModel

            Nothing ->
                Sub.none
        ]


appPageSubscriptions : AppPageModel -> Sub Msg
appPageSubscriptions pageModel =
    let
        subError portName error =
            LogError
                [ E.string ("Error while parsing port " ++ portName ++ ":")
                , E.string (Json.errorToString error)
                ]
    in
    Sub.batch
        [ case pageModel.deletionState of
            AppDeletionInProgress ->
                Sub.batch
                    [ Ports.appDeleteFailed
                        (\app error -> AuthenticatedMsg (AppPageMsg app (AppPageDeleteAppFailed error)))
                        (subError "appDeleteFailed")
                    , Ports.appDeleteSucceeded
                        (\app -> AuthenticatedMsg (AppPageMsg app AppPageDeleteAppSucceeded))
                        (subError "appDeleteSucceeded")
                    ]

            _ ->
                Sub.none
        , case pageModel.renamingState of
            AppRenameInProgress ->
                Sub.batch
                    [ Ports.appRenameFailed
                        (\app error -> AuthenticatedMsg (AppPageMsg app (AppPageRenameAppFailed error)))
                        (subError "appRenameFailed")
                    , Ports.appRenameSucceeded
                        (\{ app, renamed } -> AuthenticatedMsg (AppPageMsg app (AppPageRenameAppSucceeded renamed)))
                        (subError "appRenameSucceeded")
                    ]

            _ ->
                Sub.none
        ]


appsIndexDecoder : Json.Decoder (List App.Name)
appsIndexDecoder =
    Json.list (Json.field "domain" App.decoder)
