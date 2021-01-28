module Radix exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation
import Json.Decode as Json
import Url exposing (Url)
import Webnative
import Webnative.Types as Webnative



-- ⛩


type alias Flags =
    {}



-- 🌳


type alias Model =
    { navKey : Browser.Navigation.Key
    , state : State
    }


type State
    = Authenticated DashboardModel
    | SigninScreen
    | LoadingScreen


type alias DashboardModel =
    { username : String
    , resendingVerificationEmail : Bool
    }



-- 📣


type Msg
    = UrlChanged Url
    | UrlRequested UrlRequest
    | DashboardMsg DashboardMsg
      -----------------------------------------
      -- Webnative
      -----------------------------------------
    | InitializedWebnative (Result Json.Error Webnative.State)
    | GotWnfsResponse Webnative.Response
    | RedirectToLobby


type DashboardMsg
    = EmailResendVerification
    | VerificationEmailSent
