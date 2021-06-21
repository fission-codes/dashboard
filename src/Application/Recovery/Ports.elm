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
