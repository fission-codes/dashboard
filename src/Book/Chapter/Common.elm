module Chapter.Common exposing (it)

import Css
import ElmBook.Chapter exposing (chapter, render, withComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import FeatherIcons
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as A
import Tailwind.Utilities as Tw
import View.Common


content : String
content =
    """
## Buttons

There is view function for buttons in `View.Common` with this signature:

```elm
View.Common.button :
    { isLoading : Bool
    , disabled : Bool
    , icon : Maybe FeatherIcons.Icon
    , label : String
    , onClick : Maybe msg
    , style : Css.Style
    , spinnerStyle : List Css.Style
    }
    -> Html msg
```

### Styles

You can choose the particular style of button via the `style`
property:

<component with-label="View.Common.primaryButtonStyle" />

Use the primary style for the *main* and *only*, next
*non-destructive* action.

<component with-label="View.Common.primaryDangerButtonStyle" />

Use the primary danger style for the *main* and *only*, but
*destructive* action. Use it for primary actions which can't
be undone.
(But prefer to avoid this style if possible by
providing an 'undo' action.)

<component with-label="View.Common.secondaryButtonStyle" />

Use the secondary style for *alternative* options, which
aren't main.

<component with-label="View.Common.uppercaseButtonStyle" />

Use the uppercase style for *non-destrictive*, basic button
actions. You can use it when there are multiple
equally-important options, e.g. settings screens.

<component with-label="View.Common.dangerButtonStyle" />

Use the danger style for similar cases to the uppercase
style, but for *destructive* actions.


### Typography

Generally, buttons should use title case (except for the
uppercase style).


### Width

On any environments where the button's container is wider
than 600px, the button should be as small as possible while
fitting its content.

On mobile screens and environments where the button's
container is narrower than 600px, the button should fill the
container's width.


### States

Buttons can have special states:

* An *idle*, normal state (as seen above)
* A *disabled* state
* A *loading* state with a spinner

<component with-label="Disabled" />
<component with-label="Loading" />

Keep in mind that usually, the button should be disabled
while it's in the loading state (unless it makes sense to
re-trigger the action while it's loading).

> "Gotcha" in the mean time: The uppercase button has an
empty list set as "spinnerStyle".


### Icons

Buttons can be decorated with `FeatherIcons`.

Consider using them to improve recognition.

<component with-label="Iconized" />


## Warnings

Sometimes, you want to give feedback to the user that an
action failed unexpectedly or cannot be performed (e.g. due
to input validation).

For these cases, we support a `warning` view function:

```elm
import Html.Styled exposing (text, br)
import View.Common

View.Common.warning
    [ text "We're sorry, something went wrong unexpectedly."
    , br [] []
    , text "Please contact our support!"
    ]
```

<component with-label="Warning" />

"""


it : Chapter x
it =
    chapter "View.Common"
        |> withComponentList
            [ ( "View.Common.primaryButtonStyle"
              , View.Common.button primary
              )
            , ( "View.Common.primaryDangerButtonStyle"
              , View.Common.button primaryDanger
              )
            , ( "View.Common.secondaryButtonStyle"
              , View.Common.button secondary
              )
            , ( "View.Common.uppercaseButtonStyle"
              , View.Common.button uppercase
              )
            , ( "View.Common.dangerButtonStyle"
              , View.Common.button danger
              )
            , ( "Disabled"
              , sideBySide
                    [ View.Common.button
                        { primary | disabled = True }
                    , View.Common.button
                        { secondary | disabled = True }
                    , View.Common.button
                        { uppercase | disabled = True }
                    ]
              )
            , ( "Loading"
              , sideBySide
                    [ View.Common.button
                        { primary | disabled = True, isLoading = True }
                    , View.Common.button
                        { secondary | disabled = True, isLoading = True }
                    , View.Common.button
                        { uppercase | disabled = True, isLoading = True }
                    ]
              )
            , ( "Iconized"
              , sideBySide
                    [ View.Common.button { primary | icon = Just FeatherIcons.logIn }
                    , View.Common.button { primaryDanger | label = "Break Encryption", icon = Just FeatherIcons.unlock }
                    ]
              )
            , ( "Warning"
              , View.Common.warning
                    [ Html.text "We're sorry, something went wrong unexpectedly."
                    , Html.br [] []
                    , Html.text "Please contact our support!"
                    ]
              )
            ]
        |> render content



--- UTILITIES


sideBySide : List (Html msg) -> Html msg
sideBySide items =
    Html.div
        [ A.css
            [ Tw.flex
            , Tw.flex_row
            , Tw.items_center
            , Tw.w_auto
            , Css.property "gap" "1rem"
            ]
        ]
        items


primary =
    { label = "Sign in"
    , icon = Nothing
    , disabled = False
    , isLoading = False
    , onClick = Nothing
    , style = View.Common.primaryButtonStyle
    , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
    }


primaryDanger =
    { label = "Do it."
    , icon = Nothing
    , disabled = False
    , isLoading = False
    , onClick = Nothing
    , style = View.Common.primaryDangerButtonStyle
    , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
    }


secondary =
    { label = "Go back"
    , icon = Nothing
    , disabled = False
    , isLoading = False
    , onClick = Nothing
    , style = View.Common.secondaryButtonStyle
    , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
    }


uppercase =
    { label = "Update"
    , icon = Nothing
    , disabled = False
    , isLoading = False
    , onClick = Nothing
    , style = View.Common.uppercaseButtonStyle
    , spinnerStyle = []
    }


danger =
    { label = "Delete Something"
    , icon = Nothing
    , disabled = False
    , isLoading = False
    , onClick = Nothing
    , style = View.Common.dangerButtonStyle
    , spinnerStyle = [ View.Common.primaryButtonLoaderStyle ]
    }
