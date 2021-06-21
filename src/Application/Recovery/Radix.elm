module Recovery.Radix exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation
import Data.App as App
import Dict exposing (Dict)
import File exposing (File)
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
    , recoveryState : State
    }


type alias SecureBackup =
    { username : String
    , key : String
    }


type State
    = ScreenInitial (Maybe (Result VerifyBackupError SecureBackup))
    | ScreenWaitingForEmail
    | ScreenRegainAccess { username : String, usernameMightExist : Bool, usernameValid : Bool }



-- | UploadSuccess SecureBackup
-- 📣


type Msg
    = UrlChanged Url
    | UrlChangedFromOutside String
    | UrlRequested UrlRequest
    | NoOp
    | SelectedBackup (List File)
    | VerifyBackupFailed VerifyBackupError
    | VerifyBackupSucceeded SecureBackup
    | UploadedBackup String
    | ClickedSendEmail
    | ClickedIHaveNoBackup
    | ClickedGoBack
    | UsernameInput String
    | UsernameExists { username : String, exists : Bool, valid : Bool }


type alias VerifyBackupError =
    { message : String, contactSupport : Bool }
