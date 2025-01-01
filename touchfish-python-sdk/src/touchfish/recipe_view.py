from enum import Enum
import sys
from yfunc import *
import base64

class RecipeViewType(Enum):
    Empty = 1
    Error = 2
    Text = 3
    List = 4
    Card = 5

class RecipeActionType(Enum):
    Back = 1
    Hide = 2
    Copy = 3
    Open = 4
    Show = 5
    Shell = 6

class RecipeActionArgType(Enum):
    Plain = 1
    Para = 2
    CommandBarText = 3
    Context = 4

class RecipeActionArg:
    arg_type: RecipeActionArgType
    value: str

    def __init__(self, type: RecipeActionArgType, value: str=None) -> None:
        self.arg_type = type
        self.value = value

class RecipeAction:
    action_type: RecipeActionType
    arguments: list[RecipeActionArg]

    def __init__(self, type: RecipeActionType, arguments: list[RecipeActionArg]=[]) -> None:
        self.action_type = type
        self.arguments = arguments

class RecipeViewItemProperty:
    name: str
    value: str

    def __init__(self, name: str, value):
        self.name = str(name)
        self.value = str(value)

class RecipeViewItemOperation:
    name: str
    actions: list[RecipeAction]

    def __init__(self, name: str="", actions: list[RecipeAction]=[]):
        self.name = name
        self.actions = actions

class RecipeViewItem:
    title: str
    description: str
    icon: str
    tags: list[str]
    images: list[str]
    properties: list[RecipeViewItemProperty]
    operations: list[RecipeViewItemOperation]

    def __init__(self,
        title: str,
        description: str,
        icon: str = None,
        tags: list[str] = [],
        images: list[str] = [],
        properties: list[RecipeViewItemProperty] = [],
        operations: list[RecipeAction] = [],
    ) -> None:
        self.title = title
        self.description = description
        self.icon = icon
        self.tags = tags
        self.images = images
        self.properties = properties
        self.operations = operations

class RecipeView:

    type: RecipeViewType
    data: list[str]
    items: list[RecipeViewItem]
    
    def __init__(self,
            type: RecipeViewType,
            data: list[bytes] = [],
            items: list[RecipeViewItem] = [],
    ) -> None:
        self.type = type
        self.data = [base64.b64encode(s).decode('utf-8') for s in data]
        self.items = items

    def show(self):
        sys.stdout.write(ystr().json().from_object(self)+"\n<RECIPE_OUTPUT_FRAME_END>\n")
