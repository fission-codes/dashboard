module Dashboard exposing (..)

import Browser
import Common
import Css.Classes
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Events
import Json.Decode as Json
import Ports
import Radix exposing (..)
import View.Common
import View.Dashboard as View
import Webnative
import Webnative.Types as Webnative


init : String -> DashboardModel
init username =
    { username = username
    , resendingVerificationEmail = False
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



-- view


view : DashboardModel -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        View.appShell
            { main =
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
    }


resendVerificationEmailButton : DashboardModel -> Html Msg
resendVerificationEmailButton model =
    Html.button
        (List.concat
            [ [ Events.onClick (DashboardMsg EmailResendVerification)
              , Html.disabled model.resendingVerificationEmail
              ]
            , View.uppercaseButtonAttributes
            ]
        )
        (List.concat
            [ [ Html.text "Resend Verification Email" ]
            , Common.when model.resendingVerificationEmail
                [ View.Common.loadingAnimation View.Common.Small [ Css.Classes.ml_3 ] ]
            ]
        )


subscriptions : DashboardModel -> Sub Msg
subscriptions model =
    if model.resendingVerificationEmail then
        Ports.webnativeVerificationEmailSent
            (\_ -> DashboardMsg VerificationEmailSent)

    else
        Sub.none
