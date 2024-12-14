from enum import Enum
import sys
from yfunc import *

class RecipeViewType(Enum):
    empty = 1
    error = 2
    text = 3
    list1 = 4
    list2 = 5

class RecipeActionType(Enum):
    back = 1
    hide = 2
    copy = 3
    open = 4
    shell = 5

class RecipeActionArgType(Enum):
    plain = 1
    para = 2
    commandBarText = 3
    file = 4
    context = 5

class RecipeActionArg:
    type: RecipeActionArgType
    value: str

    def __init__(self, type: RecipeActionArgType, value: str=None) -> None:
        self.type = type
        self.value = value

class RecipeAction:
    type: RecipeActionType
    arguments: list[RecipeActionArg]

    def __init__(self, type: RecipeActionType, arguments: list[RecipeActionArg]=[]) -> None:
        self.type = type
        self.arguments = arguments

class RecipeViewItem:
    title: str
    description: str
    icon: str
    tags: list[str]
    actions: list[RecipeAction]

    def __init__(self,
        title: str,
        description: str,
        icon: str = None,
        tags: list[str] = [],
        actions: list[RecipeAction] = [],
    ) -> None:
        self.title = title
        self.description = description
        self.icon = icon
        self.tags = tags
        self.actions = actions

class RecipeView:

    default_item_icon: str
    error_message: str
    type: RecipeViewType
    items: list[RecipeViewItem]

    def __init__(self,
            type: RecipeViewType,
            items: list[RecipeViewItem],
            default_item_icon: str = None,
            error_message: str = None,
    ) -> None:
        self.type = type
        self.default_item_icon = default_item_icon
        self.items = items
        self.error_message = error_message

    def show(self):
        sys.stdout.write(ystr().json().from_object(self))
