from enum import Enum
import base64
from yfunc import *

class FishType(Enum):
    Text = 'Text'
    Image = 'Image'
    Other = 'Other'

class DataInfo:
    byte_count: int | None
    char_count: int | None
    word_count: int | None
    row_count: int | None
    width: int | None
    height: int | None

    def __init__(self, arg: dict):
        self.byte_count = arg.get('byte_count', None)
        self.char_count = arg.get('char_count', None)
        self.word_count = arg.get('word_count', None)
        self.row_count = arg.get('row_count', None)
        self.width = arg.get('width', None)
        self.height = arg.get('height', None)
    
    def __str__(self) -> str:
        return str(self.__dict__)
    
    def __repr__(self) -> str:
        return str(self.__dict__)
        
class Fish:
    uid: str
    identity: str
    count: int
    fish_type: FishType
    fish_data: bytes
    data_info: DataInfo
    desc: str
    tags: list[str]
    is_marked: bool
    is_locked: bool
    extra_info: dict
    create_time: str
    update_time: str

    def __init__(self, arg: dict):
        self.uid = arg['uid']
        self.identity = arg['identity']
        self.count = arg['count']
        self.fish_type = FishType(arg['fish_type'])
        self.fish_data = base64.b64decode(arg['fish_data'])
        self.data_info = DataInfo(arg['data_info'])
        self.desc = arg['desc']
        self.tags = arg['tags']
        self.is_marked = arg['is_marked']
        self.is_locked = arg['is_locked']
        self.extra_info = ystr(arg['extra_info']).json().to_dic()
        self.create_time = arg['create_time']
        self.update_time = arg['update_time']

    def text_data(self) -> str:
        return self.fish_data.decode('utf-8')

    def __str__(self) -> str:
        return str(self.__dict__)
    
    def __repr__(self) -> str:
        return str(self.__dict__)
