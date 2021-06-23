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
    = ScreenRecoverAccount StateRecoverAccount
    | ScreenRegainAccess StateRegainAccess
    | ScreenVerifiedEmail StateVerifiedEmail
    | ScreenWrongBrowser


type alias StateRecoverAccount =
    { backupUpload : RemoteData VerifyBackupError SecureBackup
    , sentEmail : WebData ()
    }


type alias StateRegainAccess =
    { username : String
    , usernameValidation : RemoteData UsernameError String
    , sentEmail : WebData ()
    }


type UsernameError
    = UsernameInvalid
    | UsernameNotFound


type alias StateVerifiedEmail =
    { username : String
    , challenge : String
    , publicWriteKey : RemoteData String String
    , updateDID : WebData ()
    }



-- | UploadSuccess SecureBackup
-- 📣


type Msg
    = -- URL
      UrlChanged Url
    | UrlRequested UrlRequest
      -- Account Recovery Screen
    | RecoverySelectedBackup (List File)
    | RecoveryVerifyBackupFailed VerifyBackupError
    | RecoveryVerifyBackupSucceeded SecureBackup
    | RecoveryUploadedBackup String
    | RecoveryClickedSendEmail
    | RecoveryEmailSent (Result Http.Error ())
      -- Regain Account Screen
    | RegainEmailSent (Result Http.Error ())
    | RegainClickedIHaveNoBackup
    | RegainClickedGoBack
    | RegainUsernameInput String
    | RegainUsernameExists { username : String, exists : Bool, valid : Bool }
    | RegainClickedSendEmail
      -- Verified Email Screen
    | VerifiedRecoverAccount
    | VerifiedPublicKeyFetched (Result String String)
    | VerifiedUserDIDUpdated (Result Http.Error ())


type alias VerifyBackupError =
    { message : String, contactSupport : Bool }
