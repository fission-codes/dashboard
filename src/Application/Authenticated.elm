module Authenticated exposing (..)

import Browser
import Browser.Navigation as Navigation
import Common
import Data.App as App
import Data.Validation
import FeatherIcons
import Html.Styled as Html exposing (Html)
import Json.Decode as Json
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Ports
import Radix exposing (..)
import Route exposing (Route)
import Url exposing (Url)
import View.Account
import View.AppList
import View.Common
import View.Dashboard
import View.Navigation


init : Url -> String -> ( AuthenticatedModel, Cmd Msg )
init url username =
    let
        route =
            Route.fromUrl url
                |> Maybe.withDefault Route.Index
    in
    ( { username = username
      , resendingVerificationEmail = False
      , navigationExpanded = False
      , route = route
      , appList = Nothing
      , uploadDropzoneState = DropzoneWaiting
      , repeatAppNameInput = ""
      , deletionState = AppDeletionWaiting
      , renamingState = AppRenamingWaiting
      , renameAppInput = ""
      }
    , commandsByRoute route
    )


onRouteChange : Route -> AuthenticatedModel -> ( AuthenticatedModel, Cmd Msg )
onRouteChange route model =
    ( { model
        | route = route
        , navigationExpanded = False
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


update : Navigation.Key -> AuthenticatedMsg -> AuthenticatedModel -> ( AuthenticatedModel, Cmd Msg )
update navKey msg model =
    case msg of
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
            ( { model | uploadDropzoneState = DropzoneAction "" }
            , Cmd.none
            )

        DropzonePublishEnd determinedAppName ->
            ( { model | uploadDropzoneState = DropzoneSucceeded determinedAppName }
            , Ports.webnativeAppIndexFetch ()
            )

        DropzoneSuccessDismiss ->
            ( { model | uploadDropzoneState = DropzoneWaiting }
            , Cmd.none
            )

        DropzoneSuccessGoToApp determinedAppName ->
            ( { model | uploadDropzoneState = DropzoneWaiting }
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
            ( { model | uploadDropzoneState = DropzoneFailed }
            , Cmd.none
            )

        DropzonePublishAction info ->
            ( { model | uploadDropzoneState = DropzoneAction info }
            , Cmd.none
            )

        DropzonePublishProgress info ->
            ( { model | uploadDropzoneState = DropzoneProgress info }
            , Cmd.none
            )

        RepeatAppNameInput value ->
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

        DeleteAppClicked app ->
            if
                List.any ((==) model.repeatAppNameInput)
                    [ App.nameOnly app
                    , App.toString app
                    , App.toUrl app
                    ]
            then
                ( { model | deletionState = AppDeletionInProgress }
                , Ports.webnativeAppDelete (App.encode app)
                )

            else
                ( { model | deletionState = AppDeletionNotConfirmed }
                , Cmd.none
                )

        DeleteAppSucceeded ->
            ( model
            , Navigation.load (Route.toUrl (Route.DeveloperAppList Route.DeveloperAppListIndex))
            )

        DeleteAppFailed message ->
            ( { model | deletionState = AppDeletionFailed message }
            , Cmd.none
            )

        RenameAppInput value ->
            ( { model
                | renameAppInput = value
                , renamingState = AppRenamingWaiting
              }
            , Cmd.none
            )

        RenameAppClicked app ->
            let
                trimmed =
                    String.trim model.renameAppInput
            in
            if Data.Validation.isValid trimmed then
                ( model, Cmd.none )

            else
                ( { model | renamingState = AppRenamingInvalidName }
                , Cmd.none
                )


view : AuthenticatedModel -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        View.Dashboard.appShell
            { navigation =
                { expanded = model.navigationExpanded
                , onToggleExpanded = AuthenticatedMsg ToggleNavigationExpanded
                , items =
                    List.concat
                        [ [ View.Navigation.header "Users" ]
                        , navigationItems.users |> List.map (viewNavItem model)
                        , [ View.Navigation.header "Developers" ]
                        , navigationItems.developers |> List.map (viewNavItem model)
                        ]
                }
            , main =
                case model.route of
                    Route.Index ->
                        viewAccount model

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


navigationItems : { users : List NavItem, developers : List NavItem }
navigationItems =
    { users =
        [ { route = Route.Index
          , name = "Account"
          , icon = FeatherIcons.user
          }
        ]
    , developers =
        [ { route = Route.DeveloperAppList Route.DeveloperAppListIndex
          , name = "App List"
          , icon = FeatherIcons.code
          }
        ]
    }


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
    View.Account.workInProgressBanner
        :: List.intersperse View.Common.sectionSpacer
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
                        }
                    ]
                }
            ]


viewAppList : AuthenticatedModel -> List (Html Msg)
viewAppList model =
    List.intersperse View.Common.sectionSpacer
        [ View.Dashboard.heading [ Html.text "Developed Apps" ]
        , View.Dashboard.section []
            [ View.Dashboard.sectionTitle [] [ Html.text "Create a new App" ]
            , View.Dashboard.sectionParagraph [ View.Common.infoTextStyle ]
                [ Html.text "Upload a folder with HTML, CSS and javascript files:"
                , viewUploadDropzone Nothing model.uploadDropzoneState
                ]
            , View.Dashboard.sectionParagraph [ View.Common.infoTextStyle ]
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
                        { location = "https://guide.fission.codes/developers/installation#installing-the-fission-cli" }
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
                            { location = App.toUrl determinedAppName }
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
                                }

                        Just _ ->
                            View.Common.button
                                { label = "Dismiss"
                                , onClick = Just (AuthenticatedMsg DropzoneSuccessDismiss)
                                , isLoading = False
                                , disabled = False
                                , style = View.Common.uppercaseButtonStyle
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
                            { location = "https://github.com/fission-suite/dashboard/issues" }
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
                            viewAppListAppLoaded model app

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


viewAppListAppLoaded : AuthenticatedModel -> App.Name -> List (Html Msg)
viewAppListAppLoaded model app =
    [ View.Dashboard.section []
        [ View.Dashboard.sectionTitle []
            [ Html.text "Preview of "
            , View.Common.linkMarkedExternal [] { link = App.toUrl app }
            ]
        , View.Dashboard.sectionParagraph []
            [ View.AppList.previewIframe { url = App.toUrl app }
            ]
        ]
    , View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ Html.text "Update your App" ]
        , View.Dashboard.sectionParagraph [ View.Common.infoTextStyle ]
            [ Html.text "Upload a folder with HTML, CSS and javascript files:"
            , viewUploadDropzone (Just app) model.uploadDropzoneState
            ]
        ]
    , viewAppRenamingSection model app
    , viewAppDeletionSection model app
    ]


viewAppRenamingSection : AuthenticatedModel -> App.Name -> Html Msg
viewAppRenamingSection model app =
    let
        renaming =
            case model.renamingState of
                AppRenamingWaiting ->
                    { loading = False
                    , error = Nothing
                    }

                AppRenamingInvalidName ->
                    { loading = False
                    , error = Just "This is not a valid subdomain name. Make sure to only use alphanumeric, lowercase characters. You can split words with dashes or underscores."
                    }
    in
    View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ Html.text "Rename your App" ]
        , View.Dashboard.sectionParagraph [ View.Common.infoTextStyle ]
            (List.concat
                [ [ Html.span [] [ Html.text "Auto-generated subdomains are often pretty cool, but sometimes you just like to put a chosen name on your project! It’s first come, first serve." ]
                  , View.AppList.inputRow
                        { onSubmit = AuthenticatedMsg (RenameAppClicked app) }
                        [ View.Common.input
                            { placeholder = "your-subdomain"
                            , value = model.renameAppInput
                            , onInput = AuthenticatedMsg << RenameAppInput
                            , inErrorState = Maybe.isJust renaming.error
                            , disabled = renaming.loading
                            , style = View.Common.basicInputStyle
                            }
                        , View.AppList.appNameRest ".fission.app"
                        , View.Common.button
                            { isLoading = renaming.loading
                            , disabled = Maybe.isJust renaming.error
                            , onClick = Nothing
                            , label = "Rename App"
                            , style = View.Common.uppercaseButtonStyle
                            }
                        ]
                  ]
                , case renaming.error of
                    Just error ->
                        [ View.Common.warning [ Html.text error ] ]

                    _ ->
                        []
                ]
            )
        ]


viewAppDeletionSection : AuthenticatedModel -> App.Name -> Html Msg
viewAppDeletionSection model app =
    let
        deletion =
            case model.deletionState of
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
        , View.Dashboard.sectionParagraph [ View.Common.infoTextStyle ]
            (List.concat
                [ [ Html.span []
                        [ Html.text "This will make the app unaccessible at "
                        , View.Common.linkMarkedExternal [] { link = App.toUrl app }
                        , Html.text ". The app’s data will still exist in your local filesystem under "
                        , View.Common.monoInfoText [ Html.text ("public/Apps/" ++ App.nameOnly app ++ "/Published") ]
                        , Html.text "."
                        ]
                  , View.AppList.inputRow
                        { onSubmit = AuthenticatedMsg (DeleteAppClicked app) }
                        [ View.Common.input
                            { placeholder = "please type " ++ App.nameOnly app ++ " to confirm"
                            , value = model.repeatAppNameInput
                            , onInput = AuthenticatedMsg << RepeatAppNameInput
                            , inErrorState = deletion.failed
                            , disabled = deletion.loading
                            , style = View.Common.basicInputStyle
                            }
                        , View.Common.button
                            { isLoading = deletion.loading
                            , onClick = Nothing
                            , label = "Delete App"
                            , disabled = False
                            , style = View.Common.dangerButtonStyle
                            }
                        ]
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
        , Ports.webnativeAppIndexFetched (AuthenticatedMsg << FetchedAppList)
        , if model.deletionState == AppDeletionInProgress then
            Sub.batch
                [ Ports.webnativeAppDeleteFailed (AuthenticatedMsg << DeleteAppFailed)
                , Ports.webnativeAppDeleteSucceeded (\_ -> AuthenticatedMsg DeleteAppSucceeded)
                ]

          else
            Sub.none
        ]


appsIndexDecoder : Json.Decoder (List App.Name)
appsIndexDecoder =
    Json.list (Json.field "domain" App.decoder)
