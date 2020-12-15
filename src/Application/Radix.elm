module Radix exposing (..)

import Browser exposing (UrlRequest)
import Url exposing (Url)



-- ⛩


type alias Flags =
    {}



-- 🌳


type alias Model =
    { username : SettingModel
    , email : SettingModel
    , productUpdates : Bool
    }



-- 📣


type
    Msg
    -----------------------------------------
    -- URL
    -----------------------------------------
    = UrlChanged Url
    | UrlRequested UrlRequest
    | Username SettingMsg
    | Email SettingMsg
    | ProductUpdatesCheck Bool



-- Settings


type SettingModel
    = SettingIs String
    | SettingEditing String


type SettingMsg
    = SettingEdit
    | SettingUpdate String
    | SettingSave
