module Dashboard exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Json.Decode as Json
import Radix exposing (..)
import View.Dashboard as View
import Webnative
import Webnative.Types as Webnative


init : String -> DashboardModel
init username =
    { username = username
    , email = "my-email@me.com"
    , productUpdates = False
    , emailVerified = False
    }


update : DashboardMsg -> DashboardModel -> ( DashboardModel, Cmd Msg )
update msg model =
    case msg of
        -----------------------------------------
        -- App
        -----------------------------------------
        ProductUpdatesCheck checked ->
            ( { model | productUpdates = checked }
            , Cmd.none
            )

        EmailResendVerification ->
            ( { model | emailVerified = True }
            , Cmd.none
            )



-- view


view : DashboardModel -> List (Html Msg)
view model =
    View.appShell
        { header = View.appHeader
        , main =
            List.intersperse View.spacer
                [ View.dashboardHeading "Your Account"
                , View.sectionUsername
                    { username = [ View.settingText [ Html.text model.username ] ]
                    }
                , View.sectionEmail
                    { email = [ View.settingText [ Html.text model.email ] ]
                    , productUpdates = model.productUpdates
                    , onCheckProductUpdates = ProductUpdatesCheck >> DashboardMsg
                    , verificationStatus = viewVerificationStatus model
                    }
                ]
        , footer = View.appFooter
        }


viewVerificationStatus : DashboardModel -> List (Html Msg)
viewVerificationStatus model =
    if model.emailVerified then
        [ View.verificationStatus View.Verified ]

    else
        [ View.verificationStatus View.NotVerified
        , Html.button
            (Events.onClick (DashboardMsg EmailResendVerification)
                :: View.uppercaseButtonAttributes
            )
            [ Html.text "Resend Verification Email" ]
        ]
