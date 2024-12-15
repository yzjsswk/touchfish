from touchfish import *
from yfunc import *
import sys

host = sys.argv[1]
port = sys.argv[2]
search_text = sys.argv[3]

data_service = DataService(host=host, port=port)

fish_list = data_service.search_fish(fuzzy=search_text, tags=['bookmark'], page_size=999)

RecipeView(
    type=RecipeViewType.list2,
    default_item_icon='system:link',
    items=[
        RecipeViewItem(
            title = fish.desc,
            description = fish.text_data(),
            icon = None if ((t:=fish.extra_info.get('bookmark_icon_uid', None)) == None) else f'fish:{t}',
            actions = [
                RecipeAction(
                    type=RecipeActionType.Open,
                    arguments=[
                        RecipeActionArg(
                            type=RecipeActionArgType.Plain,
                            value=fish.text_data()
                        )
                    ]
                ),
                RecipeAction(type=RecipeActionType.Hide),
            ]
        ) for fish in fish_list
    ]
).show()
