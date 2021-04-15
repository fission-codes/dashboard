module Radix exposing (..)

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

    -- App List
    , appList : Maybe (List App.Name)
    , appListUploadState : UploadDropzoneState

    -- App Page (Dict keys are App.Name toString's)
    , appPageModels : Dict String AppPageModel
    }


type alias AppPageModel =
    { repeatAppNameInput : String
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
    | AppRenameInProgress
    | AppRenamingFailed String



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
      -- Other
    | LogError (List Json.Value)


type AuthenticatedMsg
    = -- Mobile Navigation
      ToggleNavigationExpanded
      -- Account
    | EmailResendVerification
    | VerificationEmailSent
      -- Backup
    | PromptedBrowserToSaveReadKey
      -- App List
    | FetchedAppList Json.Value
    | DropzonePublishStart
    | DropzonePublishEnd App.Name
    | DropzonePublishFail
    | DropzonePublishAction String
    | DropzonePublishProgress { progress : Int, total : Int, info : String }
    | DropzoneSuccessDismiss
    | DropzoneSuccessGoToApp App.Name
    | AppPageMsg App.Name AppPageMsg


type AppPageMsg
    = AppPageRepeatAppNameInput String
    | AppPageDeleteAppClicked
    | AppPageDeleteAppSucceeded
    | AppPageDeleteAppFailed String
    | AppPageRenameAppInput String
    | AppPageRenameAppClicked
    | AppPageRenameAppFailed String
    | AppPageRenameAppSucceeded App.Name
