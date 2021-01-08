module Radix exposing (..)

import Browser exposing (UrlRequest)
import Url exposing (Url)
import Webnative



-- ⛩


type alias Flags =
    {}



-- 🌳


type alias Model =
    { username : SettingModel
    , email : SettingModel
    , productUpdates : Bool
    , emailVerified : Bool
    }



-- 📣


type
    Msg
    -----------------------------------------
    -- URL
    -----------------------------------------
    = UrlChanged Url
    | UrlRequested UrlRequest
      -----------------------------------------
      -- App
      -----------------------------------------
    | Username SettingMsg
    | Email SettingMsg
    | ProductUpdatesCheck Bool
    | EmailResendVerification
      -----------------------------------------
      -- Webnative
      -----------------------------------------
    | GotWnfsResponse Webnative.Response



-- Settings


type SettingModel
    = SettingIs String
    | SettingEditing String


type SettingMsg
    = SettingEdit
    | SettingUpdate String
    | SettingSave
