module Radix exposing (..)

import Browser exposing (UrlRequest)
import Url exposing (Url)



-- ⛩


type alias Flags =
    {}



-- 🌳


type alias Model =
    { username : UsernameModel
    }


type UsernameModel
    = UsernameIs String
    | UsernameEditing String



-- 📣


type
    Msg
    -----------------------------------------
    -- URL
    -----------------------------------------
    = UrlChanged Url
    | UrlRequested UrlRequest
      --
    | UsernameEdit
    | UsernameUpdate String
    | UsernameSave
