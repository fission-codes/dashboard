module Dashboard exposing (..)

import Browser
import FeatherIcons
import Html.Styled as Html exposing (Html)
import Json.Decode as Json
import Ports
import Radix exposing (..)
import Route exposing (Route)
import Url exposing (Url)
import View.Dashboard as View
import Webnative
import Webnative.Types as Webnative


init : Url -> String -> DashboardModel
init url username =
    { username = username
    , resendingVerificationEmail = False
    , navigationExpanded = False
    , route =
        Route.fromUrl url
            |> Maybe.withDefault Route.Index
    }


update : DashboardMsg -> DashboardModel -> ( DashboardModel, Cmd Msg )
update msg model =
    case msg of
        -----------------------------------------
        -- App
        -----------------------------------------
        EmailResendVerification ->
            ( { model | resendingVerificationEmail = True }
            , Ports.webnativeResendVerificationEmail {}
            )

        VerificationEmailSent ->
            ( { model | resendingVerificationEmail = False }
            , Cmd.none
            )

        ToggleNavigationExpanded ->
            ( { model | navigationExpanded = not model.navigationExpanded }
            , Cmd.none
            )


view : DashboardModel -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        View.appShell
            { navigation =
                { expanded = model.navigationExpanded
                , onToggleExpanded = DashboardMsg ToggleNavigationExpanded
                , items =
                    List.concat
                        [ [ View.navigationHeader "Users" ]
                        , navigationItems.users |> List.map (viewNavItem model)
                        , [ View.navigationHeader "Developers" ]
                        , navigationItems.developers |> List.map (viewNavItem model)
                        ]
                }
            , main =
                case model.route of
                    Route.Index ->
                        viewAccount model

                    Route.AppList ->
                        viewAppList model
            }
            |> Html.toUnstyled
            |> List.singleton
    }


type alias NavItem =
    { route : Route, name : String, icon : FeatherIcons.Icon }


navigationItems : { users : List NavItem, developers : List NavItem }
navigationItems =
    { users =
        [ { route = Route.Index, name = "Account", icon = FeatherIcons.user }
        ]
    , developers =
        [ { route = Route.AppList, name = "App List", icon = FeatherIcons.code }
        ]
    }


viewNavItem : DashboardModel -> NavItem -> Html Msg
viewNavItem model { route, icon, name } =
    View.navigationItem []
        { active = route == model.route
        , icon = icon
        , label = name
        , link = route
        }


viewAccount : DashboardModel -> List (Html Msg)
viewAccount model =
    View.workInProgressBanner
        :: List.intersperse View.spacer
            [ View.dashboardHeading "Your Account"
            , View.sectionUsername
                { username = [ View.settingText [ Html.text model.username ] ]
                }
            , View.sectionEmail
                { verificationStatus = [ resendVerificationEmailButton model ]
                }
            ]


viewAppList : DashboardModel -> List (Html Msg)
viewAppList model =
    List.intersperse View.spacer
        [ View.dashboardHeading "Developed Apps" ]


resendVerificationEmailButton : DashboardModel -> Html Msg
resendVerificationEmailButton model =
    View.uppercaseButton
        { label = "Resend Verification Email"
        , onClick = DashboardMsg EmailResendVerification
        , isLoading = model.resendingVerificationEmail
        }


subscriptions : DashboardModel -> Sub Msg
subscriptions model =
    if model.resendingVerificationEmail then
        Ports.webnativeVerificationEmailSent
            (\_ -> DashboardMsg VerificationEmailSent)

    else
        Sub.none
