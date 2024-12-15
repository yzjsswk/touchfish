from .fish import FishType, Fish
from .recipe_view import RecipeView, RecipeActionType, RecipeAction, RecipeActionArg, RecipeActionArgType, RecipeViewItem, RecipeViewType
from yfunc import *
import requests

class DataService:

    def __init__(self, host='127.0.0.1', port=56173) -> None:
        self.host = host
        self.port = port
        self.url_prefix = f'http://{host}:{port}'

    def heart_beat(self) -> str:
        url = self.url_prefix + '/heartbeat'
        res = requests.get(url=url)
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['code']

    def search_fish(
        self,
        fuzzy: str = None,
        identitys: list[str] = None, 
        fish_types: list[FishType] = None,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        passed_hours: int = None,
        page_num: int = 0,
        page_size: int = 10,
    ) -> list[Fish]:
        url = self.url_prefix + '/fish/search'
        res = requests.post(url=url, json={
            'fuzzy': fuzzy,
            'identitys': identitys,
            'fish_types': fish_types,
            'desc': desc, 
            'tags': tags, 
            'is_marked': is_marked,
            'is_locked': is_locked,
            'passed_hours': passed_hours,
            'page_num': page_num,
            'page_size': page_size,
        })
        res_dic = ystr(res.text).json().to_dic()
        return [Fish(f) for f in res_dic['data']['data']]
    
    def delect_fish(
        self,
        fuzzy: str = None,
        identitys: list[str] = None, 
        fish_types: list[FishType] = None,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        passed_hours: int = None,
    ) -> list[Fish]:
        url = self.url_prefix + '/fish/delect'
        res = requests.post(url=url, json={
            'fuzzy': fuzzy,
            'identitys': identitys,
            'fish_types': fish_types,
            'desc': desc, 
            'tags': tags, 
            'is_marked': is_marked,
            'is_locked': is_locked,
            'passed_hours': passed_hours,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def pick_fish(self, uid: str) -> Fish | None:
        url = self.url_prefix + f'/fish/pick/{uid}'
        res = requests.get(url=url)
        res_dic = ystr(res.text).json().to_dic()
        return None if (t:=res_dic['data']) == None else Fish(t)
    
    def pick_fish_by_identity(self, identity: str) -> Fish | None:
        url = self.url_prefix + f'/fish/pick_by_identity/{identity}'
        res = requests.get(url=url)
        res_dic = ystr(res.text).json().to_dic()
        return None if (t:=res_dic['data']) == None else Fish(t)
    
    def count_fish(self) -> dict:
        url = self.url_prefix + '/fish/count'
        res = requests.get(url=url)
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def add_fish(
        self,
        fish_type: FishType,
        fish_data: bytes,
        desc: str = None,
        tags: list[str] = None,
        is_marked: bool = None,
        is_locked: bool = None,
        extra_info: str = None,
    ) -> str:
        url = self.url_prefix + '/fish/add'
        import base64
        fish_data = base64.b64encode(fish_data).decode('utf-8')
        res = requests.post(url=url, json={
            'fish_type': fish_type.name,
            'fish_data': fish_data,
            'desc': desc, 
            'tags': tags, 
            'is_marked': is_marked,
            'is_locked': is_locked,
            'extra_info': extra_info,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']

    def modify_fish(
        self,
        uid: str,
        desc: str = None,
        tags: list[str] = None,
        extra_info: str = None,
    ):
        url = self.url_prefix + '/fish/modify'
        res = requests.post(url=url, json={
            'uid': uid,
            'desc': desc, 
            'tags': tags, 
            'extra_info': extra_info,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def expire_fish(self, uid: str):
        url = self.url_prefix + '/fish/expire'
        res = requests.post(url=url, json={
            'uids': [uid],
            'skip_if_not_exists': False,
            'skip_if_locked': False,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def batch_expire_fish(
            self,
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = self.url_prefix + '/fish/expire'
        res = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def mark_fish(self, uid: str):
        url = self.url_prefix + '/fish/mark'
        res = requests.post(url=url, json={
            'uids': [uid],
            'skip_if_not_exists': False,
            'skip_if_locked': False,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def batch_mark_fish(
            self,
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = self.url_prefix + '/fish/mark'
        res = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def unmark_fish(self, uid: str):
        url = self.url_prefix + '/fish/unmark'
        res = requests.post(url=url, json={
            'uids': [uid],
            'skip_if_not_exists': False,
            'skip_if_locked': False,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def batch_unmark_fish(
            self,
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = self.url_prefix + '/fish/unmark'
        res = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def lock_fish(self, uid: str):
        url = self.url_prefix + '/fish/lock'
        res = requests.post(url=url, json={
            'uids': [uid],
            'skip_if_not_exists': False,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def batch_lock_fish(
            self,
            uids: list[str],
            skip_if_not_exists: bool = True,
        ):
        url = self.url_prefix + '/fish/lock'
        res = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def unlock_fish(self, uid: str):
        url = self.url_prefix + '/fish/unlock'
        res = requests.post(url=url, json={
            'uids': [uid],
            'skip_if_not_exists': False,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def batch_unlock_fish(
            self,
            uids: list[str],
            skip_if_not_exists: bool = True,
        ):
        url = self.url_prefix + '/fish/unlock'
        res = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def pin_fish(self, uid: str):
        url = self.url_prefix + '/fish/pin'
        res = requests.post(url=url, json={
            'uids': [uid],
            'skip_if_not_exists': False,
            'skip_if_locked': False,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
    
    def batch_pin_fish(
            self,
            uids: list[str],
            skip_if_not_exists: bool = True,
            skip_if_locked: bool = True,
        ):
        url = self.url_prefix + '/fish/pin'
        res = requests.post(url=url, json={
            'uids': uids,
            'skip_if_not_exists': skip_if_not_exists,
            'skip_if_locked': skip_if_locked,
        })
        res_dic = ystr(res.text).json().to_dic()
        return res_dic['data']
