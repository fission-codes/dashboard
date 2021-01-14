module Dashboard exposing (..)

import Browser
import Browser.Navigation
import Common
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as Events
import Json.Decode as Json
import Ports
import Radix exposing (..)
import Url exposing (Url)
import View.Dashboard as View
import Webnative
import Webnative.Types as Webnative
import Wnfs


init : String -> DashboardModel
init username =
    { username = SettingIs username
    , email = SettingIs "my-email@me.com"
    , productUpdates = False
    , emailVerified = False
    }


update : DashboardMsg -> DashboardModel -> ( DashboardModel, Cmd Msg )
update msg model =
    case msg of
        -----------------------------------------
        -- App
        -----------------------------------------
        Username settingMsg ->
            ( { model
                | username =
                    updateSetting
                        settingMsg
                        model.username
              }
            , Cmd.none
            )

        Email settingMsg ->
            ( { model
                | email =
                    updateSetting
                        settingMsg
                        model.email
              }
            , Cmd.none
            )

        ProductUpdatesCheck checked ->
            ( { model | productUpdates = checked }
            , Cmd.none
            )

        EmailResendVerification ->
            ( { model | emailVerified = True }
            , Cmd.none
            )


updateSetting : SettingMsg -> SettingModel -> SettingModel
updateSetting msg model =
    case ( model, msg ) of
        ( SettingIs value, SettingEdit ) ->
            SettingEditing value

        ( SettingEditing value, SettingSave ) ->
            SettingIs value

        ( SettingEditing _, SettingUpdate value ) ->
            SettingEditing value

        _ ->
            model



-- view


view : DashboardModel -> List (Html Msg)
view model =
    View.appShell
        { header = View.appHeader
        , main =
            List.intersperse View.spacer
                [ View.dashboardHeading "Your Account"
                , View.sectionUsername
                    { username = viewUsername model
                    }
                , View.sectionEmail
                    { email = viewEmail model
                    , productUpdates = model.productUpdates
                    , onCheckProductUpdates = ProductUpdatesCheck >> DashboardMsg
                    , verificationStatus = viewVerificationStatus model
                    }
                , View.sectionManageAccount
                ]
        , footer = View.appFooter
        }


viewUsername : DashboardModel -> List (Html Msg)
viewUsername model =
    case model.username of
        SettingIs username ->
            [ View.settingViewing
                { value = username
                , onClickUpdate = DashboardMsg (Username SettingEdit)
                }
            ]

        SettingEditing username ->
            List.concat
                [ [ View.settingEditing
                        { value = username
                        , onInput = DashboardMsg << Username << SettingUpdate
                        , placeholder = "Your account name"
                        , inErrorState = username == "matheus23"
                        , onSave = DashboardMsg (Username SettingSave)
                        }
                  ]
                , Common.when (username == "matheus23")
                    [ View.warning [ Html.text "Sorry, this username was already taken." ] ]
                ]


viewEmail : DashboardModel -> List (Html Msg)
viewEmail model =
    case model.email of
        SettingIs email ->
            [ View.settingViewing
                { value = email
                , onClickUpdate = DashboardMsg (Email SettingEdit)
                }
            ]

        SettingEditing email ->
            List.concat
                [ [ View.settingEditing
                        { value = email
                        , onInput = DashboardMsg << Email << SettingUpdate
                        , placeholder = "my-email@example.com"
                        , inErrorState = not (String.contains "@" email)
                        , onSave = DashboardMsg (Email SettingSave)
                        }
                  ]

                -- TODO improve email verification
                , Common.when (not (String.contains "@" email))
                    [ View.warning
                        [ Html.text "This doesn’t seem to be an email address."
                        , Html.br [] []
                        , Html.text "Is there a typo?"
                        ]
                    ]
                , [ Html.span View.infoTextAttributes
                        [ Html.text "You’ll have to verify your email address again, once changed." ]
                  ]
                ]


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
