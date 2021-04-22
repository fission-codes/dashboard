module Common exposing (..)


when : Bool -> List a -> List a
when predicate list =
    if predicate then
        list

    else
        []


ifThenElse : Bool -> a -> a -> a
ifThenElse b t f =
    if b then
        t

    else
        f
