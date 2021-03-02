module Dashboard exposing (..)

import Browser
import FeatherIcons
import Html.Styled as Html exposing (Html)
import Json.Decode as Json
import Ports
import Radix exposing (..)
import View.Dashboard as View
import Webnative
import Webnative.Types as Webnative


init : String -> DashboardModel
init username =
    { username = username
    , resendingVerificationEmail = False
    , navigationExpanded = False
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
                    [ View.navigationHeader "Users"
                    , View.navigationItem []
                        { active = True
                        , icon = FeatherIcons.user
                        , label = "Account"
                        }
                    , View.navigationHeader "Developers"
                    , View.navigationItem []
                        { active = False
                        , icon = FeatherIcons.code
                        , label = "App List"
                        }
                    ]
                }
            , main =
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
            }
            |> Html.toUnstyled
            |> List.singleton
    }


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
