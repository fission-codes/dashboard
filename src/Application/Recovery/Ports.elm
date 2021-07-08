port module Recovery.Ports exposing (..)

import Json.Decode as Json


port log : List Json.Value -> Cmd msg



-- verifyBackup


port verifyBackup : { username : String, key : String } -> Cmd msg


port verifyBackupFailed : ({ message : String, contactSupport : Bool } -> msg) -> Sub msg


port verifyBackupSucceeded : ({ username : String, key : String } -> msg) -> Sub msg



-- usernameExists


port usernameExists : String -> Cmd msg


port usernameExistsResponse : ({ username : String, exists : Bool, valid : Bool } -> msg) -> Sub msg



-- save backup


port saveUsername : String -> Cmd msg


port saveBackup : String -> Cmd msg



-- Account Recovery


port fetchWritePublicKey : () -> Cmd msg


port writePublicKeyFetched : (String -> msg) -> Sub msg


port writePublicKeyFailure : (String -> msg) -> Sub msg



-- Account Linking


port linkingInitiate : { username : String, rootPublicKey : String, readKey : Maybe String } -> Cmd msg


port linkingPinVerification : ({ did : String, pin : List Int } -> msg) -> Sub msg


port linkingPinVerified : Bool -> Cmd msg


port linkingDone : ({} -> msg) -> Sub msg
