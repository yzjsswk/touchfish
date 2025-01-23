from enum import Enum
from dataclasses import dataclass, field
from typing import Any
import requests
from yfunc import *

class DataService:

    host = None
    port = None

    @staticmethod
    def get_url_prefix() -> str:
        host = DataService.host if DataService.host != None else Para.data_service_host
        port = DataService.port if DataService.port != None else Para.data_service_port
        if host == None:
            raise Exception("no host delected, use DataService.host=... to specify a host")
        if port == None:
            raise Exception("no port delected, use DataService.port=... to specify a port")
        return f'http://{host}:{port}'

    @staticmethod
    def heart_beat() -> dict:
        url = DataService.get_url_prefix() + '/heartbeat'
        resp = requests.get(url=url)
        resp.raise_for_status()
        return ystr(resp.text).json().to_dic()

    @staticmethod
    def search_fish(
        fuzzy: str = None,
        identitys: list[str] = None, 
        fish_types: list['FishType'] = None,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        create_after: int = None,
        create_before: int = None,
        update_after: int = None,
        update_before: int = None,
        page_num: int = None,
        page_size: int = None,
    ) -> dict:
        url = DataService.get_url_prefix() + '/fish/search'
        resp = requests.post(url=url, json={
            'fuzzy': fuzzy,
            'identitys': identitys,
            'fish_types': fish_types,
            'desc': desc, 
            'tags': tags, 
            'is_marked': is_marked,
            'is_locked': is_locked,
            'create_after': create_after,
            'create_before': create_before,
            'update_after': update_after,
            'update_before': update_before,
            'page_num': page_num,
            'page_size': page_size,
        })
        resp.raise_for_status()
        return ystr(resp.text).json().to_dic()
        
    @staticmethod
    def delect_fish(
        fuzzy: str = None,
        identitys: list[str] = None, 
        fish_types: list['FishType'] = None,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        create_after: int = None,
        create_before: int = None,
        update_after: int = None,
        update_before: int = None,
    ) -> dict:
        url = DataService.get_url_prefix() + '/fish/delect'
        resp = requests.post(url=url, json={
            'fuzzy': fuzzy,
            'identitys': identitys,
            'fish_types': fish_types,
            'desc': desc, 
            'tags': tags, 
            'is_marked': is_marked,
            'is_locked': is_locked,
            'create_after': create_after,
            'create_before': create_before,
            'update_after': update_after,
            'update_before': update_before,
        })
        resp.raise_for_status()
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def pick_fish(uid: str) -> dict:
        url = DataService.get_url_prefix() + f'/fish/pick/{uid}'
        resp = requests.get(url=url)
        resp.raise_for_status()
        return ystr(resp.text).json().to_dic()
        
    @staticmethod
    def pick_fish_by_identity(identity: str) -> dict:
        url = DataService.get_url_prefix() + f'/fish/pick_by_identity/{identity}'
        resp = requests.get(url=url)
        resp.raise_for_status()
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def count_fish() -> dict:
        url = DataService.get_url_prefix() + '/fish/count'
        resp = requests.get(url=url)
        resp.raise_for_status()
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def add_fish(
        fish_type: 'FishType',
        fish_data: bytes,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        extra_info: dict = None,
    ) -> dict:
        url = DataService.get_url_prefix() + '/fish/add'
        import base64
        fish_data = base64.b64encode(fish_data).decode('utf-8')
        resp = requests.post(url=url, json={
            'fish_type': fish_type.name,
            'fish_data': fish_data,
            'desc': desc, 
            'tags': tags, 
            'is_marked': is_marked,
            'is_locked': is_locked,
            'extra_info': extra_info,
        })
        resp.raise_for_status()
        return ystr(resp.text).json().to_dic()

    @staticmethod
    def modify_fish(
        uid: str,
        desc: str = None,
        tags: list[str] = None,
        extra_info: dict = None,
    ) -> dict:
        url = DataService.get_url_prefix() + '/fish/modify'
        resp = requests.post(url=url, json={
            'uid': uid,
            'desc': desc, 
            'tags': tags, 
            'extra_info': ystr().json().from_object(extra_info) if extra_info != None else None,
        })
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def expire_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/expire'
        resp = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def mark_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/mark'
        resp = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def unmark_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/unmark'
        resp = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def lock_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/lock'
        resp = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
        })
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def unlock_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/unlock'
        resp = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
        })
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def pin_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/pin'
        resp = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        return ystr(resp.text).json().to_dic()
    
    @staticmethod
    def create_topic(
            subject: str,
            source: str,
            title: str,
            extra_info: dict = None,
        ):
        url = DataService.get_url_prefix() + '/topic/create'
        resp = requests.post(url=url, json={
            'subject': subject,
            'source': source,
            'title': title,
            'extra_info': extra_info,
        })
        return ystr(resp.text).json().to_dic()

    @staticmethod
    def send_message(
            subject: str,
            level: 'MessageLevel',
            title: str,
            body: str,
            has_read: bool = False,
            extra_info: dict = None,
        ):
        url = DataService.get_url_prefix() + '/message/send'
        resp = requests.post(url=url, json={
            'subject': subject,
            'level': level.name,
            'title': title,
            'body': body,
            'has_read': has_read,
            'extra_info': extra_info,
        })
        return ystr(resp.text).json().to_dic()

class FishType(Enum):
    Text = 'Text'
    Image = 'Image'
    Other = 'Other'

@dataclass
class DataInfo:

    byte_count: int | None = field(default=None)
    char_count: int | None = field(default=None)
    word_count: int | None = field(default=None)
    row_count: int | None = field(default=None)
    width: int | None = field(default=None)
    height: int | None = field(default=None)

    @staticmethod
    def from_arg(arg: dict) -> 'DataInfo':
        byte_count: int | None = arg.get('byte_count', None)
        char_count: int | None = arg.get('char_count', None)
        word_count: int | None = arg.get('word_count', None)
        row_count: int | None = arg.get('row_count', None)
        width: int | None = arg.get('width', None)
        height: int | None = arg.get('height', None)
        return DataInfo(
            byte_count=byte_count, char_count=char_count, word_count=word_count,
            row_count=row_count, width=width, height=height,
        )
        
@dataclass
class Fish:

    uid: str
    identity: str
    fish_type: FishType 
    fish_data: bytes = field(repr=False)
    data_info: DataInfo
    desc: str
    tags: list[str]
    is_marked: bool
    is_locked: bool
    extra_info: dict
    create_time: str
    update_time: str

    @staticmethod
    def from_arg(arg: dict) -> 'Fish':
        uid = arg['uid']
        identity = arg['identity']
        fish_type = FishType(arg['fish_type'])
        import base64
        fish_data = base64.b64decode(arg['fish_data'])
        data_info = DataInfo.from_arg(arg['data_info'])
        desc = arg['desc']
        tags = arg['tags']
        is_marked = arg['is_marked']
        is_locked = arg['is_locked']
        extra_info = arg['extra_info']
        create_time = arg['create_time']
        update_time = arg['update_time']
        return Fish(
            uid=uid, identity=identity, fish_type=fish_type, fish_data=fish_data,
            data_info=data_info, desc=desc, tags=tags, is_marked=is_marked, is_locked=is_locked,
            extra_info=extra_info, create_time=create_time, update_time=update_time,
        )

    def text_data(self) -> str:
        return self.fish_data.decode('utf-8')
    
    @staticmethod
    def search(
        fuzzy: str = None,
        identitys: list[str] = None, 
        fish_types: list[FishType] = None,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        create_after: int = None,
        create_before: int = None,
        update_after: int = None,
        update_before: int = None,
        page_num: int = 0,
        page_size: int = 100000,
    ) -> 'Handler':
        return Handler(resp=DataService.search_fish(
            fuzzy=fuzzy, identitys=identitys, fish_types=fish_types, desc=desc, tags=tags,
            is_marked=is_marked, is_locked=is_locked, create_after=create_after, create_before=create_before,
            update_after=update_after, update_before=update_before, page_num=page_num, page_size=page_size,
        ))
    
    @staticmethod
    def delect(
        fuzzy: str = None,
        identitys: list[str] = None, 
        fish_types: list['FishType'] = None,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        create_after: int = None,
        create_before: int = None,
        update_after: int = None,
        update_before: int = None,
    ) -> 'Handler':
        return Handler(resp=DataService.delect_fish(
            fuzzy=fuzzy, identitys=identitys, fish_types=fish_types, desc=desc, tags=tags,
            is_marked=is_marked, is_locked=is_locked, create_after=create_after, create_before=create_before,
            update_after=update_after, update_before=update_before,
        ))
    
    @staticmethod
    def pick(uid: str) -> 'Handler':
        return Handler(resp=DataService.pick_fish(uid=uid))
        
    @staticmethod
    def pick_by_identity(identity: str) -> 'Handler':
        return Handler(resp=DataService.pick_fish_by_identity(identity=identity))
    
    @staticmethod
    def count() -> 'Handler':
        return Handler(resp=DataService.count_fish())
    
    @staticmethod
    def add(
        fish_type: 'FishType', fish_data: bytes, desc: str = None, tags: list[str] = None,
        is_marked: bool = None, is_locked: bool = None, extra_info: dict = None,
    ) -> 'Handler':
        return Handler(resp=DataService.add_fish(
            fish_type=fish_type, fish_data=fish_data, desc=desc, tags=tags,
            is_marked=is_marked, is_locked=is_locked, extra_info=extra_info,
        ))

    @staticmethod
    def modify(uid: str, desc: str = None, tags: list[str] = None, extra_info: dict = None) -> 'Handler':
        return Handler(resp=DataService.modify_fish(
            uid=uid, desc=desc, tags=tags, extra_info=extra_info,
        ))
    
    @staticmethod
    def expire(uid: str) -> 'Handler':
        return Handler(resp=DataService.expire_fish(
            uids=[uid], skip_if_not_exists=False, skip_if_locked=False,
        ))
    
    @staticmethod
    def batch_expire(uids: list[str], skip_if_not_exists: bool = True, skip_if_locked: bool = True) -> 'Handler':
        return Handler(resp=DataService.expire_fish(
            uids=uids, skip_if_not_exists=skip_if_not_exists, skip_if_locked=skip_if_locked,
        ))
    
    @staticmethod
    def mark(uid: str) -> 'Handler':
        return Handler(resp=DataService.mark_fish(
            uids=[uid], skip_if_not_exists=False, skip_if_locked=False,
        ))
    
    @staticmethod
    def batch_mark(uids: list[str], skip_if_not_exists: bool = True, skip_if_locked: bool = True) -> 'Handler':
        return Handler(resp=DataService.mark_fish(
            uids=uids, skip_if_not_exists=skip_if_not_exists, skip_if_locked=skip_if_locked,
        ))
    
    @staticmethod
    def unmark(uid: str) -> 'Handler':
        return Handler(resp=DataService.unmark_fish(
            uids=[uid], skip_if_not_exists=False, skip_if_locked=False,
        ))
    
    @staticmethod
    def batch_unmark(uids: list[str], skip_if_not_exists: bool = True, skip_if_locked: bool = True) -> 'Handler':
        return Handler(resp=DataService.unmark_fish(
            uids=uids, skip_if_not_exists=skip_if_not_exists, skip_if_locked=skip_if_locked,
        ))
    
    @staticmethod
    def lock(uid: str) -> 'Handler':
        return Handler(resp=DataService.lock_fish(uids=[uid], skip_if_not_exists=False))
    
    @staticmethod
    def batch_lock(uids: list[str], skip_if_not_exists: bool = True) -> 'Handler':
        return Handler(resp=DataService.lock_fish(uids=uids, skip_if_not_exists=skip_if_not_exists))
    
    @staticmethod
    def unlock(uid: str) -> 'Handler':
        return Handler(resp=DataService.unlock_fish(uids=[uid], skip_if_not_exists=False))
    
    @staticmethod
    def batch_unlock(uids: list[str], skip_if_not_exists: bool = True) -> 'Handler':
        return Handler(resp=DataService.unlock_fish(uids=uids, skip_if_not_exists=skip_if_not_exists))
    
    @staticmethod
    def pin(uid: str) -> 'Handler':
        return Handler(resp=DataService.pin_fish(uids=[uid], skip_if_not_exists=False, skip_if_locked=False))
    
    @staticmethod
    def batch_pin(uids: list[str], skip_if_not_exists: bool = True, skip_if_locked: bool = True) -> 'Handler':
        return Handler(resp=DataService.pin_fish(uids=uids, skip_if_not_exists=skip_if_not_exists, skip_if_locked=skip_if_locked))

class MessageLevel(Enum):
    Info = 'Info'
    Warning = 'Warning'
    Error = 'Error'

class Topic:

    @staticmethod
    def create(subject: str, source: str, title: str, extra_info: dict = None) -> 'Handler':
        return Handler(resp=DataService.create_topic(
            subject=subject, source=source, title=title, extra_info=extra_info
        ))

    @staticmethod
    def send_message(subject: str, level: MessageLevel, title: str, body: str, extra_info: dict = None) -> 'Handler':
        return Handler(resp=DataService.send_message(
            subject=subject, level=level, title=title, body=body, has_read=False, extra_info=extra_info,
        ))

class ViewType(Enum):
    Empty = 1
    Error = 2
    Text = 3
    List = 4
    Card = 5

class ViewItemActionType(Enum):
    Back = 1
    Hide = 2
    Copy = 3
    Open = 4
    Show = 5
    Shell = 6

class Action:

    @staticmethod
    def run_shell_command(command: str, arguments: list[str]=[], refresh_view=True) -> dict:
        return {
            'type': 'run',
            'cmd': command,
            'args': arguments,
            'refresh_view': refresh_view,
        }
    
    @staticmethod
    def copy_to_clipboard(content: str) -> dict:
        return {
            'type': 'run',
            'content': content,
        }

    @staticmethod
    def back_to_menu() -> dict:
        return {
            'type': 'back',
        }
    
    @staticmethod
    def hide_touchfish() -> dict:
        return {
            'type': 'hide',
        }
    
    @staticmethod
    def open_url(url: str) -> dict:
        return {
            'type': 'open_url',
            'url': url,
        }
    
    @staticmethod
    def active_external_app(bundle_id: str) -> dict:
        return {
            'type': 'active_app',
            'bundle_id': bundle_id,
        }
    
    @staticmethod
    def set_parameter(name: str, value: str) -> dict:
        return {
            'type': 'set_para',
            'name': name,
            'value': value,
        }

class Property:

    name: str
    value: str

    def __init__(self, name: str, value):
        self.name = str(name)
        self.value = str(value)

@dataclass
class Operation:
    name: str = field(default="")
    actions: list[dict] = field(default_factory=list)

@dataclass
class ViewItem:
    title: str
    description: str
    icon: str = field(default=None)
    tags: list[str] = field(default_factory=list)
    images: list[str] = field(default_factory=list)
    properties: list[Property] = field(default_factory=list)
    operations: list[Operation] = field(default_factory=list)

class View:

    type: ViewType
    data: list[str]
    items: list[ViewItem]
    
    def __init__(self, type: ViewType, data: list[bytes] = [], items: list[ViewItem] = []) -> None:
        import base64
        self.type = type
        self.data = [base64.b64encode(s).decode('utf-8') for s in data]
        self.items = items

    def update(self):
        import sys
        sys.stdout.reconfigure(line_buffering=True)
        sys.stdout.write(ystr().json().from_object(self)+"\n<RECIPE_OUTPUT_FRAME_END>\n")

class Para:

    import os

    context = {} if (t:=os.environ.get("RECIPE_CONTEXT")) == None else ystr(t).json().to_dic()

    data_service_host = os.environ.get('TFDS_HOST')
    data_service_port = os.environ.get('TFDS_PORT')

    command_bar_text: str = context.get('command_bar_text', '')

    def get(name: str) -> Any | None:
        return Para.context.get(name)

class Handler:

    def __init__(self, resp: dict):
        self.resp = resp

    def as_fish_list(self) -> list[Fish]:
        return [Fish.from_arg(f) for f in self.resp['data']['data']]
    
    def as_fish(self) -> Fish | None:
        return None if (t:=self.resp['data']) == None else Fish(t)

    def as_uids(self) -> list[str]:
        return self.resp['data']
    
    def as_stats(self) -> dict:
        return self.resp['data']
    
    def update_view_if_not_ok(self, note) -> 'Handler':
        pass

    def send_message_if_not_ok(self, topic, level, note) -> 'Handler':
        pass

    def exit_if_not_ok(self) -> 'Handler':
        if self.resp['code'] != 'Ok':
            exit(0)
        return self
    