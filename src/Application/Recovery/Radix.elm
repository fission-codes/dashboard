module Recovery.Radix exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation
import File exposing (File)
import Http
import RemoteData exposing (RemoteData, WebData)
import Url exposing (Url)



-- ⛩


type alias Flags =
    { endpoints : Endpoints

    -- Because there's an interruption in the account recovery process
    -- (you need to open your email inbox and go to the link in the recovery email)
    -- so we need to make sure we save&load the submitted backup.
    , savedRecovery :
        { username : Maybe String
        , key : Maybe String
        }
    }


type alias Endpoints =
    { api : String
    , lobby : String
    , user : String
    }



-- 🌳


type alias Model =
    { navKey : Browser.Navigation.Key
    , endpoints : Endpoints
    , url : Url
    , recoveryState : State
    }


type alias SecureBackup =
    { username : String
    , key : String
    }


type State
    = ScreenInitial Step1State
    | ScreenRegainAccess { username : String, usernameMightExist : Bool, usernameValid : Bool }


type alias Step1State =
    { backupUpload : RemoteData VerifyBackupError SecureBackup
    , sentEmail : WebData ()
    }



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
    | RecoveryEmailSent (Result Http.Error ())
    | ClickedIHaveNoBackup
    | ClickedGoBack
    | UsernameInput String
    | UsernameExists { username : String, exists : Bool, valid : Bool }


type alias VerifyBackupError =
    { message : String, contactSupport : Bool }
