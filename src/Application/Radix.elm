module Radix exposing (..)

import Browser exposing (UrlRequest)
import Json.Decode as Json
import Url exposing (Url)
import Webnative
import Webnative.Types as Webnative



-- ⛩


type alias Flags =
    {}



-- 🌳


type Model
    = Dashboard DashboardModel
    | SigninScreen
    | LoadingScreen


type alias DashboardModel =
    { username : SettingModel
    , email : SettingModel
    , productUpdates : Bool
    , emailVerified : Bool
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
    = Username SettingMsg
    | Email SettingMsg
    | ProductUpdatesCheck Bool
    | EmailResendVerification



-- Settings


type SettingModel
    = SettingIs String
    | SettingEditing String


type SettingMsg
    = SettingEdit
    | SettingUpdate String
    | SettingSave
