module Radix exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation
import Data.App as App
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
    , appList : Maybe (List App.Name)
    , uploadDropzoneState : UploadDropzoneState
    , repeatAppNameInput : String
    , deletionState : AppDeletionState
    , renamingState : AppRenamingState
    , renameAppInput : String
    }


type UploadDropzoneState
    = DropzoneWaiting
    | DropzoneAction String
    | DropzoneProgress { info : String, progress : Int, total : Int }
    | DropzoneSucceeded App.Name
    | DropzoneFailed


type AppDeletionState
    = AppDeletionWaiting
    | AppDeletionInProgress
    | AppDeletionFailed String
    | AppDeletionNotConfirmed


type AppRenamingState
    = AppRenamingWaiting
    | AppRenamingInvalidName



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
    | FetchedAppList Json.Value
    | DropzonePublishStart
    | DropzonePublishEnd App.Name
    | DropzonePublishFail
    | DropzonePublishAction String
    | DropzonePublishProgress { progress : Int, total : Int, info : String }
    | DropzoneSuccessDismiss
    | DropzoneSuccessGoToApp App.Name
    | RepeatAppNameInput String
    | DeleteAppClicked App.Name
    | DeleteAppSucceeded
    | DeleteAppFailed String
    | RenameAppInput String
    | RenameAppClicked App.Name
