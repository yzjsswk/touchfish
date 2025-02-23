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
        host = DataService.host if DataService.host != None else Context.data_service_host
        port = DataService.port if DataService.port != None else Context.data_service_port
        if host == None:
            raise Exception("no host delected, use DataService.host=... to specify a host")
        if port == None:
            raise Exception("no port delected, use DataService.port=... to specify a port")
        return f'http://{host}:{port}'

    @staticmethod
    def heart_beat():
        url = DataService.get_url_prefix() + '/heartbeat'
        return requests.get(url=url)

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
    ):
        url = DataService.get_url_prefix() + '/fish/search'
        if fish_types != None:
            fish_types = [fish_type.value for fish_type in fish_types]
        return requests.post(url=url, json={
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
    ):
        url = DataService.get_url_prefix() + '/fish/delect'
        if fish_types != None:
            fish_types = [fish_type.value for fish_type in fish_types]
        return requests.post(url=url, json={
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
    
    @staticmethod
    def pick_fish(uid: str):
        url = DataService.get_url_prefix() + f'/fish/pick/{uid}'
        return requests.get(url=url)
        
    @staticmethod
    def pick_fish_by_identity(identity: str):
        url = DataService.get_url_prefix() + f'/fish/pick_by_identity/{identity}'
        return requests.get(url=url)
    
    @staticmethod
    def count_fish():
        url = DataService.get_url_prefix() + '/fish/count'
        return requests.get(url=url)
    
    @staticmethod
    def add_fish(
        fish_type: 'FishType',
        fish_data: bytes,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        extra_info: dict = None,
    ):
        url = DataService.get_url_prefix() + '/fish/add'
        import base64
        fish_data = base64.b64encode(fish_data).decode('utf-8')
        return requests.post(url=url, json={
            'fish_type': fish_type.value,
            'fish_data': fish_data,
            'desc': desc, 
            'tags': tags, 
            'is_marked': is_marked,
            'is_locked': is_locked,
            'extra_info': extra_info,
        })

    @staticmethod
    def modify_fish(
        uid: str, desc: str = None, tags: list[str] = None, extra_info: dict = None,
    ):
        url = DataService.get_url_prefix() + '/fish/modify'
        return requests.post(url=url, json={
            'uid': uid,
            'desc': desc, 
            'tags': tags, 
            'extra_info': ystr().json().from_object(extra_info) if extra_info != None else None,
        })
    
    @staticmethod
    def expire_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/expire'
        return requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
    
    @staticmethod
    def mark_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/mark'
        return requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
    
    @staticmethod
    def unmark_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/unmark'
        return requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
    
    @staticmethod
    def lock_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/lock'
        return requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
        })
    
    @staticmethod
    def unlock_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/unlock'
        return requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
        })
    
    @staticmethod
    def pin_fish(
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = DataService.get_url_prefix() + '/fish/pin'
        return requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
    
    @staticmethod
    def create_topic(
            subject: str,
            source: str,
            title: str,
            extra_info: dict = None,
        ):
        url = DataService.get_url_prefix() + '/topic/create'
        return requests.post(url=url, json={
            'subject': subject,
            'source': source,
            'title': title,
            'extra_info': extra_info,
        })

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
        return requests.post(url=url, json={
            'subject': subject,
            'level': level.name,
            'title': title,
            'body': body,
            'has_read': has_read,
            'extra_info': extra_info,
        })

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

class ViewItemActionType(Enum):
    Back = 1
    Hide = 2
    Copy = 3
    Open = 4
    Show = 5
    Shell = 6

class Action:

    @staticmethod
    def run_shell_command(command: str, arguments: list[str]=[], refresh_view=True):
        return {
            'type': 'run',
            'cmd': command,
            'args': arguments,
            'refresh_view': refresh_view,
        }
    
    @staticmethod
    def copy_to_clipboard(content: str):
        return {
            'type': 'copy',
            'content': content,
        }

    @staticmethod
    def back_to_menu():
        return {
            'type': 'back',
        }
    
    @staticmethod
    def hide_touchfish():
        return {
            'type': 'hide',
        }
    
    @staticmethod
    def open_url(url: str):
        return {
            'type': 'open_url',
            'url': url,
        }
    
    @staticmethod
    def active_external_app(bundle_id: str):
        return {
            'type': 'active_app',
            'bundle_id': bundle_id,
        }
    
    @staticmethod
    def set_parameter(name: str, value: str):
        return {
            'type': 'set_para',
            'name': name,
            'value': value,
        }

class ViewItemSize(Enum):
    Adaptive = "Adaptive"
    Small = "Small"
    Medium = "Medium"
    Large = "Large"

class HoverEffect(Enum):
    Background = "Background"
    Description = "Description"
    Expand = "Expand"

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

class ViewItem:

    @staticmethod
    def info(title: str, body: str = None, value: str = None, selectable: bool = False) -> dict:
        return {
            'type': 'info',
            'title': title,
            'body': body,
            'value': value,
            'selectable': selectable,
        }
    
    @staticmethod
    def warn(title: str, body: str = None, value: str = None, selectable: bool = False) -> dict:
        return {
            'type': 'warn',
            'title': title,
            'body': body,
            'value': value,
            'selectable': selectable,
        }
    
    @staticmethod
    def error(title: str, body: str = None, value: str = None, selectable: bool = False) -> dict:
        return {
            'type': 'error',
            'title': title,
            'body': body,
            'value': value,
            'selectable': selectable,
        }
    
    @staticmethod
    def strip(
        size: ViewItemSize = ViewItemSize.Adaptive, title: str = '', description: str = None, icon: str = None, tags: list[str] = [],
        hover_effects: list[HoverEffect] = [], operation: Operation = None, value: str = None, selectable: bool = True,
    ) -> dict:
        return {
            'type': 'strip',
            'size': size.name,
            'title': title,
            'description': description,
            'icon': icon,
            'tags': tags,
            'hover_effects': hover_effects,
            'operation': operation,
            'value': value,
            'selectable': selectable,
        }
    
    @staticmethod
    def text_card(
        size: ViewItemSize = ViewItemSize.Adaptive,
        title: str = '',
        description: str = None,
        icon: str = None,
        tags: list[str] = [],
        body: str = '',
        properties: list[Property] = [],
        show_properties: bool = False,
        operations: list[Operation] = [],
        value: str = None,
        selectable: bool = True,
    ) -> dict:
        return {
            'type': 'text_card',
            'size': size.name,
            'title': title,
            'description': description,
            'icon': icon,
            'tags': tags,
            'body': body,
            'properties': properties,
            'show_properties': show_properties,
            'operations': operations,
            'value': value,
            'selectable': selectable,
        }

    @staticmethod
    def image_card(
        size: ViewItemSize = ViewItemSize.Adaptive,
        title: str = '',
        description: str = None,
        icon: str = None,
        tags: list[str] = [],
        images: list[str] = [],
        properties: list[Property] = [],
        show_properties: bool = False,
        operations: list[Operation] = [],
        value: str = None,
        selectable: bool = True,
    ) -> dict:
        return {
            'type': 'image_card',
            'size': size.name,
            'title': title,
            'description': description,
            'icon': icon,
            'tags': tags,
            'images': images,
            'properties': properties,
            'show_properties': show_properties,
            'operations': operations,
            'value': value,
            'selectable': selectable,
        }

class View:

    items: list[dict]
    data: list[str]
    operations: list[Operation]
    enable_select: bool
    
    def __init__(self, items: list[dict], data: list[bytes] = [], operations: list[Operation] = [], enable_select: bool = False) -> None:
        self.items = items
        import base64
        self.data = [base64.b64encode(s).decode('utf-8') for s in data]
        self.operations = operations
        self.enable_select = enable_select

    @staticmethod
    def empty() -> 'View':
        return View(items=[])
    
    @staticmethod
    def info(title: str, body: str = '') -> 'View':
        return View(items=[ViewItem.info(title=title, body=body)])

    @staticmethod
    def warn(title: str, body: str = '') -> 'View':
        return View(items=[ViewItem.warn(title=title, body=body)])
    
    @staticmethod
    def error(title: str, body: str = '') -> 'View':
        return View(items=[ViewItem.error(title=title, body=body)])

    def update(self):
        import sys
        sys.stdout.reconfigure(line_buffering=True)
        sys.stdout.write(ystr().json().from_object(self)+"\n<RECIPE_OUTPUT_FRAME_END>\n")

class Context:

    import os

    context = {} if (t:=os.environ.get("RECIPE_CONTEXT")) == None else ystr(t).json().to_dic()

    data_service_host = os.environ.get('TFDS_HOST')
    data_service_port = os.environ.get('TFDS_PORT')

    query: str = context.get('query', '')

    def get_para(name: str, default: Any = None) -> Any | None:
        paras = Context.context.get('parameters', {})
        if type(paras) != dict:
            return default
        return paras.get(name, default)
    
    def get_setting(name: str, default: Any = None) -> Any | None:
        paras = Context.context.get('settings', {})
        if type(paras) != dict:
            return default
        return paras.get(name, default)
    
    def get_cmd_arg(index: int, default: Any = None) -> str | None:
        import sys
        if len(sys.argv) > index:
            return sys.argv[index] if sys.argv[index] != None else default
        return default

class Handler:

    def __init__(self, resp: requests.Response):
        self.resp = resp
        self.data = ystr(resp.text).json().to_dic()

    def as_fish_list(self) -> list[Fish]:
        return [Fish.from_arg(f) for f in self.data['data']['data']]
    
    def as_fish(self) -> Fish | None:
        return None if (t:=self.data['data']) == None else Fish.from_arg(t)

    def as_uid(self) -> str | None:
        return self.data['data']
    
    def as_uids(self) -> list[str]:
        return self.data['data']
    
    def as_stats(self) -> dict:
        return self.data['data']
    
    def update_view_if_not_ok(self, note: str = '') -> 'Handler':
        if self.data['code'] != 'OK':
            View.error(
                title='Request Server Error', 
                body=f'got response not ok when requesting data server in recipe, note={note}, url={self.resp.url}, code={self.data['code']}, msg={self.data['msg']}',
            ).update()
        return self

    def send_err_msg_if_not_ok(self, subject: str, note: str = '') -> 'Handler':
        if self.data['code'] != 'OK':
            Topic.send_message(
                subject=subject, level=MessageLevel.Error, title='Request Server Error',
                body=f'got response not ok when requesting data server in recipe, note={note}, url={self.resp.url}, code={self.data['code']}, msg={self.data['msg']}',
            )
        return self

    def exit_if_not_ok(self) -> 'Handler':
        if self.data['code'] != 'OK':
            exit(0)
        return self
    