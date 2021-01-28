port module Ports exposing (..)

import Json.Decode as Json
import Webnative
import Webnative.Types as Webnative



-- Webnative-Elm Ports


port webnativeRequest : Webnative.Request -> Cmd msg


port wnfsRequest : Webnative.Request -> Cmd msg


port wnfsResponse : (Webnative.Response -> msg) -> Sub msg



-- Webnative Ports


port webnativeInitialized : (Json.Value -> msg) -> Sub msg


port webnativeResendVerificationEmail : {} -> Cmd msg


port webnativeVerificationEmailSent : ({} -> msg) -> Sub msg
