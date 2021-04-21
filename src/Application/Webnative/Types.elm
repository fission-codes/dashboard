module Webnative.Types exposing (..)

import Codec exposing (Codec)
import Json.Decode as Json
import Json.Encode as E


type State
    = NotAuthorised NotAuthorisedFields
    | AuthSucceeded AuthSucceededFields
    | AuthCancelled AuthCancelledFields
    | Continuation ContinuationFields


type alias NotAuthorisedFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    }


type alias AuthSucceededFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    , newUser : Bool
    , throughLobby : Bool
    , username : String
    }


type alias AuthCancelledFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    , cancellationReason : String
    , throughLobby : Bool
    }


type alias ContinuationFields =
    { permissions : Maybe Permissions
    , authenticated : Bool
    , newUser : Bool
    , throughLobby : Bool
    , username : String
    }


type alias Permissions =
    { app : Maybe AppInfo
    , fs : Maybe FileSystemPermissions
    , platform : Maybe PlatformPermissions
    }


type alias AppInfo =
    { name : String
    , creator : String
    }


type alias FileSystemPermissions =
    { privatePaths : List String
    , publicPaths : List String
    }


type alias PlatformPermissions =
    { apps : PlatformAppsPermissions
    }


type PlatformAppsPermissions
    = AllApps
    | Domains (List String)


decoderState : Json.Decoder State
decoderState =
    let
        decoderNotAuthorised =
            Json.map2 NotAuthorisedFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)

        decoderAuthSucceeded =
            Json.map5 AuthSucceededFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)
                (Json.field "newUser" Json.bool)
                (Json.field "throughLobby" Json.bool)
                (Json.field "username" Json.string)

        decoderAuthCancelled =
            Json.map4 AuthCancelledFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)
                (Json.field "cancellationReason" Json.string)
                (Json.field "throughLobby" Json.bool)

        decoderContinuation =
            Json.map5 ContinuationFields
                (Json.field "permissions" (Json.maybe decoderPermissions))
                (Json.field "authenticated" Json.bool)
                (Json.field "newUser" Json.bool)
                (Json.field "throughLobby" Json.bool)
                (Json.field "username" Json.string)
    in
    Json.field "scenario" Json.string
        |> Json.andThen
            (\scenario ->
                case scenario of
                    "NOT_AUTHORISED" ->
                        Json.map NotAuthorised decoderNotAuthorised

                    "AUTH_SUCCEEDED" ->
                        Json.map AuthSucceeded decoderAuthSucceeded

                    "AUTH_CANCELLED" ->
                        Json.map AuthCancelled decoderAuthCancelled

                    "CONTINUATION" ->
                        Json.map Continuation decoderContinuation

                    other ->
                        Json.fail ("Unrecognized 'scenario' field in Webnative.State: '" ++ other ++ "'")
            )


codecPermissions : Codec Permissions
codecPermissions =
    Codec.object Permissions
        |> Codec.maybeField "app" .app codecAppInfo
        |> Codec.maybeField "fs" .fs codecFileSystemPermissions
        |> Codec.maybeField "platform" .platform codecPlatformPermissions
        |> Codec.buildObject


decoderPermissions : Json.Decoder Permissions
decoderPermissions =
    Codec.decoder codecPermissions


encodePermissions : Permissions -> Json.Value
encodePermissions =
    Codec.encoder codecPermissions


codecAppInfo : Codec AppInfo
codecAppInfo =
    Codec.object AppInfo
        |> Codec.field "name" .name Codec.string
        |> Codec.field "creator" .creator Codec.string
        |> Codec.buildObject


codecFileSystemPermissions : Codec FileSystemPermissions
codecFileSystemPermissions =
    let
        nonEmptyList ls =
            case ls of
                [] ->
                    Nothing

                _ ->
                    Just ls

        fromNonEmptyList maybeNonEmpty =
            case maybeNonEmpty of
                Just ls ->
                    ls

                Nothing ->
                    []
    in
    Codec.object
        (\publicPaths privatePaths ->
            { publicPaths = fromNonEmptyList publicPaths
            , privatePaths = fromNonEmptyList privatePaths
            }
        )
        |> Codec.maybeField "publicPaths" (nonEmptyList << .publicPaths) (Codec.list Codec.string)
        |> Codec.maybeField "privatePaths" (nonEmptyList << .privatePaths) (Codec.list Codec.string)
        |> Codec.buildObject


codecPlatformPermissions : Codec PlatformPermissions
codecPlatformPermissions =
    Codec.object PlatformPermissions
        |> Codec.field "apps" .apps codecPlatformAppsPermissions
        |> Codec.buildObject


codecPlatformAppsPermissions : Codec PlatformAppsPermissions
codecPlatformAppsPermissions =
    Codec.build
        encodePlatformAppsPermissions
        decoderPlatformAppsPermissions


decoderPlatformAppsPermissions : Json.Decoder PlatformAppsPermissions
decoderPlatformAppsPermissions =
    Json.maybe Json.string
        |> Json.andThen
            (\result ->
                case result of
                    Just "*" ->
                        Json.succeed AllApps

                    Just _ ->
                        Json.fail "Expected the string \"*\" or a list of strings."

                    Nothing ->
                        Json.map Domains (Json.list Json.string)
            )


encodePlatformAppsPermissions : PlatformAppsPermissions -> Json.Value
encodePlatformAppsPermissions appsPermissions =
    case appsPermissions of
        AllApps ->
            E.string "*"

        Domains list ->
            E.list E.string list
