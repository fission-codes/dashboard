module Recovery.Radix exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation
import Data.App as App
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
    , username : String
    , backup : String
    , recoveryState : State
    }


type State
    = EnterUsername
      -- | EnterBackup
      -- | AskForRecoveryWithoutPrivateFiles
      -- | WaitingForLinking
      -- | WaitingForEmailVerification
    | Loading



-- 📣


type Msg
    = UrlChanged Url
    | UrlChangedFromOutside String
    | UrlRequested UrlRequest
    | NoOp
    | UsernameInput String
    | BackupInput String
    | StartRecoveryClicked
