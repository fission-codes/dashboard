module Authenticated exposing (..)

import Browser
import Dict exposing (Dict)
import FeatherIcons
import Html.Styled as Html exposing (Html)
import Json.Decode as Json
import List.Extra as List
import Ports
import Radix exposing (..)
import Route exposing (Route)
import Url exposing (Url)
import View.Account
import View.AppList
import View.Common
import View.Dashboard
import View.Navigation
import Webnative
import Webnative.Types as Webnative


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


update : AuthenticatedMsg -> AuthenticatedModel -> ( AuthenticatedModel, Cmd Msg )
update msg model =
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
                Ok dict ->
                    let
                        appList =
                            dict
                                |> Dict.toList
                                |> List.concatMap
                                    (\( _, urls ) ->
                                        urls
                                            |> List.concatMap
                                                (\url ->
                                                    case String.split "." url of
                                                        [ subdomain, _, _ ] ->
                                                            [ { name = subdomain
                                                              , url = url
                                                              }
                                                            ]

                                                        _ ->
                                                            []
                                                )
                                    )
                    in
                    ( { model | appList = Just appList }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        DropzonePublishStart ->
            ( model, Cmd.none )

        DropzonePublishEnd ->
            ( model, Cmd.none )

        DropzonePublishFail ->
            ( model, Cmd.none )

        DropzonePublishAction _ ->
            ( model, Cmd.none )

        DropzonePublishProgress _ ->
            ( model, Cmd.none )


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

                    Route.DeveloperAppList (Route.DeverloperAppListApp app) ->
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
                    [ View.Common.uppercaseButton
                        { label = "Resend Verification Email"
                        , onClick = AuthenticatedMsg EmailResendVerification
                        , isLoading = model.resendingVerificationEmail
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
                , View.AppList.uploadDropzone
                    { onPublishStart = AuthenticatedMsg DropzonePublishStart
                    , onPublishEnd = AuthenticatedMsg DropzonePublishEnd
                    , onPublishFail = AuthenticatedMsg DropzonePublishFail
                    , onPublishAction = AuthenticatedMsg << DropzonePublishAction
                    , onPublishProgress = AuthenticatedMsg << DropzonePublishProgress
                    , appName = Nothing
                    , dashedBorder = True
                    }
                    [ View.AppList.clickableDropzone ]
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
                                { name = app.name
                                , url = "https://" ++ app.url
                                , link = Route.DeveloperAppList (Route.DeverloperAppListApp app.url)
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


viewAppListApp : AuthenticatedModel -> String -> List (Html Msg)
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
                    , View.Dashboard.headingSubItem appName
                    ]
              ]
            , case model.appList of
                Nothing ->
                    [ viewAppListAppLoading ]

                Just appList ->
                    case List.find (\app -> app.url == appName) appList of
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


viewAppListAppNotFound : String -> Html Msg
viewAppListAppNotFound appName =
    View.Dashboard.section []
        [ View.Dashboard.sectionLoading
            [ View.Dashboard.sectionLoadingErrorIcon
            , View.Dashboard.sectionLoadingText
                [ Html.text "Could not find an app "
                , Html.text appName
                ]
            ]
        ]


viewAppListAppLoaded : AuthenticatedModel -> { name : String, url : String } -> List (Html Msg)
viewAppListAppLoaded model app =
    let
        realUrl =
            "https://" ++ app.url
    in
    [ View.Dashboard.section []
        [ View.Dashboard.sectionTitle []
            [ Html.text "Preview of "
            , View.Common.linkMarkedExternal [] { link = realUrl }
            ]
        , View.Dashboard.sectionParagraph []
            [ View.AppList.previewIframe { url = realUrl }
            ]
        ]
    , View.Dashboard.section []
        [ View.Dashboard.sectionTitle [] [ Html.text "Update your App" ]
        , View.Dashboard.sectionParagraph [ View.Common.infoTextStyle ]
            [ Html.text "Upload a folder with HTML, CSS and javascript files:"
            , View.AppList.uploadDropzone
                { onPublishStart = AuthenticatedMsg DropzonePublishStart
                , onPublishEnd = AuthenticatedMsg DropzonePublishEnd
                , onPublishFail = AuthenticatedMsg DropzonePublishFail
                , onPublishAction = AuthenticatedMsg << DropzonePublishAction
                , onPublishProgress = AuthenticatedMsg << DropzonePublishProgress
                , appName = Just app.name
                , dashedBorder = True
                }
                [ View.AppList.clickableDropzone ]
            ]
        ]
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
        ]


appsIndexDecoder : Json.Decoder (Dict String (List String))
appsIndexDecoder =
    Json.dict (Json.list Json.string)
