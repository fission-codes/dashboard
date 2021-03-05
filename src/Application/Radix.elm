module Radix exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation
import Dict exposing (Dict)
import Json.Decode as Json
import Route exposing (Route)
import Url exposing (Url)
import Webnative
import Webnative.Types



-- ⛩


type alias Flags =
    {}



-- 🌳


type alias Model =
    { navKey : Browser.Navigation.Key
    , url : Url
    , state : State
    }


type State
    = Authenticated AuthenticatedModel
    | SigninScreen
    | LoadingScreen
    | ErrorScreen WebnativeError


type WebnativeError
    = InsecureContext
    | UnsupportedBrowser
    | UnknownError String


type alias AuthenticatedModel =
    { username : String
    , resendingVerificationEmail : Bool
    , navigationExpanded : Bool
    , route : Route
    }



-- 📣


type Msg
    = UrlChanged Url
    | UrlRequested UrlRequest
    | AuthenticatedMsg AuthenticatedMsg
      -----------------------------------------
      -- Webnative
      -----------------------------------------
    | InitializedWebnative (Result Json.Error Webnative.Types.State)
    | GotWebnativeResponse Webnative.Response
    | GotWebnativeError String
    | RedirectToLobby


type AuthenticatedMsg
    = -- Mobile Navigation
      ToggleNavigationExpanded
      -- Account
    | EmailResendVerification
    | VerificationEmailSent
      -- App List
    | FetchedAppList (Dict String (List String))
